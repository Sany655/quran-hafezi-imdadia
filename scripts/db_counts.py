import sqlite3

con = sqlite3.connect('data/quran_imdadia.db')
cur = con.cursor()
tables = [r[0] for r in cur.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
for t in tables:
    try:
        cnt = cur.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
        print(f"Table {t}: {cnt} rows")
    except Exception as e:
        print(f"Table {t}: error {e}")
