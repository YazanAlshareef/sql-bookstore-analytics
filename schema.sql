-- schema.sql: independent bookstore, SQLite first, PostgreSQL where practical.
-- Third normal form: every non-key column depends on the key, the whole key, and nothing but the key.
-- Names live once (authors, categories, suppliers). Stock on hand is not stored: it is the sum of inventory_movements.quantity_change.
-- order_items.unit_price_cents is the price paid that day, a historical fact, so it is not a copy of books.list_price_cents.
-- Money is stored as integer cents. Dates are ISO text 'YYYY-MM-DD'.
-- Run with PRAGMA foreign_keys = ON (SQLite turns it off per connection by default).
-- Tables are STRICT (SQLite 3.37+) so a text value cannot slip into an INTEGER column.
-- PostgreSQL differences are listed in README.md.

CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE CHECK (length(trim(name)) > 0)
) STRICT;

CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE CHECK (length(trim(name)) > 0)
) STRICT;

CREATE TABLE suppliers (
    supplier_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE CHECK (length(trim(name)) > 0),
    email       TEXT NOT NULL UNIQUE COLLATE NOCASE CHECK (email LIKE '%_@_%'),
    country     TEXT NOT NULL CHECK (length(country) = 2 AND country = upper(country))  -- ISO 3166 alpha-2
) STRICT;

CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    isbn             TEXT    NOT NULL UNIQUE CHECK (length(isbn) = 13 AND isbn NOT GLOB '*[^0-9]*'),
    title            TEXT    NOT NULL CHECK (length(trim(title)) > 0),
    author_id        INTEGER NOT NULL REFERENCES authors(author_id)       ON DELETE RESTRICT,
    category_id      INTEGER NOT NULL REFERENCES categories(category_id)  ON DELETE RESTRICT,
    list_price_cents INTEGER NOT NULL CHECK (list_price_cents > 0),
    published_year   INTEGER NOT NULL CHECK (published_year BETWEEN 1800 AND 2100)
) STRICT;
CREATE INDEX idx_books_author   ON books(author_id);
CREATE INDEX idx_books_category ON books(category_id);

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    first_name  TEXT NOT NULL CHECK (length(trim(first_name)) > 0),
    last_name   TEXT NOT NULL CHECK (length(trim(last_name)) > 0),
    email       TEXT NOT NULL UNIQUE COLLATE NOCASE CHECK (email LIKE '%_@_%'),
    city        TEXT NOT NULL CHECK (length(trim(city)) > 0),
    -- "IS" not "=": date('garbage') is NULL and a CHECK only rejects FALSE, not NULL
    joined_on   TEXT NOT NULL CHECK (date(joined_on) IS joined_on)
) STRICT;

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    ordered_on  TEXT    NOT NULL CHECK (date(ordered_on) IS ordered_on),
    channel     TEXT    NOT NULL CHECK (channel IN ('in_store', 'online')),
    status      TEXT    NOT NULL CHECK (status IN ('completed', 'cancelled', 'returned'))
) STRICT;
CREATE INDEX idx_orders_customer_date ON orders(customer_id, ordered_on);
CREATE INDEX idx_orders_date          ON orders(ordered_on);

-- unit_price_cents is the price paid on that day (can differ from list price: promos).
-- It is a historical fact, not a copy of books.list_price_cents.
-- RESTRICT, not CASCADE: an order is cancelled with orders.status, never deleted.
CREATE TABLE order_items (
    order_id         INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE RESTRICT,
    book_id          INTEGER NOT NULL REFERENCES books(book_id)   ON DELETE RESTRICT,
    quantity         INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents > 0),
    PRIMARY KEY (order_id, book_id)
) STRICT;
CREATE INDEX idx_order_items_book ON order_items(book_id);

-- Stock on hand is never stored. It is the sum of quantity_change per book.
--   purchase_receipt: stock in from a supplier, needs supplier_id and unit_cost_cents, change > 0
--   sale:             stock out for an order line, needs order_id, change < 0
--   return:           stock back in from a returned order line, needs order_id, change > 0
--   adjustment:       count correction, no links, change <> 0
-- A sale or return must point at a real order line: the (order_id, book_id) pair
-- is a foreign key to order_items. A NULL order_id skips that check.
-- Not enforced (needs a trigger): sale only on non-cancelled orders, return only on
-- 'returned' orders, stock never below zero. Queries filter on orders.status instead.
CREATE TABLE inventory_movements (
    movement_id     INTEGER PRIMARY KEY,
    book_id         INTEGER NOT NULL REFERENCES books(book_id)         ON DELETE RESTRICT,
    moved_on        TEXT    NOT NULL CHECK (date(moved_on) IS moved_on),
    movement_type   TEXT    NOT NULL CHECK (movement_type IN ('purchase_receipt', 'sale', 'return', 'adjustment')),
    quantity_change INTEGER NOT NULL CHECK (quantity_change <> 0),
    supplier_id     INTEGER          REFERENCES suppliers(supplier_id) ON DELETE RESTRICT,
    unit_cost_cents INTEGER          CHECK (unit_cost_cents > 0),
    order_id        INTEGER          REFERENCES orders(order_id)       ON DELETE RESTRICT,
    FOREIGN KEY (order_id, book_id) REFERENCES order_items(order_id, book_id) ON DELETE RESTRICT,
    CHECK (
        (movement_type = 'purchase_receipt' AND quantity_change > 0 AND supplier_id IS NOT NULL
            AND unit_cost_cents IS NOT NULL AND order_id IS NULL)
     OR (movement_type = 'sale'    AND quantity_change < 0 AND order_id IS NOT NULL
            AND supplier_id IS NULL AND unit_cost_cents IS NULL)
     OR (movement_type = 'return'  AND quantity_change > 0 AND order_id IS NOT NULL
            AND supplier_id IS NULL AND unit_cost_cents IS NULL)
     OR (movement_type = 'adjustment' AND supplier_id IS NULL AND unit_cost_cents IS NULL
            AND order_id IS NULL)
    )
) STRICT;
CREATE INDEX idx_movements_book_date ON inventory_movements(book_id, moved_on);
CREATE INDEX idx_movements_date      ON inventory_movements(moved_on);
CREATE INDEX idx_movements_supplier  ON inventory_movements(supplier_id) WHERE supplier_id IS NOT NULL;
CREATE INDEX idx_movements_order     ON inventory_movements(order_id)    WHERE order_id IS NOT NULL;
-- An order line is sold once and returned once at most.
CREATE UNIQUE INDEX uq_movements_sale   ON inventory_movements(order_id, book_id) WHERE movement_type = 'sale';
CREATE UNIQUE INDEX uq_movements_return ON inventory_movements(order_id, book_id) WHERE movement_type = 'return';
