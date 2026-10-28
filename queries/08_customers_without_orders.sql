-- Q08. Which cities have customers who signed up but never completed an order?
-- Reading: 54 customers across 8 cities never completed an order; Geelong has the most (10).

SELECT c.city,
       COUNT(*) AS customers_without_completed_order
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'completed'
)
GROUP BY c.city
ORDER BY customers_without_completed_order DESC, c.city;

/* Sample output (8 rows, seed 42 data)
city       customers_without_completed_order
---------  ---------------------------------
Geelong    10
Hobart     9
Adelaide   7
Perth      7
Sydney     7
Brisbane   6
Canberra   4
Melbourne  4
*/
