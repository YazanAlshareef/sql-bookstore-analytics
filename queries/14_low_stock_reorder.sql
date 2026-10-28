-- Q14. Which books will run out first, based on the last 90 days of sales?
-- Reading: The Last River and The Salt River have about 8 days of stock left at the 90-day sales pace, so reorder these first.

WITH today AS (
    SELECT MAX(ordered_on) AS d FROM orders
),
stock AS (
    SELECT book_id, SUM(quantity_change) AS on_hand
    FROM inventory_movements
    GROUP BY book_id
),
recent AS (
    SELECT i.book_id, SUM(i.quantity) AS units_90d
    FROM order_items i
    JOIN orders o ON o.order_id = i.order_id
    WHERE o.status = 'completed'
      AND o.ordered_on > (SELECT date(d, '-90 days') FROM today)
    GROUP BY i.book_id
)
SELECT b.title,
       s.on_hand,
       r.units_90d,
       ROUND(s.on_hand / (r.units_90d / 90.0), 0) AS days_of_stock_left
FROM recent r
JOIN stock s ON s.book_id = r.book_id
JOIN books b ON b.book_id = r.book_id
ORDER BY days_of_stock_left, b.title
LIMIT 15;

/* Sample output (first 10 of 15 rows, seed 42 data)
title                on_hand  units_90d  days_of_stock_left
-------------------  -------  ---------  ------------------
The Last River       9        99         8.0
The Salt River       3        33         8.0
The Broken Orchard   4        27         13.0
The Salt Garden      4        15         24.0
The Lost Letter      3        11         25.0
The Lost River       10       36         25.0
The Paper Engine     8        27         27.0
The Burning Kitchen  4        13         28.0
The Open Border      5        14         32.0
The Paper Kitchen    6        15         36.0
*/
