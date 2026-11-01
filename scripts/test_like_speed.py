import sqlite3
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

start = time.perf_counter()
query = "সালাত"
sql = '''
    SELECT s.id as surah_id, s.name_bn, s.name_en, t.ayah_number, t.edition, t.text_bn
    FROM translations t
    JOIN surahs s ON s.id = t.surah_id
    WHERE t.text_bn LIKE ?
    LIMIT 100;
'''
cur.execute(sql, [f"%{query}%"])
res = cur.fetchall()
elapsed_ms = (time.perf_counter() - start) * 1000

print(f"LIKE query took: {elapsed_ms:.2f} ms")
print(f"Results found: {len(res)}")
if res:
    print("First 3 results:")
    for r in res[:3]:
        print(f"  Surah {r[1]} ({r[3]}): {r[5][:80]}...")
