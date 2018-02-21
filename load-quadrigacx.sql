TRUNCATE TABLE import_quadrigacx_txn;
-- (txn_date, open_order_date, market, trade_type, bid_ask, filled, total, actual_rate, settle_amount)

LOAD DATA LOCAL INFILE './data/quadrigacx.csv' 
 INTO TABLE import_quadrigacx_txn 
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
;


/*
Presently no sells so this doesn't matter. 
-- 09/28/2017 19:01:51
INSERT INTO quadrigacx_txn(
 txn_date, txn_type, currency_to, currency_from, quantity, price, amount, fee, settle_amount)
SELECT STR_TO_DATE(a.txn_date,'%m/%d/%Y %h24:%i:%s'), a.txn_type, a.currency_to, a.currency_from, a.quantity, a.price, a.amount, a.fee, a.settle_amount
FROM import_quadrigacx_txn a
;*/
