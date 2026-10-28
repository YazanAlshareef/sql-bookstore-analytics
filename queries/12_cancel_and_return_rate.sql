-- Q12. What share of orders is cancelled or returned, by year and channel?
-- Reading: Cancel and return rates stay between 2.8% and 5.1%; the highest is the 5.1% cancel rate for in-store orders in 2024.

SELECT substr(ordered_on, 1, 4) AS year,
       channel,
       COUNT(*) AS orders,
       SUM(status = 'cancelled') AS cancelled,
       SUM(status = 'returned')  AS returned,
       ROUND(100.0 * SUM(status = 'cancelled') / COUNT(*), 1) AS cancel_rate_pct,
       ROUND(100.0 * SUM(status = 'returned')  / COUNT(*), 1) AS return_rate_pct
FROM orders
GROUP BY year, channel
ORDER BY year, channel;

/* Sample output (4 rows, seed 42 data)
year  channel   orders  cancelled  returned  cancel_rate_pct  return_rate_pct
----  --------  ------  ---------  --------  ---------------  ---------------
2024  in_store  257     13         10        5.1              3.9
2024  online    317     12         9         3.8              2.8
2025  in_store  668     25         24        3.7              3.6
2025  online    758     29         29        3.8              3.8
*/
