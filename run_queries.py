"""Run every queries/*.sql against bookstore.db and print the results.

    python run_queries.py                  run all 20, print up to 10 rows each
    python run_queries.py 07 14            run only queries 07 and 14
    python run_queries.py --write-samples  also paste the output into each .sql file

A query file is: header comments, the SQL, then (optional) a "/* Sample output"
block that --write-samples rewrites. The block is cut off before the SQL runs.
"""
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MARK = "\n/* Sample output"
SAMPLE_ROWS = 10


def table(cols, rows):
    cells = [[("" if v is None else str(v)) for v in r] for r in rows]
    width = [max([len(c)] + [len(r[i]) for r in cells]) for i, c in enumerate(cols)]
    line = lambda vals: "  ".join(v.ljust(w) for v, w in zip(vals, width)).rstrip()
    return "\n".join([line(cols), line(["-" * w for w in width])] + [line(r) for r in cells])


def main(argv):
    write = "--write-samples" in argv
    wanted = [a for a in argv if not a.startswith("--")]
    conn = sqlite3.connect(f"file:{ROOT / 'bookstore.db'}?mode=ro", uri=True)
    conn.execute("PRAGMA foreign_keys = ON")
    failed = 0
    for path in sorted((ROOT / "queries").glob("*.sql")):
        if wanted and path.name[:2] not in wanted:
            continue
        text = path.read_text(encoding="utf-8")
        head, _, _ = text.partition(MARK)
        head = head.rstrip() + "\n"
        title = head.splitlines()[0].lstrip("- ").strip()
        try:
            cur = conn.execute(head)
            cols = [d[0] for d in cur.description]
            rows = cur.fetchall()
        except sqlite3.Error as e:
            failed += 1
            print(f"FAIL {path.name}: {e}")
            continue
        shown = rows[:SAMPLE_ROWS]
        out = table(cols, shown)
        print(f"\n== {title}\n{out}\n({len(rows)} rows total, {len(shown)} shown)")
        if write:
            note = f"first {len(shown)} of {len(rows)} rows" if len(rows) > len(shown) else f"{len(rows)} rows"
            path.write_text(f"{head}\n/* Sample output ({note}, seed 42 data)\n{out}\n*/\n",
                            encoding="utf-8", newline="\n")
    print(f"\n{'FAILED: ' + str(failed) if failed else 'all queries ran'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
