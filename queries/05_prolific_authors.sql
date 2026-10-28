-- Q05. Which authors have at least 3 different titles sold and at least 40 units sold in total?
-- Reading: Ava Patel leads with 7 titles and 474 units (10548.46); 20 authors pass the 3-title and 40-unit bar.

SELECT a.name AS author,
       COUNT(DISTINCT b.book_id) AS titles_sold,
       SUM(i.quantity) AS units,
       ROUND(SUM(i.quantity * i.unit_price_cents) / 100.0, 2) AS revenue
FROM authors a
JOIN books b       ON b.author_id = a.author_id
JOIN order_items i ON i.book_id = b.book_id
JOIN orders o      ON o.order_id = i.order_id
WHERE o.status = 'completed'
GROUP BY a.author_id, a.name
HAVING COUNT(DISTINCT b.book_id) >= 3
   AND SUM(i.quantity) >= 40
ORDER BY units DESC, author;

/* Sample output (first 10 of 20 rows, seed 42 data)
author        titles_sold  units  revenue
------------  -----------  -----  --------
Ava Patel     7            474    10548.46
Liam Cohen    3            243    5518.17
Mia Fox       6            240    6003.7
Oscar Patel   5            145    4003.65
Ava Cohen     7            144    4552.26
Jack Wilson   6            102    2085.98
Sam Bell      5            89     2202.61
Ava Hughes    4            80     2213.2
Grace Taylor  4            79     1481.01
Max Lee       3            73     1469.87
*/
