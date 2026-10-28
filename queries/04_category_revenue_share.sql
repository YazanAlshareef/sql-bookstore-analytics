-- Q04. What share of total revenue does each category bring, and how fast does the cumulative share build up?
-- Reading: Science, Biography and Science Fiction together bring 54.2% of revenue; Children is the smallest at 4.2%.

WITH cat_rev AS (
    SELECT c.name AS category,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS revenue
    FROM order_items i
    JOIN orders o     ON o.order_id = i.order_id
    JOIN books b      ON b.book_id = i.book_id
    JOIN categories c ON c.category_id = b.category_id
    WHERE o.status = 'completed'
    GROUP BY c.name
)
SELECT category,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 1) AS share_pct,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC, category)
             / SUM(revenue) OVER (), 1) AS cumulative_share_pct
FROM cat_rev
ORDER BY revenue DESC, category;

/* Sample output (8 rows, seed 42 data)
category         revenue   share_pct  cumulative_share_pct
---------------  --------  ---------  --------------------
Science          16056.87  19.8       19.8
Biography        14474.63  17.8       37.6
Science Fiction  13477.53  16.6       54.2
Cooking          11615.3   14.3       68.4
Fiction          9448.46   11.6       80.1
History          6855.53   8.4        88.5
Mystery          5943.04   7.3        95.8
Children         3392.57   4.2        100.0
*/
