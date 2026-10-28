-- Q02. Which 10 books earn the most revenue?
-- Reading: One title, The Last River, earns 7578.40 from 320 units, about 47% more than the runner-up (5168.14).

WITH book_rev AS (
    SELECT b.book_id, b.title, a.name AS author,
           SUM(i.quantity) AS units,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS revenue
    FROM order_items i
    JOIN orders o  ON o.order_id = i.order_id
    JOIN books b   ON b.book_id = i.book_id
    JOIN authors a ON a.author_id = b.author_id
    WHERE o.status = 'completed'
    GROUP BY b.book_id, b.title, a.name
)
SELECT RANK() OVER (ORDER BY revenue DESC) AS rank,
       title, author, units, ROUND(revenue, 2) AS revenue
FROM book_rev
ORDER BY rank
LIMIT 10;

/* Sample output (10 rows, seed 42 data)
rank  title               author       units  revenue
----  ------------------  -----------  -----  -------
1     The Last River      Ava Patel    320    7578.4
2     The Lost River      Amir Garcia  146    5168.14
3     The Hidden Orchard  Liam Cohen   196    4634.84
4     The Salt River      Mia Fox      111    3499.69
5     The Red Garden      Ava Cohen    85     3107.15
6     The Silver Archive  Oscar Patel  104    2971.46
7     The Paper Engine    Ethan Singh  88     2779.92
8     The Broken Orchard  Noah Novak   79     2426.51
9     The Lost Letter     Chloe Khan   42     1390.18
10    The Silver Kitchen  Ava Hughes   43     1265.57
*/
