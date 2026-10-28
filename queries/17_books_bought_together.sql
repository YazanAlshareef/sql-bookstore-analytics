-- Q17. Which pairs of books are most often in the same completed order?
-- Reading: The Last River and The Hidden Orchard share 16 orders, well ahead of any other pair (9 or fewer).

SELECT b1.title AS book_a,
       b2.title AS book_b,
       COUNT(*) AS orders_together
FROM order_items i1
JOIN order_items i2 ON i2.order_id = i1.order_id
                   AND i2.book_id > i1.book_id
JOIN orders o ON o.order_id = i1.order_id
JOIN books b1 ON b1.book_id = i1.book_id
JOIN books b2 ON b2.book_id = i2.book_id
WHERE o.status = 'completed'
GROUP BY i1.book_id, i2.book_id, b1.title, b2.title
HAVING COUNT(*) >= 2
ORDER BY orders_together DESC, book_a, book_b
LIMIT 10;

/* Sample output (10 rows, seed 42 data)
book_a              book_b              orders_together
------------------  ------------------  ---------------
The Last River      The Hidden Orchard  16
The Hidden Orchard  The Hollow Signal   9
The Hidden Orchard  The Quiet Atlas     9
The Lost River      The Broken Orchard  9
The Salt River      The Last River      9
The Winter Lantern  The Lost River      9
The Last River      The Long Engine     8
The Last River      The Midnight Atlas  8
The Last River      The Paper Engine    8
The Last River      The Red Engine      8
*/
