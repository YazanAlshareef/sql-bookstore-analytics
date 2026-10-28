-- Q06. Who are the 10 biggest customers, and what share of all revenue do they bring?
-- Reading: The top customer, Omar Kim, brings 2.77% of revenue and the top 10 each bring between 1.16% and 2.77%, so no single customer dominates.

WITH cust_rev AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name AS customer,
           c.city,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(i.quantity * i.unit_price_cents) / 100.0 AS revenue
    FROM customers c
    JOIN orders o      ON o.customer_id = c.customer_id
    JOIN order_items i ON i.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id, customer, c.city
)
SELECT RANK() OVER (ORDER BY revenue DESC) AS rank,
       customer, city, orders,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * revenue / (SELECT SUM(revenue) FROM cust_rev), 2) AS share_of_all_revenue_pct
FROM cust_rev
ORDER BY rank, customer_id
LIMIT 10;

/* Sample output (10 rows, seed 42 data)
rank  customer     city       orders  revenue  share_of_all_revenue_pct
----  -----------  ---------  ------  -------  ------------------------
1     Omar Kim     Geelong    43      2249.9   2.77
2     Yuki Park    Melbourne  42      1955.49  2.41
3     Isla Fox     Melbourne  42      1919.2   2.36
4     Amir Chen    Melbourne  44      1670.7   2.06
5     Ruby Cohen   Hobart     37      1665.41  2.05
6     Noah Clarke  Brisbane   35      1520.23  1.87
7     Ava Wilson   Adelaide   26      1334.86  1.64
8     Mateo Khan   Melbourne  25      1208.02  1.49
9     Sam Haddad   Brisbane   21      1051.8   1.29
10    Liam Novak   Canberra   19      939.21   1.16
*/
