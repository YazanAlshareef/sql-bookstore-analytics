-- Q20. For each signup quarter, how many customers joined, how many went on to buy, and how much did the average member spend?
-- Reading: Between 82.5% and 94.6% of each signup quarter went on to buy; average spend per member ranges from 119.41 to 315.03.

WITH spend AS (
    SELECT o.customer_id,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS revenue
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
)
SELECT substr(c.joined_on, 1, 4) || '-Q' || ((CAST(substr(c.joined_on, 6, 2) AS INTEGER) + 2) / 3) AS signup_quarter,
       COUNT(*) AS customers,
       COUNT(s.customer_id) AS buyers,
       ROUND(100.0 * COUNT(s.customer_id) / COUNT(*), 1) AS buyer_pct,
       ROUND(SUM(COALESCE(s.revenue, 0)) / COUNT(*), 2) AS avg_revenue_per_member
FROM customers c
LEFT JOIN spend s ON s.customer_id = c.customer_id
GROUP BY signup_quarter
ORDER BY signup_quarter;

/* Sample output (10 rows, seed 42 data)
signup_quarter  customers  buyers  buyer_pct  avg_revenue_per_member
--------------  ---------  ------  ---------  ----------------------
2023-Q3         98         86      87.8       164.0
2023-Q4         59         49      83.1       164.1
2024-Q1         39         35      89.7       230.78
2024-Q2         47         43      91.5       176.84
2024-Q3         37         35      94.6       159.25
2024-Q4         45         38      84.4       229.53
2025-Q1         40         33      82.5       125.15
2025-Q2         42         38      90.5       197.98
2025-Q3         25         22      88.0       119.41
2025-Q4         18         17      94.4       315.03
*/
