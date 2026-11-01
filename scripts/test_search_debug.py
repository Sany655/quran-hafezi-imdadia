import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Test 1: Check what is in translations table for 'সালাত' using LIKE
cur.execute("SELECT surah_id, ayah_number, edition, text_bn FROM translations WHERE text_bn LIKE '%সালাত%' LIMIT 5;")
like_results = cur.fetchall()
print(f"LIKE '%সালাত%' count in translations: {len(like_results)}")
for r in like_results:
    print(" ", r[0], r[1], r[2], r[3][:60])

# Test 2: Check FTS5 with 'সালাত'
print("\nTesting FTS5 with 'সালাত':")
try:
    cur.execute("SELECT * FROM search_translations_fts WHERE search_translations_fts MATCH 'সালাত' LIMIT 5;")
    fts_res = cur.fetchall()
    print("FTS5 match count:", len(fts_res))
    for r in fts_res:
        print(" ", r)
except Exception as e:
    print("FTS5 error:", e)

# Test 3: Check how FTS5 was created and tokenized
cur.execute("SELECT sql FROM sqlite_master WHERE name = 'search_translations_fts';")
print("\nFTS table definition:")
print(cur.fetchone()[0])

# Test 4: Check if translations table has 'নামায' vs 'সালাত' vs 'সালাতের' vs 'নামাজ'
for term in ['সালাত', 'সালাতের', 'নামায', 'নামাজ', 'রহমান']:
    cur.execute(f"SELECT COUNT(*) FROM translations WHERE text_bn LIKE '%{term}%';")
    cnt = cur.fetchone()[0]
    print(f"Term '{term}': {cnt} occurrences in translations")
