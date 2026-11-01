import sqlite3
import urllib.request
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

cur.execute("""
CREATE TABLE IF NOT EXISTS tafsirs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    verse_key TEXT NOT NULL,
    tafsir_id INTEGER NOT NULL,
    tafsir_name TEXT NOT NULL,
    text_bn TEXT NOT NULL,
    FOREIGN KEY(surah_id) REFERENCES surahs(id)
);
""")
cur.execute("CREATE INDEX IF NOT EXISTS idx_tafsirs_lookup ON tafsirs(surah_id, ayah_number, tafsir_id);")
conn.commit()
conn.close()
print("Tafsir table ready in SQLite!")
