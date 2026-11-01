import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

query = "সালাত"
try:
    sql = '''
      SELECT s.id as surah_id, s.name_bn, s.name_en, f.ayah_number, f.edition, f.text_bn
      FROM search_translations_fts f
      JOIN surahs s ON s.id = f.surah_id
      WHERE search_translations_fts MATCH ?
      LIMIT 100;
    '''
    cur.execute(sql, [query])
    res = cur.fetchall()
    print("Exact app query result count:", len(res))
    if res:
        print("First result:", res[0])
except Exception as e:
    print("Error on exact app query:", e)
