-- Q18. Do discounted order lines (below list price) carry more copies per line than full-price lines?
-- Reading: Discounted lines carry 1.144 copies per line against 1.163 for full price, so the 10% discount does not lift quantity here.

SELECT CASE WHEN i.unit_price_cents < b.list_price_cents THEN 'discounted' ELSE 'full price' END AS price_type,
       COUNT(*) AS order_lines,
       SUM(i.quantity) AS units,
       ROUND(1.0 * SUM(i.quantity) / COUNT(*), 3) AS avg_units_per_line,
       ROUND(SUM(i.quantity * i.unit_price_cents) / 100.0, 2) AS revenue
FROM order_items i
JOIN orders o ON o.order_id = i.order_id
JOIN books b  ON b.book_id = i.book_id
WHERE o.status = 'completed'
GROUP BY price_type
ORDER BY price_type;

/* Sample output (2 rows, seed 42 data)
price_type  order_lines  units  avg_units_per_line  revenue
----------  -----------  -----  ------------------  --------
discounted  431          493    1.144               10696.07
full price  2505         2914   1.163               70567.86
*/
