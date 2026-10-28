-- Q01. How much did the shop earn each month, what is the running total, and how did each month change from the one before?
-- Reading: Monthly revenue grows from 967.30 in 2024-01 to 10095.46 in 2025-12, with the biggest jump in 2025-11 (+83.3%); the running total ends at 81263.93.

WITH monthly AS (
    SELECT substr(o.ordered_on, 1, 7) AS month,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS revenue
    FROM orders o
    JOIN order_items i ON i.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY substr(o.ordered_on, 1, 7)
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS running_total,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS pct_change_vs_prev
FROM monthly
ORDER BY month;

/* Sample output (first 10 of 24 rows, seed 42 data)
month    revenue  running_total  pct_change_vs_prev
-------  -------  -------------  ------------------
2024-01  967.3    967.3
2024-02  867.08   1834.38        -10.4
2024-03  1154.29  2988.67        33.1
2024-04  1246.06  4234.73        8.0
2024-05  1492.56  5727.29        19.8
2024-06  2353.57  8080.86        57.7
2024-07  2206.74  10287.6        -6.2
2024-08  1444.54  11732.14       -34.5
2024-09  1800.18  13532.32       24.6
2024-10  2082.11  15614.43       15.7
*/
