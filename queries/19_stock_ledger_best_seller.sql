-- Q19. For the best-selling book, what does the first part of its stock ledger look like, with running stock after each movement?
-- Reading: The best seller is The Last River: 320 copies sold on completed orders, 295 ledger movements in all, and 9 copies on hand at the end.

SELECT m.moved_on, m.movement_type, m.quantity_change,
       SUM(m.quantity_change) OVER (ORDER BY m.moved_on, m.movement_id) AS stock_after
FROM inventory_movements m
WHERE m.book_id = (
    SELECT i.book_id
    FROM order_items i
    JOIN orders o ON o.order_id = i.order_id
    WHERE o.status = 'completed'
    GROUP BY i.book_id
    ORDER BY SUM(i.quantity) DESC, i.book_id
    LIMIT 1
)
ORDER BY m.moved_on, m.movement_id
LIMIT 20;

/* Sample output (first 10 of 20 rows, seed 42 data)
moved_on    movement_type     quantity_change  stock_after
----------  ----------------  ---------------  -----------
2023-12-01  purchase_receipt  32               32
2024-01-06  sale              -1               31
2024-01-10  sale              -1               30
2024-01-13  sale              -1               29
2024-01-17  return            1                30
2024-01-21  sale              -2               28
2024-01-25  sale              -2               26
2024-02-02  sale              -1               25
2024-02-07  sale              -1               24
2024-02-08  sale              -1               23
*/
