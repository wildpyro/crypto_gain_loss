# Crypto Gains Calculator

## Limitations 
* Naming for the pricing files matters
* I only support the exchanges I use. Presently bittrex and gatehub 

## Prep 
* Clone repo
* install mariadb/mysql
* create a database called test

## Running 
* Pull down your prices from cryptocompare using their endpoints. Presently you can daily or every hour stats up to a maximum of 2000 rows

```
Sample call: https://min-api.cryptocompare.com/data/histohour?fsym=XRP&tsym=BTC&limit=2000&aggregate=3&e=BITTREX
Where: 
    fsym = from symbol
    tsym = to symbol
    limit = 2000 (the maximum)
    e = which exchange you want. 
```

* Once the files using my companion add crypto_price_parser (or anything that parses JSON to csv) 

* Place the file in the 'data' directory 

* Run `bash run-all.sh`

* Using sqlworkbench or the command line run 'gain_loss.sql' for totals and amounts by years.