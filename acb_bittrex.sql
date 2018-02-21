DELIMITER //
DROP PROCEDURE IF EXISTS calc_acb_bittrex//

CREATE PROCEDURE calc_acb_bittrex()
BEGIN

 DECLARE v_finished BOOLEAN;
 DECLARE v_txn_id NUMERIC(10);
 DECLARE v_txn_type VARCHAR(10);
 DECLARE v_quantity NUMERIC(30,16);
 DECLARE v_price NUMERIC(30,16);
 DECLARE v_gross_amount NUMERIC(30,16);
 DECLARE v_txn_date DATETIME;
 DECLARE v_currency VARCHAR(10);
 
 DECLARE v_prev_currency VARCHAR(10) DEFAULT 0;
 DECLARE v_prev_quantity NUMERIC(30,16) DEFAULT 1;
 DECLARE v_prev_book NUMERIC(30,16) DEFAULT 0;
 DECLARE v_prev_book_usd NUMERIC(30,16) DEFAULT 0;
 DECLARE v_current_book NUMERIC(30,16) DEFAULT 0;
 DECLARE v_current_book_usd NUMERIC(30,16) DEFAULT 0;
 DECLARE v_price_usd NUMERIC(30,16) DEFAULT 0;
 DECLARE v_price_currency_usd NUMERIC(30,16) DEFAULT 0;
 DECLARE v_price_cad NUMERIC(30,16) DEFAULT 0;
 
 DECLARE c1 CURSOR FOR
 SELECT 
	a.txn_id,
	a.txn_hash, 
	a.txn_date, 
	a.txn_type, 
	a.currency, 
	a.currency_base, 
	a.quantity, 
	a.price, 
	a.settle_amount gross_amount
 FROM bittrex_txn a
 ORDER BY a.currency, a.txn_date;
 
 -- declare NOT FOUND handler
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = true;
 
 OPEN c1;
 cursor_loop: LOOP
  FETCH c1 INTO v_txn_id, v_txn_type, v_quantity, v_price, v_gross_amount, v_txn_date, v_currency;
	
    IF v_finished THEN 
		LEAVE cursor_loop; 
	END IF;

	BEGIN 
		DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN SELECT 'Price not found for: ' + v_txn_id; END;

		SELECT ROUND(1 / ((1/v_price) / z.price),6), z.price
		INTO v_price_currency_usd, v_price_usd
		FROM price z 
		WHERE z.currency = 'BTC'
		AND z.effective_date = (SELECT MAX(y.effective_date) FROM price y WHERE y.effective_date < v_txn_date AND y.currency = 'BTC' AND y.currency_base = 'USD');
	END;
	
	BEGIN
		DECLARE CONTINUE HANDLER FOR NOT FOUND BEGIN END;
	
		SELECT a.price
		INTO v_price_cad
		FROM price a 
		WHERE a.currency = 'USD'
		AND a.effective_date = (SELECT MAX(b.effective_date) FROM price b WHERE b.effective_date < v_txn_date AND b.currency = 'USD' AND b.currency_base = 'CAD');        
	END;
    
	IF v_currency = v_prev_currency THEN
        
		SELECT SUM(IF(a.txn_type='sell', -a.quantity, a.quantity)) prev_quantity
		INTO v_prev_quantity
		FROM bittrex_txn a
		WHERE a.txn_date < v_txn_date
		AND a.currency = v_currency;
		IF v_txn_type = 'sell' THEN
			SELECT ROUND(v_prev_book * (v_prev_quantity - v_quantity) / v_prev_quantity,16),
				   ROUND(v_prev_book_usd * (v_prev_quantity - v_quantity) / v_prev_quantity,16)
			INTO v_current_book,
				 v_current_book_usd;
		ELSE 
			SET v_current_book = v_prev_book + v_gross_amount;
            SET v_current_book_usd = v_prev_book_usd + (v_quantity * v_price_currency_usd);
		END IF;
        
		UPDATE bittrex_txn a
		SET a.book_before = v_prev_book,
			a.book_after = v_current_book,
            a.book_before_usd = v_prev_book_usd,
			a.book_after_usd = v_current_book_usd,
			a.price_usd = v_price_usd,
			a.price_cad = v_price_cad,
			a.price_currency_usd = v_price_currency_usd,
            a.quantity_before = v_prev_quantity,
            a.settle_amount_usd = v_quantity * v_price_currency_usd
		WHERE a.txn_id = v_txn_id;            

		SET v_prev_book = v_current_book;
        SET v_prev_book_usd = v_current_book_usd;
        SET v_prev_currency = v_currency;
	ELSE
		SET v_prev_book = 0;
        SET v_prev_book_usd = 0;
		SET v_prev_currency = v_currency;
		SET v_prev_quantity = 0;
		SET v_current_book = v_gross_amount;
        SET v_current_book_usd = v_quantity * v_price_currency_usd;
       
		UPDATE bittrex_txn a
		SET a.book_before = v_prev_book,
			a.book_after = v_current_book,
            a.book_before_usd = v_prev_book_usd,
			a.book_after_usd = v_current_book_usd,
			a.price_usd = v_price_usd,
			a.price_cad = v_price_cad,
			a.price_currency_usd = v_price_currency_usd,
            a.quantity_before = 0,
            a.settle_amount_usd = v_current_book_usd
		WHERE a.txn_id = v_txn_id;
        
        SET v_prev_book = v_current_book;
        SET v_prev_book_usd = v_current_book_usd;
        SET v_price_currency_usd = 0;
	END IF;
END LOOP cursor_loop;
CLOSE c1;

END //
DELIMITER ;