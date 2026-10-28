# Walkthrough

Every file in this repo, in plain English. The data is synthetic: `seed.py` makes it up.

## schema.sql

Defines the database: 8 tables and their indexes.

- `authors`, `categories`, `suppliers`: small lookup tables. A name lives in one place only.
- `books`: one row per title. It points at an author and a category by id.
- `customers`: one row per person.
- `orders`: one row per order, with a customer, a date, a channel (`online` or `in_store`) and a status (`completed`, `returned` or `cancelled`).
- `order_items`: the lines of an order. The key is `(order_id, book_id)`. It stores the quantity and the price paid.
- `inventory_movements`: a ledger of stock changes (`purchase_receipt`, `sale`, `return`, `adjustment`). Stock on hand is the sum of this ledger. It is never stored as a number, so it cannot drift.

Choices worth knowing:

- Money is whole cents (integers), so there is no rounding error.
- Dates are text in `YYYY-MM-DD` form, which sorts correctly.
- Foreign keys use `ON DELETE RESTRICT`, so you cannot delete a row that history depends on.
- `STRICT` tables reject a text value in an integer column.
- The file starts with a comment that explains why the design is in third normal form.

## seed.py

Deletes `bookstore.db`, builds it from `schema.sql`, and fills it with made-up data: 60 authors, 8 categories, 6 suppliers, 160 books, 450 customers, 2,000 orders (3,186 lines) and 3,389 stock movements. Orders run from 2024-01-01 to 2025-12-31.

- It uses `random.Random(42)`, so every run gives the same data.
- At the end it checks itself: integrity check, foreign key check, row counts, no negative stock, no empty orders. It stops with an error if one check fails.

## run_queries.py

Runs the files in `queries/` against `bookstore.db` and prints up to 10 rows of each.

- No arguments: run all 20.
- Numbers, for example `python run_queries.py 07 14`: run only those.
- `--write-samples`: rewrite the "Sample output" comment at the bottom of each query file from the real result.
- It ends with `all queries ran`, or `FAILED: n` and a non-zero exit code.

## run.ps1

The one command to rebuild and run everything on Windows. It moves to its own folder, checks that Python exists, runs `seed.py`, then `run_queries.py`. It stops with a non-zero exit code if either step fails.

```powershell
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

## queries/

Twenty files, one business question each. Each file has:

1. the question in a comment at the top,
2. the query,
3. a one-line "Reading" of what the result says,
4. a "Sample output" comment with the real result.

Together they use joins, CTEs, window functions, `HAVING` and subqueries. Queries that count revenue or units count only orders whose status is `completed`, because the schema does not stop a cancelled order from having lines.

## README.md

The front page: what the project is, how to run it, the ER diagram, why the design is in third normal form, what the schema does and does not enforce, the PostgreSQL differences, how AI helped, what broke and how it was fixed, the limits, and the real output of all 20 queries. The query sections are generated from the `.sql` files, so they match the files.

## PRACTICE.md and PRACTICE_ANSWERS.md

Ten exercises on this database, and their answers in a separate file so you can try first. Every answer was run against the seed-42 database before it was written down.

## LICENSE

MIT. You may use and change the code if you keep the notice.

## .gitignore

Keeps generated and local files out of git: the built `bookstore.db`, Python cache folders and similar. The database is rebuilt from `seed.py`, so it does not need to be saved.

## How the pieces fit

```text
schema.sql ──┐
             ├─> seed.py ──> bookstore.db ──> run_queries.py ──> output
seed (42) ───┘                                     ^
                                      queries/*.sql
run.ps1 = seed.py, then run_queries.py
```

## What to say in an interview

- The design: eight tables in third normal form. Names live once. Stock comes from a ledger, so it cannot disagree with the movements.
- Money is in cents, to avoid float errors. Dates are ISO text, so they sort.
- The constraints do real work: foreign keys, `CHECK`, `STRICT`, partial unique indexes, and a composite foreign key from the ledger to the order line.
- What the schema does not enforce (a sale on a cancelled order, stock below zero) needs a trigger. I did not write one. The queries filter on status and the seed script asserts no negative stock.
- The data is synthetic and seeded, so results are repeatable but say nothing about real shops.
- I have not run any of this on PostgreSQL. The README lists what would change.
- An AI review of the first schema found real problems, and I fixed them. Some of the first one-line readings were wrong, and I fixed those by comparing them with the printed output.
