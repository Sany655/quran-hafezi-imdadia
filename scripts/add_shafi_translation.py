import sqlite3
import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
db_path = 'data/quran_imdadia.db'

print("Fetching Mufti Shafi / Muhiuddin Khan translation dataset (6236 ayahs)...")
url = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ben-muhiuddinkhan.json'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=30) as r:
    data = json.loads(r.read().decode('utf-8'))
    quran = data.get('quran', [])

print(f"Downloaded {len(quran)} verses. Inserting into {db_path}...")

con = sqlite3.connect(db_path)
cur = con.cursor()

# Remove existing if any
cur.execute("DELETE FROM translations WHERE edition = 'shafi'")

# Insert 6236 verses
rows_to_insert = []
for v in quran:
    surah_id = v['chapter']
    ayah_num = v['verse']
    text = v['text'].strip()
    rows_to_insert.append((surah_id, ayah_num, 'shafi', text))

cur.executemany(
    "INSERT INTO translations (surah_id, ayah_number, edition, text_bn) VALUES (?, ?, ?, ?)",
    rows_to_insert
)
print(f"Inserted {len(rows_to_insert)} rows for edition='shafi'.")

# Update search FTS
cur.execute("DELETE FROM search_translations_fts;")
cur.execute("""
    INSERT INTO search_translations_fts(rowid, surah_id, ayah_number, edition, text_bn)
    SELECT id, surah_id, ayah_number, edition, text_bn FROM translations;
""")
print("Rebuilt search_translations_fts.")

con.commit()

# Verify
cur.execute("SELECT edition, count(*) FROM translations GROUP BY edition")
print("Editions in translations table:", cur.fetchall())

con.close()
print("Successfully added Shafi Saheb's Tarjuma into SQLite DB.")
