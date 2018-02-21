TRUNCATE TABLE import_bittrex_txn;
TRUNCATE TABLE bittrex_txn;

/* The original file doesn't have quotes and is encoded in UTF16! Make sure to convert it*/
LOAD DATA LOCAL INFILE './data/bittrex.csv' 
 INTO TABLE import_bittrex_txn 
 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
 IGNORE 1 LINES
 (order_uuid, currency, txn_type, quantity, bid_ask, commission_paid, price, open_order_date, close_order_date)
;

/* Pull all deposits and withdrawals separately */
LOAD DATA LOCAL INFILE './data/bittrex-dep-wdr.csv' 
 INTO TABLE import_bittrex_txn
 FIELDS TERMINATED BY '\t'
 (txn_type, close_order_date, currency, quantity)
;

INSERT INTO bittrex_txn(
 txn_hash, txn_date, txn_type, currency, currency_base, quantity, price, fee, settle_amount)
SELECT 
 TRIM(a.order_uuid) txn_hash,
 CASE WHEN a.txn_type IN ('LIMIT_BUY', 'LIMIT_SELL') THEN STR_TO_DATE(a.close_order_date,'%m/%d/%Y %h:%i:%s %p')
   ELSE STR_TO_DATE(a.close_order_date,'%m/%d/%Y')
  END txn_date,
 CASE WHEN a.txn_type = 'LIMIT_BUY' THEN 'buy'
   WHEN a.txn_type = 'LIMIT_SELL' THEN 'sell'
   ELSE a.txn_type
  END txn_type,
 IF(LENGTH(a.currency)=3,a.currency,SUBSTRING_INDEX(a.currency, '-', -1)) currency, 
 SUBSTRING_INDEX(a.currency, '-', 1) currency_base,
 SUM(TRIM(a.quantity)) quantity, 
 MAX(TRIM(a.bid_ask)) price,
 SUM(IFNULL(TRIM(a.commission_paid),0)) fee,
 SUM(TRIM(a.price)) settle_amount
FROM import_bittrex_txn a
GROUP BY a.order_uuid, a.txn_type, a.close_order_date, a.currency
;

/* Add prices for deposits and withdrawals */
INSERT INTO bittrex_txn(txn_id,txn_date)
WITH 
txns AS (
 SELECT a.txn_id,
  a.quantity, 
  a.txn_date, 
  a.txn_type,
  a.currency,
  (SELECT MAX(b.effective_date) FROM price b WHERE b.effective_date < a.txn_date AND a.currency = b.currency AND b.currency_base = 'BTC') price_date 
 FROM bittrex_txn a
 WHERE a.txn_type in ('deposit','withdrawal')
)
SELECT a.txn_id, a.txn_date
FROM txns a 
LEFT JOIN price b ON a.price_date = b.effective_date AND a.currency = b.currency
ON DUPLICATE KEY UPDATE price = IF(a.currency='BTC',1,b.price), settle_amount = ROUND(a.quantity * IF(a.currency='BTC',1,b.price),16)
;

/**
* How to handle deposits and withdrawals with the same date? For now just make the sum be <=
**/
INSERT INTO bittrex_txn(txn_id, txn_date)
WITH 
txns AS
(
 SELECT 
  a.txn_id,
  a.txn_hash, 
  a.txn_date, 
  a.txn_type, 
  a.currency, 
  a.currency_base, 
  IF(a.txn_type = 'sell', -a.quantity, a.quantity) quantity, 
  a.price price, 
  a.settle_amount + IF(a.txn_type = 'sell', -a.fee, IFNULL(a.fee,0)) gross_amount
 FROM bittrex_txn a
),
acb AS
(
SELECT a.txn_id, 
 a.txn_type, 
 a.quantity,
 a.price,
 a.gross_amount,
 a.txn_date,
 (SELECT SUM(IF(b.txn_type='sell',-b.gross_amount,b.gross_amount)) FROM txns b WHERE a.txn_date > b.txn_date AND a.currency = b.currency) previous_book,
 (SELECT SUM(b.quantity) FROM txns b WHERE a.txn_date > b.txn_date AND a.currency = b.currency) previous_quantity
FROM txns a
),
new_acb AS 
(
 SELECT 
  CASE WHEN a.txn_type = 'sell' THEN ROUND(IFNULL(a.previous_book,0) * ((IFNULL(a.previous_quantity,0) - ABS(a.quantity)) / IFNULL(a.previous_quantity,0)),16) 
   ELSE IFNULL(a.previous_book,0) + a.gross_amount
  END current_book,
  a.txn_id, a.txn_type, a.quantity, a.gross_amount, IFNULL(a.previous_book,0) previous_book, IFNULL(a.previous_quantity,0) previous_quantity, a.txn_date
 FROM acb a
),
usd_price AS
(
 SELECT
  a.txn_id,
  (SELECT MAX(b.effective_date) FROM price b WHERE b.effective_date < a.txn_date AND b.currency = 'BTC' AND b.currency_base = 'USD') price_date
 FROM new_acb a
),
cad_price AS 
(
 SELECT
  a.txn_id,
  (SELECT MAX(b.effective_date) FROM price b WHERE b.effective_date < a.txn_date AND b.currency = 'USD' AND b.currency_base = 'CAD') price_date
 FROM new_acb a
)
SELECT a.txn_id, a.txn_date
FROM new_acb a
JOIN usd_price b ON a.txn_id = b.txn_id
JOIN price c ON b.price_date = c.effective_date AND c.currency = 'BTC'
LEFT JOIN cad_price d ON a.txn_id = d.txn_id
LEFT JOIN price e ON d.price_date = e.effective_date AND e.currency = 'USD'
ON DUPLICATE KEY UPDATE 
 price_usd = c.price, 
 price_cad = e.price, 
 settle_amount = a.gross_amount, 
 book_before = a.previous_book, 
 book_after = a.current_book, 
 quantity_before = a.previous_quantity
;
