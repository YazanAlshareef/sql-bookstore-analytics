-- Q03. What are the 3 best-selling books (by revenue) inside each category?
-- Reading: Cooking's top book (3107.15) earns almost four times the second (825.34); Children is the closest race (529.14 against 500.49).

WITH book_rev AS (
    SELECT c.name AS category, b.title,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS revenue
    FROM order_items i
    JOIN orders o     ON o.order_id = i.order_id
    JOIN books b      ON b.book_id = i.book_id
    JOIN categories c ON c.category_id = b.category_id
    WHERE o.status = 'completed'
    GROUP BY c.name, b.book_id, b.title
),
ranked AS (
    SELECT category, title, revenue,
           RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
    FROM book_rev
)
SELECT category, rank_in_category, title, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;

/* Sample output (first 10 of 24 rows, seed 42 data)
category   rank_in_category  title               revenue
---------  ----------------  ------------------  -------
Biography  1                 The Salt River      3499.69
Biography  2                 The Broken Orchard  2426.51
Biography  3                 The Silver Kitchen  1265.57
Children   1                 The Burning Border  529.14
Children   2                 The Salt Garden     500.49
Children   3                 The Lost Atlas      401.09
Cooking    1                 The Red Garden      3107.15
Cooking    2                 The Winter Signal   825.34
Cooking    3                 The Burning Planet  792.69
Fiction    1                 The Hidden Orchard  4634.84
*/
