import sqlite3
import os

db_path = 'data/quran_imdadia.db'

print(f"Opening {db_path}...")
con = sqlite3.connect(db_path)
cur = con.cursor()

# Check initial count of zakaria
cur.execute("SELECT count(*) FROM translations WHERE edition = 'zakaria'")
zakaria_count = cur.fetchone()[0]
print(f"Current 'zakaria' rows in translations: {zakaria_count}")

# 1. Remove zakaria from translations table
cur.execute("DELETE FROM translations WHERE edition = 'zakaria'")
print(f"Deleted {cur.rowcount} rows where edition = 'zakaria'")

# 2. Check FTS table
fts_tables = [r[0] for r in cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='search_translations_fts'").fetchall()]
if fts_tables:
    print("Rebuilding search_translations_fts index...")
    try:
        cur.execute("DELETE FROM search_translations_fts;")
        # Re-populate search_translations_fts from existing translations
        cur.execute("""
            INSERT INTO search_translations_fts(rowid, surah_id, ayah_number, edition, text_bn)
            SELECT id, surah_id, ayah_number, edition, text_bn FROM translations;
        """)
        print("Rebuilt search_translations_fts successfully.")
    except Exception as e:
        print(f"FTS update warning: {e}")

con.commit()

# Verify remaining editions
cur.execute("SELECT edition, count(*) FROM translations GROUP BY edition")
print("Remaining editions in translations:", cur.fetchall())

con.close()
print("Done removing Abu Bakr Zakaria's translation from SQLite DB.")
