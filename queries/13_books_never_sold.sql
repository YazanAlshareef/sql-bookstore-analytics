-- Q13. Which books never sold, how many copies sit on the shelf, and what is that stock worth at cost?
-- Reading: The 10 unsold books hold 457 copies on the shelf; The Long Letter alone ties up 916.98 at cost.

WITH stock AS (
    SELECT book_id, SUM(quantity_change) AS on_hand
    FROM inventory_movements
    GROUP BY book_id
)
SELECT b.title, c.name AS category,
       s.on_hand,
       ROUND(s.on_hand * (SELECT AVG(m.unit_cost_cents)
                          FROM inventory_movements m
                          WHERE m.book_id = b.book_id
                            AND m.movement_type = 'purchase_receipt') / 100.0, 2) AS stock_value_at_cost
FROM books b
JOIN categories c ON c.category_id = b.category_id
JOIN stock s      ON s.book_id = b.book_id
WHERE b.book_id NOT IN (
    SELECT i.book_id
    FROM order_items i
    JOIN orders o ON o.order_id = i.order_id
    WHERE o.status <> 'cancelled'
)
ORDER BY stock_value_at_cost DESC, b.title;

/* Sample output (10 rows, seed 42 data)
title                 category         on_hand  stock_value_at_cost
--------------------  ---------------  -------  -------------------
The Long Letter       Cooking          51       916.98
The Midnight Archive  Biography        56       848.96
The Hidden Planet     Science          53       790.23
The Lost Season       Fiction          59       672.6
The Golden Archive    Science Fiction  50       453.5
The Burning Season    Fiction          54       394.74
The Paper Mirror      Fiction          44       341.0
The Open Planet       Biography        22       224.18
The Last Season       Children         34       194.48
The Hollow River      Children         34       138.04
*/
