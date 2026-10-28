-- Q11. Each month, how many buying customers are new (first completed order that month) and how many are returning?
-- Reading: New buyers per month stay between 9 and 26 over the 24 months, while returning buyers grow from 0 in 2024-01 to 113 in 2025-12.

WITH order_months AS (
    SELECT customer_id, substr(ordered_on, 1, 7) AS month
    FROM orders
    WHERE status = 'completed'
),
first_month AS (
    SELECT customer_id, MIN(month) AS first_month
    FROM order_months
    GROUP BY customer_id
)
SELECT om.month,
       COUNT(DISTINCT CASE WHEN om.month = f.first_month THEN om.customer_id END) AS new_customers,
       COUNT(DISTINCT CASE WHEN om.month > f.first_month THEN om.customer_id END) AS returning_customers
FROM order_months om
JOIN first_month f ON f.customer_id = om.customer_id
GROUP BY om.month
ORDER BY om.month;

/* Sample output (first 10 of 24 rows, seed 42 data)
month    new_customers  returning_customers
-------  -------------  -------------------
2024-01  15             0
2024-02  17             3
2024-03  17             5
2024-04  13             13
2024-05  18             12
2024-06  16             20
2024-07  26             23
2024-08  12             19
2024-09  13             25
2024-10  14             25
*/
