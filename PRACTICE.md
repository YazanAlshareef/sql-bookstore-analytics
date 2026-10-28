# Practice exercises

Ten SQL exercises on the bookstore database. Try each one before you open `PRACTICE_ANSWERS.md`.

## Setup

Build the database once, then open it from Python (no `sqlite3` command-line tool is required):

```powershell
python seed.py
python -c "import sqlite3; c = sqlite3.connect('bookstore.db'); print(c.execute('SELECT COUNT(*) FROM books').fetchone())"
```

Tables: `authors`, `categories`, `suppliers`, `books`, `customers`, `orders`, `order_items`, `inventory_movements`. See the diagram in `README.md` for the columns.

Reminders about the data:

- Money columns end in `_cents`. Divide by 100.0 to show currency units.
- `orders.status` is `completed`, `cancelled` or `returned`. `orders.channel` is `online` or `in_store`.
- Dates are text in `YYYY-MM-DD` form, so `substr(ordered_on, 1, 4)` is the year.
- There is no stored stock column. Stock is the sum of `inventory_movements.quantity_change`.
- The data is synthetic. The numbers say nothing about real shops.

## The exercises

1. **Books per category.** List every category with the number of books in it. Show the category name and the count, largest first.

2. **Above-average prices.** List the books whose `list_price_cents` is higher than the average list price of all books. Show the title and the price in currency units, most expensive first.

3. **Big cities.** Which cities have more than 15 customers? Show the city and the customer count, largest first.

4. **Completed revenue by channel.** For orders placed in 2025 with status `completed`, show the revenue per channel (sum of `quantity * unit_price_cents`, in currency units).

5. **Latest order per customer.** For each customer who has at least one order, show the customer's email and the date of their most recent order. Show the 10 most recent dates.

6. **Running order count.** For each month, show how many orders were placed and the running total of orders up to and including that month. Use a window function.

7. **Cooking books never ordered.** List the books in the category `Cooking` that appear in no order line at all. Use a `LEFT JOIN` and test for `NULL`.

8. **Best seller per category.** For each category, show the book with the most units sold (count only `completed` orders). Use a CTE and `ROW_NUMBER()`.

9. **Almost out of stock.** List the books with fewer than 5 copies on hand. Show the title and the copies on hand, lowest first. Books with no movements at all do not need to appear.

10. **Discounted lines.** Find order lines where the price paid (`order_items.unit_price_cents`) is lower than the book's `list_price_cents`. Show how many such lines exist and the average discount in percent.

## Check yourself

- Run your query. If it returns no rows, check the status filter and the join keys.
- Read the result as a sentence. If the sentence sounds wrong, the query is probably wrong.
- Compare with `PRACTICE_ANSWERS.md`. Your SQL can differ and still be right; compare the results, not the text.
