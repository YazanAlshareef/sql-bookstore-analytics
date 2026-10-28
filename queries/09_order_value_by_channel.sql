-- Q09. What is the average, smallest and largest order value for in-store and online orders?
-- Reading: Online has more orders (996 vs 853) but the average order is about the same (43.36 online, 44.64 in store).

WITH order_totals AS (
    SELECT o.order_id, o.channel,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS total
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_id, o.channel
)
SELECT channel,
       COUNT(*) AS orders,
       ROUND(AVG(total), 2) AS avg_order_value,
       ROUND(MIN(total), 2) AS smallest,
       ROUND(MAX(total), 2) AS largest,
       ROUND(SUM(total), 2) AS revenue
FROM order_totals
GROUP BY channel
ORDER BY revenue DESC;

/* Sample output (2 rows, seed 42 data)
channel   orders  avg_order_value  smallest  largest  revenue
--------  ------  ---------------  --------  -------  --------
online    996     43.36            7.19      194.12   43189.2
in_store  853     44.64            7.19      188.53   38074.73
*/
