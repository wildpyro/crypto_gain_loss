TRUNCATE TABLE price;
TRUNCATE TABLE import_coincompare_btc_price;
TRUNCATE TABLE import_coincompare_xrp_price;
TRUNCATE TABLE import_coincompare_eth_price;
TRUNCATE TABLE import_cad_to_usd_2017;

/* Load the hourly prices */
LOAD DATA LOCAL INFILE './data/coin-compare-btc-usd-hour.csv' 
 INTO TABLE import_coincompare_btc_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

LOAD DATA LOCAL INFILE './data/coin-compare-btc-usd-day.csv' 
 INTO TABLE import_coincompare_btc_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

INSERT INTO price(
 effective_date, price, currency, currency_base)
SELECT FROM_UNIXTIME(a.effective_date),
 ROUND((a.high + a.low + a.open + a.close) / 4, 8) amount,
'BTC',
'USD'
FROM import_coincompare_btc_price a;

/* Load the hourly prices this only goes back 2000 hours */
LOAD DATA LOCAL INFILE './data/coin-compare-xrp-btc-hour.csv' 
 INTO TABLE import_coincompare_xrp_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

/* Load the daily prices back to 2012 */
LOAD DATA LOCAL INFILE './data/coin-compare-xrp-btc-day.csv' 
 INTO TABLE import_coincompare_xrp_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

INSERT INTO price(
 effective_date, price, currency, currency_base)
SELECT FROM_UNIXTIME(a.effective_date),
 ROUND((a.high + a.low + a.open + a.close) / 4, 8) amount,
'XRP',
'BTC'
FROM import_coincompare_xrp_price a;

/* Load the hourly prices this only goes back 2000 hours */
LOAD DATA LOCAL INFILE './data/coin-compare-eth-btc-hour.csv' 
 INTO TABLE import_coincompare_eth_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

/* Load the daily prices back to 2012 */
LOAD DATA LOCAL INFILE './data/coin-compare-eth-btc-day.csv' 
 INTO TABLE import_coincompare_eth_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

INSERT INTO price(
 effective_date, price, currency, currency_base)
SELECT FROM_UNIXTIME(a.effective_date),
 ROUND((a.high + a.low + a.open + a.close) / 4, 8) amount,
'ETH',
'BTC'
FROM import_coincompare_eth_price a;

/* Load usd to cad 2017*/
LOAD DATA LOCAL INFILE './data/cad_to_usd_2017.csv' 
 INTO TABLE import_cad_to_usd_2017
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (effective_date, price)
;

INSERT INTO price(
 effective_date, price, currency, currency_base)
SELECT effective_date,
 price,
'USD',
'CAD'
FROM import_cad_to_usd_2017 a;

/*average the high, low, open and close together */
/* "2017-12-17T03:00:00",*/
/*
TRUNCATE TABLE import_bittrex_xrp_price;
LOAD DATA LOCAL INFILE './data/bittrex-xrp-to-btc.csv' 
 INTO TABLE import_bittrex_xrp_price
 FIELDS TERMINATED BY ','
 IGNORE 1 LINES
 (open, high, low, close, volume, effective_date)
;

INSERT INTO price(
 effective_date, price, currency, currency_base)
SELECT STR_TO_DATE(a.effective_date, '%Y-%m-%dT%k:%i:%s'),
 ROUND((a.high + a.low + a.open + a.close) / 4, 8) amount,
'XRP',
'BTC'
FROM import_bittrex_xrp_price a;
*/

/*average the high, low, open and close together */
/*
TRUNCATE TABLE import_cmc_price;
INSERT INTO price(
 effective_date, price_to_usd, currency, currency_symbol, currency_to)
SELECT STR_TO_DATE(a.effective_date, '%M %d, %Y'), 
ROUND((REPLACE(a.high, ',', '') + REPLACE(a.low, ',', '') + REPLACE(a.open, ',', '') + REPLACE(a.close, ',', '')) / 4,2),
'Bitcoin', 
'BTC',
'USD'
FROM import_cmc_btc_price a
;
*/