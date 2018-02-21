select
	a.txn_id,
	a.currency,
	a.txn_type,
    a.txn_date,
    ROUND(a.price_currency_usd,2) sold_at_$_usd,
	ROUND(a.settle_amount_usd,2) settle_amount_usd,
    ROUND(a.book_before_usd - a.book_after_usd,2) book,
	ROUND(a.settle_amount_usd - (a.book_before_usd - a.book_after_usd),2) gain_loss_usd,
    ROUND(a.price_usd * (a.settle_amount - (a.book_before - a.book_after)),2) gain_loss_btc,
    ROUND(a.price_cad * a.price_currency_usd,2) sold_at_$_cad,
    ROUND(a.price_cad * (a.settle_amount_usd - (a.book_before_usd - a.book_after_usd)),2) gain_loss_cad
    /*
	ROUND(a.price_usd * a.settle_amount,2) total_amount,
    ROUND(a.price_usd * (a.book_before - a.book_after),2) book,
	ROUND(a.price_usd * (a.settle_amount - (a.book_before - a.book_after)),2) gain_loss*/
from bittrex_txn a
where a.txn_type = 'sell'
order by a.currency, a.txn_date; 

select
	a.txn_id,
	a.currency,
	a.txn_type,
    a.txn_date,
    ROUND(a.price_currency_usd,2) sold_at_$_usd,
	ROUND(a.settle_amount_usd,2) settle_amount_usd,
    ROUND(a.book_before_usd - a.book_after_usd,2) book,
	ROUND(a.settle_amount_usd - (a.book_before_usd - a.book_after_usd),2) gain_loss_usd,
    ROUND(a.price_usd * (a.settle_amount - (a.book_before - a.book_after)),2) gain_loss_btc,
    ROUND(a.price_cad * a.price_currency_usd,2) sold_at_$_cad,
    ROUND(a.price_cad * (a.settle_amount_usd - (a.book_before_usd - a.book_after_usd)),2) gain_loss_cad
from gatehub_txn a
where a.txn_type = 'sell'
and a.currency = 'XRP'
and a.row_status = 1
order by a.currency, a.txn_date; 

/** Calc the totals **/
WITH 
txns AS 
(
	select a.currency, 
		SUM(ROUND(a.settle_amount_usd - (a.book_before_usd - a.book_after_usd),2)) gain_loss,
        SUM(ROUND(a.price_cad * (a.settle_amount_usd - (a.book_before_usd - a.book_after_usd)),2)) gain_loss_cad,
        YEAR(a.txn_date) year_to_claim
	from gatehub_txn a
	where a.txn_type = 'sell'
	and a.currency = 'XRP'
	and a.row_status = 1
	UNION ALL
    SELECT a.currency, 
		SUM(ROUND(a.settle_amount_usd - (a.book_before_usd - a.book_after_usd),2)) gain_loss,
        SUM(ROUND(a.price_cad * (a.settle_amount_usd - (a.book_before_usd - a.book_after_usd)),2)) gain_loss_cad,
        YEAR(a.txn_date) year_to_claim
	FROM bittrex_txn a
	WHERE a.txn_type = 'sell'
    GROUP BY a.currency
)
SELECT a.year_to_claim, a.currency, SUM(a.gain_loss) gain_loss, SUM(a.gain_loss_cad) gain_loss_cad
FROM txns a 
GROUP BY a.year_to_claim, a.currency
ORDER BY a.year_to_claim, a.currency;
