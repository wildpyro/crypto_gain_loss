/*CREATE DATABASE IF NOT EXISTS test;*/

USE test;

DROP TABLE IF EXISTS import_coincompare_btc_price;
DROP TABLE IF EXISTS import_coincompare_xrp_price;
DROP TABLE IF EXISTS import_coincompare_eth_price;
DROP TABLE IF EXISTS import_cad_to_usd_2017;
DROP TABLE IF EXISTS price;

DROP TABLE IF EXISTS import_bittrex_txn;
DROP TABLE IF EXISTS bittrex_txn;

DROP TABLE IF EXISTS import_gatehub_txn;
DROP TABLE IF EXISTS gatehub_txn;

DROP TABLE IF EXISTS import_quadrigacx_txn;
DROP TABLE IF EXISTS quadrigacx_txn;

DROP TABLE IF EXISTS position;

CREATE TABLE IF NOT EXISTS import_coincompare_btc_price (
  open VARCHAR(30),
  high VARCHAR(30),
  low VARCHAR(30),
  close VARCHAR(30),
  volume VARCHAR(30),
  effective_date VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS import_coincompare_eth_price (
  open VARCHAR(30),
  high VARCHAR(30),
  low VARCHAR(30),
  close VARCHAR(30),
  volume VARCHAR(30),
  effective_date VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS import_coincompare_xrp_price (
  open VARCHAR(30),
  high VARCHAR(30),
  low VARCHAR(30),
  close VARCHAR(30),
  volume VARCHAR(30),
  effective_date VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS import_cad_to_usd_2017 (
	effective_date VARCHAR(30),
    price VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS price (
  price_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT, 
  effective_date DATETIME NOT NULL,
  price NUMERIC(30,20) NOT NULL,
  currency VARCHAR(3) NOT NULL, 
  currency_base VARCHAR(3) NOT NULL,
  dtcreated TIMESTAMP
);

CREATE INDEX price_date ON price(effective_date);

CREATE TABLE IF NOT EXISTS import_bittrex_txn (
  order_uuid VARCHAR(36),
  currency VARCHAR(10),
  txn_type VARCHAR(20),
  quantity VARCHAR(50),
  bid_ask VARCHAR(50),
  commission_paid VARCHAR(50),
  price VARCHAR(50),
  open_order_date VARCHAR(100),
  close_order_date VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS bittrex_txn (
  txn_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  txn_hash VARCHAR(36),
  txn_date DATETIME NOT NULL,
  currency VARCHAR(4),
  currency_base VARCHAR(4),
  txn_type VARCHAR(10),
  quantity NUMERIC(30,16),
  quantity_before NUMERIC(30,16),
  price NUMERIC(30,16),
  price_currency_usd NUMERIC(30,16),
  price_usd NUMERIC(30,16),  
  price_cad NUMERIC(30,16),
  fee NUMERIC(20,8),
  settle_amount NUMERIC(30,16),
  settle_amount_usd NUMERIC(30,16),
  book_before NUMERIC(30,16),
  book_after NUMERIC(30,16),
  book_before_usd NUMERIC(30,16),
  book_after_usd NUMERIC(30,16)
);

CREATE TABLE IF NOT EXISTS import_gatehub_txn (
  txn_date VARCHAR(100),
  txn_hash VARCHAR(64),
  txn_type VARCHAR(100),
  quantity VARCHAR(50),
  currency_issuer VARCHAR(30), 
  currency_issuer_address VARCHAR(50),
  currency_issuer_name VARCHAR(30),
  balance VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS gatehub_txn (
  txn_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  txn_hash VARCHAR(64),
  txn_date DATETIME NOT NULL,
  txn_type VARCHAR(10),
  currency VARCHAR(10),
  currency_base VARCHAR(4),
  quantity NUMERIC(30,20),
  quantity_before NUMERIC(30,20),
  price NUMERIC(30,16),
  price_usd NUMERIC(30,16),  
  price_cad NUMERIC(30,16),
  price_currency_usd NUMERIC(30,16),
  amount NUMERIC(30,16),
  fee NUMERIC(20,8),
  settle_amount NUMERIC(30,16),
  settle_amount_usd NUMERIC(30,16),
  book_before NUMERIC(30,16),
  book_after NUMERIC(30,16),
  book_before_usd NUMERIC(30,16),
  book_after_usd NUMERIC(30,16),  
  row_status NUMERIC(1) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS import_quadrigacx_txn (
  txn_type VARCHAR(100),
  currency_to VARCHAR(30),
  currency_from VARCHAR(30),
  quantity NUMERIC(20,8),
  price NUMERIC(20,8),
  amount NUMERIC(20,8),
  fee NUMERIC(20,8),
  settle_amount NUMERIC(20,8),
  txn_time VARCHAR(100),
  txn_date VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS quadrigacx_txn (
  txn_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  txn_hash VARCHAR(36),
  txn_date DATETIME NOT NULL,
  currency VARCHAR(4),
  currency_base VARCHAR(4),
  txn_type VARCHAR(10),
  quantity NUMERIC(30,16),
  quantity_before NUMERIC(30,16),
  price NUMERIC(30,16),
  price_currency_usd NUMERIC(30,16),
  price_usd NUMERIC(30,16),  
  price_cad NUMERIC(30,16),
  fee NUMERIC(20,8),
  settle_amount NUMERIC(30,16),
  settle_amount_usd NUMERIC(30,16),
  book_before NUMERIC(30,16),
  book_after NUMERIC(30,16),
  book_before_usd NUMERIC(30,16),
  book_after_usd NUMERIC(30,16)
);

CREATE TABLE IF NOT EXISTS position (
  position_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  currency VARCHAR(100),
  currency_symbol VARCHAR(100),
  book_value NUMERIC(20,8),
  market_value NUMERIC(20,8),
  acb NUMERIC(20,8)
);

/*
CREATE TABLE IF NOT EXISTS import_bittrex_xrp_price (
  open VARCHAR(30),
  high VARCHAR(30),
  low VARCHAR(30),
  close VARCHAR(30),
  volume VARCHAR(30),
  effective_date VARCHAR(20)
);

DROP TABLE import_cmc_btc_price;
CREATE TABLE IF NOT EXISTS import_cmc_btc_price (
  effective_date VARCHAR(12),
  open VARCHAR(30),
  high VARCHAR(30),
  low VARCHAR(30),
  close VARCHAR(30),
  volume VARCHAR(30),
  market_cap VARCHAR(30)
);
*/