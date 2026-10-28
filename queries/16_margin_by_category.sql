-- Q16. What gross margin does each category earn, using the average purchase cost of each book?
-- Reading: Margins range from 48.8% (Children) to 42.3% (Fiction).

WITH avg_cost AS (
    SELECT book_id,
           1.0 * SUM(quantity_change * unit_cost_cents) / SUM(quantity_change) AS cost_cents
    FROM inventory_movements
    WHERE movement_type = 'purchase_receipt'
    GROUP BY book_id
)
SELECT c.name AS category,
       SUM(i.quantity) AS units,
       ROUND(SUM(i.quantity * i.unit_price_cents) / 100.0, 2) AS revenue,
       ROUND(SUM(i.quantity * ac.cost_cents) / 100.0, 2) AS cost,
       ROUND(100.0 * (SUM(i.quantity * i.unit_price_cents) - SUM(i.quantity * ac.cost_cents))
             / SUM(i.quantity * i.unit_price_cents), 1) AS margin_pct
FROM order_items i
JOIN orders o     ON o.order_id = i.order_id
JOIN books b      ON b.book_id = i.book_id
JOIN categories c ON c.category_id = b.category_id
JOIN avg_cost ac  ON ac.book_id = i.book_id
WHERE o.status = 'completed'
GROUP BY c.category_id, c.name
ORDER BY margin_pct DESC;

/* Sample output (8 rows, seed 42 data)
category         units  revenue   cost     margin_pct
---------------  -----  --------  -------  ----------
Children         313    3392.57   1738.44  48.8
History          247    6855.53   3555.47  48.1
Science          483    16056.87  8508.88  47.0
Biography        517    14474.63  7713.89  46.7
Mystery          346    5943.04   3239.19  45.5
Cooking          370    11615.3   6338.89  45.4
Science Fiction  657    13477.53  7698.57  42.9
Fiction          474    9448.46   5452.28  42.3
*/
