-- Q15. How much did the shop spend with each supplier, and how do suppliers rank?
-- Reading: Granite Peak Imports takes the largest spend (22620.97), while Redfern Press Supply has the lowest cost per copy (11.88).

SELECT RANK() OVER (ORDER BY SUM(m.quantity_change * m.unit_cost_cents) DESC) AS rank,
       s.name AS supplier,
       s.country,
       COUNT(*) AS deliveries,
       SUM(m.quantity_change) AS copies,
       ROUND(SUM(m.quantity_change * m.unit_cost_cents) / 100.0, 2) AS spend,
       ROUND(1.0 * SUM(m.quantity_change * m.unit_cost_cents) / SUM(m.quantity_change) / 100, 2) AS avg_cost_per_copy
FROM inventory_movements m
JOIN suppliers s ON s.supplier_id = m.supplier_id
WHERE m.movement_type = 'purchase_receipt'
GROUP BY s.supplier_id, s.name, s.country
ORDER BY rank;

/* Sample output (6 rows, seed 42 data)
rank  supplier                  country  deliveries  copies  spend     avg_cost_per_copy
----  ------------------------  -------  ----------  ------  --------  -----------------
1     Granite Peak Imports      US       43          1729    22620.97  13.08
2     Pinegate Book Wholesale   AU       38          1611    19840.45  12.32
3     Bluebell Trade Co         GB       36          1400    18221.51  13.02
4     Harbor Lane Distribution  AU       30          1186    14535.33  12.26
5     Tidewater Books Ltd       NZ       24          963     11623.99  12.07
6     Redfern Press Supply      AU       21          919     10913.52  11.88
*/
