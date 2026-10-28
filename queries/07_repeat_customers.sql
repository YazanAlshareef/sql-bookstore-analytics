-- Q07. How many customers bought once, twice, or three or more times?
-- Reading: 56.6% of buyers ordered three or more times; only 17.7% ordered once.

WITH per_customer AS (
    SELECT customer_id, COUNT(*) AS orders
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN '1 order'
            WHEN orders = 2 THEN '2 orders'
            ELSE '3+ orders' END AS bucket,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_buyers
FROM per_customer
GROUP BY bucket
ORDER BY MIN(orders);

/* Sample output (3 rows, seed 42 data)
bucket     customers  pct_of_buyers
---------  ---------  -------------
1 order    70         17.7
2 orders   102        25.8
3+ orders  224        56.6
*/
