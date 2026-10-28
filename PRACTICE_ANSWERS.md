# Practice answers

Answers for the ten exercises in `PRACTICE.md`. Each query ran against the seed-42 database before it went in this file. Your own SQL can differ; compare the results.

## 1. Books per category

```sql
SELECT c.name AS category, COUNT(*) AS books
FROM books b
JOIN categories c ON c.category_id = b.category_id
GROUP BY c.category_id
ORDER BY books DESC, category;
```

`GROUP BY` collapses the join to one row per category, and `COUNT(*)` counts the books in each group. An inner join is fine because every book has a category (the column is `NOT NULL`).

## 2. Above-average prices

```sql
SELECT title, list_price_cents / 100.0 AS price
FROM books
WHERE list_price_cents > (SELECT AVG(list_price_cents) FROM books)
ORDER BY list_price_cents DESC, title;
```

The subquery returns one number, the average, and the outer query keeps the rows above it.

## 3. Big cities

```sql
SELECT city, COUNT(*) AS customers
FROM customers
GROUP BY city
HAVING COUNT(*) > 15
ORDER BY customers DESC, city;
```

`WHERE` filters rows before grouping. `HAVING` filters groups after counting, so it is the right place for a condition on `COUNT(*)`.

## 4. Completed revenue by channel

```sql
SELECT o.channel,
       ROUND(SUM(oi.quantity * oi.unit_price_cents) / 100.0, 2) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'completed'
  AND substr(o.ordered_on, 1, 4) = '2025'
GROUP BY o.channel
ORDER BY o.channel;
```

Revenue uses `unit_price_cents` from the order line, the price actually paid, not the current list price.

## 5. Latest order per customer

```sql
SELECT c.email, MAX(o.ordered_on) AS last_order
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY last_order DESC, c.email
LIMIT 10;
```

The inner join drops customers with no orders, which is what the exercise asks for.

## 6. Running order count

```sql
WITH monthly AS (
    SELECT substr(ordered_on, 1, 7) AS month, COUNT(*) AS orders
    FROM orders
    GROUP BY month
)
SELECT month,
       orders,
       SUM(orders) OVER (ORDER BY month) AS running_orders
FROM monthly
ORDER BY month;
```

The CTE counts orders per month first. The window `SUM(...) OVER (ORDER BY month)` then adds up every row from the first month to the current one.

## 7. Cooking books never ordered

```sql
SELECT b.title
FROM books b
JOIN categories c ON c.category_id = b.category_id
LEFT JOIN order_items oi ON oi.book_id = b.book_id
WHERE c.name = 'Cooking'
  AND oi.book_id IS NULL
ORDER BY b.title;
```

A `LEFT JOIN` keeps every Cooking book. Books with no matching order line get `NULL` in the `order_items` columns, and `oi.book_id IS NULL` keeps only those. This counts any order line, whatever the order status.

## 8. Best seller per category

```sql
WITH units AS (
    SELECT b.category_id, b.book_id, b.title, SUM(oi.quantity) AS units_sold
    FROM books b
    JOIN order_items oi ON oi.book_id = b.book_id
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY b.book_id
),
ranked AS (
    SELECT category_id, title, units_sold,
           ROW_NUMBER() OVER (
               PARTITION BY category_id
               ORDER BY units_sold DESC, title
           ) AS rn
    FROM units
)
SELECT c.name AS category, r.title, r.units_sold
FROM ranked r
JOIN categories c ON c.category_id = r.category_id
WHERE r.rn = 1
ORDER BY category;
```

`PARTITION BY category_id` restarts the numbering for each category. Sorting by `units_sold DESC` puts the best seller at 1. The `title` tie-break makes the result the same on every run.

## 9. Almost out of stock

```sql
SELECT b.title, SUM(m.quantity_change) AS on_hand
FROM books b
JOIN inventory_movements m ON m.book_id = b.book_id
GROUP BY b.book_id
HAVING SUM(m.quantity_change) < 5
ORDER BY on_hand, b.title;
```

Stock is derived: receipts and returns add, sales subtract, adjustments can do either. A book with no movements has no group, so it does not appear.

## 10. Discounted lines

```sql
SELECT COUNT(*) AS discounted_lines,
       ROUND(AVG(100.0 * (b.list_price_cents - oi.unit_price_cents) / b.list_price_cents), 1) AS avg_discount_pct
FROM order_items oi
JOIN books b ON b.book_id = oi.book_id
WHERE oi.unit_price_cents < b.list_price_cents;
```

The price paid is stored on the order line, so it can differ from the list price in `books`. If the result is one row with `0` and `NULL`, no line was discounted.
