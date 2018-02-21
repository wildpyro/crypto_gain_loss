TRUNCATE TABLE import_gatehub_txn;
TRUNCATE TABLE gatehub_txn;

LOAD DATA LOCAL INFILE './data/gatehub.csv' 
 INTO TABLE import_gatehub_txn 
 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
 IGNORE 1 LINES
;

/** 
 Figure out what timezone they are using. UTC?
 Gatehub uses an exchange transaction that are two sided 
*/
INSERT INTO gatehub_txn(
 txn_date, txn_type, currency, quantity, txn_hash, currency_base
 )
WITH 
txns AS 
(
 SELECT STR_TO_DATE(a.txn_date,'%b %d, %Y, %k:%i') txn_date,
  TRIM(a.txn_hash) txn_hash,
  TRIM(a.txn_type) txn_type,
  TRIM(a.balance) balance,
  TRIM(a.quantity) quantity,
  TRIM(a.currency_issuer) currency_issuer,
  TRIM(a.currency_issuer_name) currency_issuer_name
 FROM import_gatehub_txn a 
)
SELECT 
 a.txn_date, 
 CASE 
  WHEN a.txn_type IN ('exchange', 'payment') AND a.quantity > 0 THEN 'buy'
  WHEN a.txn_type IN ('exchange', 'payment') AND a.quantity <= 0 THEN 'sell'
  WHEN a.txn_type = 'ripple_network_fee' THEN 'fee'
  ELSE 'missing txn_type'
 END txn_type,
 a.currency_issuer exchange,
 ABS(a.quantity) quantity,
 a.txn_hash,
 'BTC'
FROM txns a
;


INSERT INTO gatehub_txn(txn_id, price, txn_date)
WITH 
txns AS (
 select a.txn_id,
  a.txn_hash,
  a.quantity,
  a.txn_date,
  a.txn_type,
  a.currency,
  (SELECT MAX(b.effective_date) FROM price b WHERE b.effective_date < a.txn_date AND b.currency = 'XRP' AND b.currency_base = 'BTC') price_date
 from gatehub_txn a
 where a.currency = 'XRP'
)
SELECT a.txn_id, b.price, txn_date
FROM txns a 
LEFT JOIN price b ON a.price_date = b.effective_date AND a.currency = b.currency
ON DUPLICATE KEY UPDATE price = b.price;

/**
 Compress the fees onto the buy/sell rows 
*/
INSERT INTO gatehub_txn(txn_id, fee, txn_date)
WITH fees AS 
(
    SELECT a.txn_hash, SUM(a.quantity) fee
    FROM gatehub_txn a
    WHERE a.txn_type = 'fee' 
    GROUP BY a.txn_hash
)
SELECT a.txn_id, 
 CASE WHEN a.txn_type = 'buy' THEN ABS(b.fee)
      ELSE b.fee
 END fee, 
 a.txn_date 
FROM gatehub_txn a
JOIN fees b on a.txn_hash = b.txn_hash
WHERE a.txn_type != 'fee'
ON DUPLICATE KEY UPDATE fee = b.fee
;

/**
 Figure out the acb for each trade, backfill the price fields
 Update the last row grouped by datetime and make it the active row. 
*/
INSERT INTO gatehub_txn(txn_id, txn_date)
WITH 
txns AS
(
	SELECT MAX(a.txn_id) txn_id,
		a.txn_date, 
		SUM(a.quantity) quantity, 
		a.txn_type, 
		a.price, 
		SUM(IFNULL(a.fee,0)) fee, 
		a.currency,
		SUM(ROUND((IFNULL(a.fee,0) + a.quantity) * a.price,20)) gross_amount
	FROM gatehub_txn a
	WHERE a.txn_type IN ('buy','sell')
	AND a.currency = 'XRP'
	GROUP BY a.txn_date, a.txn_type, a.price, a.currency
)
SELECT a.txn_id, a.txn_date
FROM txns a
ON DUPLICATE KEY UPDATE
	settle_amount = ROUND(a.gross_amount,16),
    quantity = a.quantity,
    fee = a.fee
;

/**
* Now update the active row 
* Need to turn off safe mode in mysql workbench
*/
UPDATE gatehub_txn z
JOIN (SELECT a.txn_id FROM gatehub_txn a WHERE a.settle_amount != 0) y ON z.txn_id = y.txn_id
SET z.row_status = 1
;
