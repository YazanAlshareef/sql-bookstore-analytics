-- Q10. Which frequent customers (4+ completed orders) come back the fastest, measured by average days between orders?
-- Reading: Ruby Cohen orders about every 1.2 days on average over 37 orders, the fastest repeat buyer.

WITH gaps AS (
    SELECT customer_id, ordered_on,
           julianday(ordered_on)
             - julianday(LAG(ordered_on) OVER (PARTITION BY customer_id
                                                ORDER BY ordered_on, order_id)) AS gap_days
    FROM orders
    WHERE status = 'completed'
)
SELECT c.first_name || ' ' || c.last_name AS customer,
       COUNT(*) AS orders,
       ROUND(AVG(g.gap_days), 1) AS avg_days_between_orders,
       MIN(g.gap_days) AS shortest_gap,
       MAX(g.gap_days) AS longest_gap
FROM gaps g
JOIN customers c ON c.customer_id = g.customer_id
GROUP BY g.customer_id, customer
HAVING COUNT(*) >= 4
ORDER BY avg_days_between_orders, customer
LIMIT 10;

/* Sample output (10 rows, seed 42 data)
customer      orders  avg_days_between_orders  shortest_gap  longest_gap
------------  ------  -----------------------  ------------  -----------
Ruby Cohen    37      1.2                      0.0           4.0
Liam Novak    19      2.1                      0.0           5.0
Nora Walker   5       4.0                      2.0           8.0
Leila Hughes  9       4.8                      0.0           10.0
Lucas Singh   7       4.8                      1.0           11.0
Isla Fox      42      5.6                      0.0           26.0
Ruby Novak    11      6.0                      2.0           17.0
Ava Chen      4       6.7                      1.0           11.0
Max Martin    4       7.0                      1.0           17.0
Grace Singh   10      8.3                      1.0           23.0
*/
