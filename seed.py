"""Build bookstore.db from schema.sql and fill it with SYNTHETIC data.

Everything here is made up by a seeded random generator (seed 42), so each run
gives the same database. Names, emails (@example.com), titles and ISBNs
(prefix 999, not a real ISBN prefix) are not real people or books.
"""
import datetime as dt
import random
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "bookstore.db"
SEED = 42
N_ORDERS = 2000
N_CUSTOMERS = 450
N_AUTHORS = 60
N_BOOKS = 160
N_UNSOLD = 10  # lowest-popularity books get weight 0: stock that never sells
START, END = dt.date(2024, 1, 1), dt.date(2025, 12, 31)

FIRST = ["Ava", "Liam", "Noah", "Mia", "Zoe", "Ethan", "Chloe", "Lucas", "Isla", "Oscar",
         "Ruby", "Jack", "Grace", "Leo", "Ella", "Henry", "Lily", "Max", "Nora", "Sam",
         "Hana", "Omar", "Priya", "Mateo", "Yuki", "Amir", "Sofia", "Ivan", "Leila", "Tariq"]
LAST = ["Nguyen", "Smith", "Patel", "Brown", "Kim", "Garcia", "Wilson", "Khan", "Taylor", "Lee",
        "Martin", "Singh", "Clarke", "Rossi", "Ali", "Walker", "Chen", "Hughes", "Novak", "Ito",
        "Evans", "Haddad", "Moreau", "Cohen", "Reid", "Park", "Silva", "Duarte", "Bell", "Fox"]
CITIES = ["Melbourne", "Sydney", "Brisbane", "Perth", "Adelaide", "Hobart", "Canberra", "Geelong"]
CATEGORIES = {  # name: (min price cents, max price cents)
    "Fiction": (1299, 2499), "Mystery": (1199, 2299), "Science Fiction": (1299, 2499),
    "History": (1899, 3499), "Science": (2199, 3999), "Biography": (1799, 3299),
    "Children": (799, 1699), "Cooking": (2299, 3999),
}
SUPPLIERS = [  # invented companies
    ("Harbor Lane Distribution", "AU"), ("Pinegate Book Wholesale", "AU"),
    ("Redfern Press Supply", "AU"), ("Tidewater Books Ltd", "NZ"),
    ("Granite Peak Imports", "US"), ("Bluebell Trade Co", "GB"),
]
ADJ = ["Quiet", "Last", "Hidden", "Silver", "Broken", "Golden", "Distant", "Paper", "Winter",
       "Burning", "Hollow", "Secret", "Lost", "Salt", "Midnight", "Open", "Long", "Red"]
NOUN = ["River", "Garden", "Signal", "Harbour", "Orchard", "Engine", "Lantern", "Border",
        "Archive", "Season", "Atlas", "Window", "Kitchen", "Planet", "Letter", "Mirror"]
MONTH_WEIGHT = {1: .5, 2: .5, 3: .6, 4: .6, 5: .6, 6: .7, 7: .7, 8: .6, 9: .6, 10: .7, 11: 1.0, 12: 1.0}


def money(x):
    return int(round(x))


def build(conn, rng):
    cur = conn.cursor()

    # reference data
    cur.executemany("INSERT INTO categories(category_id, name) VALUES (?, ?)",
                    [(i, n) for i, n in enumerate(CATEGORIES, 1)])
    cat_ids = {n: i for i, n in enumerate(CATEGORIES, 1)}
    cur.executemany("INSERT INTO suppliers(supplier_id, name, email, country) VALUES (?, ?, ?, ?)",
                    [(i, n, "orders@" + n.split()[0].lower() + ".example.com", c)
                     for i, (n, c) in enumerate(SUPPLIERS, 1)])
    names = set()
    while len(names) < N_AUTHORS:
        names.add(f"{rng.choice(FIRST)} {rng.choice(LAST)}")
    authors = sorted(names)
    cur.executemany("INSERT INTO authors(author_id, name) VALUES (?, ?)",
                    [(i, n) for i, n in enumerate(authors, 1)])

    # books: popularity is zipf-like, shuffled; the last N_UNSOLD never sell
    titles = set()
    while len(titles) < N_BOOKS:
        titles.add(f"The {rng.choice(ADJ)} {rng.choice(NOUN)}")
    titles = sorted(titles)
    rng.shuffle(titles)
    book_rows, cat_of = [], {}
    for b in range(1, N_BOOKS + 1):
        cat = rng.choice(list(CATEGORIES))
        lo, hi = CATEGORIES[cat]
        price = rng.randrange(lo // 100 + 1, hi // 100 + 1) * 100 - 1  # ends in .99
        isbn = "999" + f"{rng.randrange(10**10):010d}"
        book_rows.append((b, isbn, titles[b - 1], rng.randint(1, N_AUTHORS), cat_ids[cat],
                          price, rng.randint(1995, 2025)))
        cat_of[b] = cat
    cur.executemany("INSERT INTO books VALUES (?, ?, ?, ?, ?, ?, ?)", book_rows)
    price_of = {r[0]: r[5] for r in book_rows}
    author_of = {r[0]: r[3] for r in book_rows}
    order_ids = list(range(1, N_BOOKS + 1))
    rng.shuffle(order_ids)
    weight = {b: 1 / (rank ** 0.8) for rank, b in enumerate(order_ids, 1)}
    for b in order_ids[-N_UNSOLD:]:
        weight[b] = 0.0
    sellable = [b for b in range(1, N_BOOKS + 1) if weight[b] > 0]
    by_author = {}
    for b in sellable:
        by_author.setdefault(author_of[b], []).append(b)

    # customers: a few buy a lot (pareto weights)
    cust_rows, cust_w, joined = [], [], {}
    span = (dt.date(2025, 11, 30) - dt.date(2023, 7, 1)).days
    for c in range(1, N_CUSTOMERS + 1):
        first, last = rng.choice(FIRST), rng.choice(LAST)
        j = dt.date(2023, 7, 1) + dt.timedelta(days=int(span * rng.random() ** 1.5))
        joined[c] = j
        cust_rows.append((c, first, last, f"{first}.{last}.{c}@example.com".lower(),
                          rng.choice(CITIES), j.isoformat()))
        cust_w.append(min(rng.paretovariate(1.4), 25))
    cur.executemany("INSERT INTO customers VALUES (?, ?, ?, ?, ?, ?)", cust_rows)

    # orders: pick customer, then a date on/after they joined (busier in Nov/Dec)
    raw = []
    while len(raw) < N_ORDERS:
        c = rng.choices(range(1, N_CUSTOMERS + 1), cust_w)[0]
        lo = max(joined[c], START)
        d = lo + dt.timedelta(days=rng.randint(0, (END - lo).days))
        if rng.random() > MONTH_WEIGHT[d.month]:
            continue
        r = rng.random()
        status = "cancelled" if r < .04 else "returned" if r < .07 else "completed"
        raw.append((d, c, "online" if rng.random() < .55 else "in_store", status))
    raw.sort(key=lambda t: t[0])  # order_id grows with date

    movements, items_rows, order_rows = [], [], []
    stock = {b: 0 for b in range(1, N_BOOKS + 1)}
    supplier_of = {b: rng.randint(1, len(SUPPLIERS)) for b in stock}
    base_cost = {b: price_of[b] * rng.uniform(.45, .60) for b in stock}

    def receive(book, day, qty):
        # 80% from the usual supplier, 20% from another one
        sup = supplier_of[book] if rng.random() < .8 else rng.randint(1, len(SUPPLIERS))
        cost = max(1, money(base_cost[book] * rng.uniform(.95, 1.05)))
        movements.append((book, day.isoformat(), "purchase_receipt", qty, sup, cost, None))
        stock[book] += qty

    for b in stock:
        receive(b, dt.date(2023, 12, 1), rng.randint(20, 60))

    for oid, (d, c, channel, status) in enumerate(raw, 1):
        order_rows.append((oid, c, d.isoformat(), channel, status))
        n = rng.choices([1, 2, 3, 4], [60, 25, 10, 5])[0]
        picked = []
        while len(picked) < n:
            if picked and rng.random() < .3 and len(by_author.get(author_of[picked[0]], [])) > 1:
                b = rng.choice(by_author[author_of[picked[0]]])  # same-author pairs
            else:
                b = rng.choices(sellable, [weight[x] for x in sellable])[0]
            if b not in picked:
                picked.append(b)
        for b in picked:
            qty = rng.choices([1, 2, 3], [85, 12, 3])[0]
            unit = price_of[b] if rng.random() > .15 else money(price_of[b] * .9)
            items_rows.append((oid, b, qty, unit))
            if status == "cancelled":
                continue
            if stock[b] < qty:
                receive(b, d - dt.timedelta(days=1), rng.randint(20, 50))
            movements.append((b, d.isoformat(), "sale", -qty, None, None, oid))
            stock[b] -= qty
            if status == "returned":
                back = min(d + dt.timedelta(days=rng.randint(3, 14)), END)
                movements.append((b, back.isoformat(), "return", qty, None, None, oid))
                stock[b] += qty
        if rng.random() < .01:  # shrinkage: a book gets lost or damaged
            b = rng.choice(sellable)
            if stock[b] >= 1:
                movements.append((b, d.isoformat(), "adjustment", -1, None, None, None))
                stock[b] -= 1

    cur.executemany("INSERT INTO orders VALUES (?, ?, ?, ?, ?)", order_rows)
    cur.executemany("INSERT INTO order_items VALUES (?, ?, ?, ?)", items_rows)
    movements.sort(key=lambda m: m[1])
    cur.executemany("""INSERT INTO inventory_movements
        (book_id, moved_on, movement_type, quantity_change, supplier_id, unit_cost_cents, order_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)""", movements)


def check(conn):
    """Self-check: fail loudly instead of shipping a broken database."""
    q = lambda sql: conn.execute(sql).fetchone()[0]
    assert q("PRAGMA integrity_check") == "ok"
    assert conn.execute("PRAGMA foreign_key_check").fetchall() == []
    assert q("SELECT COUNT(*) FROM orders") == N_ORDERS
    assert q("SELECT COUNT(*) FROM customers") == N_CUSTOMERS
    assert q("""SELECT COUNT(*) FROM (SELECT book_id FROM inventory_movements
                GROUP BY book_id HAVING SUM(quantity_change) < 0)""") == 0, "negative stock"
    assert q("""SELECT COUNT(*) FROM orders o WHERE NOT EXISTS
                (SELECT 1 FROM order_items i WHERE i.order_id = o.order_id)""") == 0, "empty order"


def main():
    DB_PATH.unlink(missing_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript((ROOT / "schema.sql").read_text(encoding="utf-8"))
    with conn:
        build(conn, random.Random(SEED))
    check(conn)
    for t in ["authors", "categories", "suppliers", "books", "customers", "orders",
              "order_items", "inventory_movements"]:
        print(f"{t:22} {conn.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]:>6} rows")
    conn.close()
    print(f"built {DB_PATH.name} (synthetic data, seed {SEED})")


if __name__ == "__main__":
    sys.exit(main())
