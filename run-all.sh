mysql -u root -psecret --database=test --show-warnings < create-db.sql
mysql -u root -psecret --database=test --show-warnings < load-prices.sql

mysql -u root -psecret --database=test --show-warnings < load-gatehub.sql
mysql -u root -psecret --database=test --show-warnings < load-bittrex.sql
mysql -u root -psecret --database=test --show-warnings < load-quadrigacx.sql

mysql -u root -psecret --database=test --execute="call calc_acb_bittrex()"
mysql -u root -psecret --database=test --execute="call calc_acb_gatehub()"
mysql -u root -psecret --database=test --execute="call calc_acb_quadrigacx()"
