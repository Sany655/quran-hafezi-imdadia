"""
build_usmani_toc.py
===================
Defines the volume and Surah layout for Tafsir Usmani across 4 volumes:
  Vol 1: Surahs 1–6 (735 pages)
  Vol 2: Surahs 7–18 (777 pages)
  Vol 3: Surahs 19–38 (748 pages)
  Vol 4: Surahs 39–114 (777 pages)
"""

import json
import sqlite3
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

DB_PATH  = r"data/quran_imdadia.db"
OUT_JSON = r"data/tafsir/tafsir_usmani_toc.json"

VOLUMES = {
    1: {
        'file': "reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_1_Surah_1-6.pdf",
        'surah_start': 1,
        'surah_end': 6,
        'total_pages': 735,
        'content_start_page': 35,  # Surah Al-Fatihah starts on PDF page 35
    },
    2: {
        'file': "reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_2_Surah_7-18.pdf",
        'surah_start': 7,
        'surah_end': 18,
        'total_pages': 777,
        'content_start_page': 15,
    },
    3: {
        'file': "reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_3_Surah_19-38.pdf",
        'surah_start': 19,
        'surah_end': 38,
        'total_pages': 748,
        'content_start_page': 15,
    },
    4: {
        'file': "reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_4_Surah_39-114.pdf",
        'surah_start': 39,
        'surah_end': 114,
        'total_pages': 777,
        'content_start_page': 15,
    }
}

con = sqlite3.connect(DB_PATH)
cur = con.cursor()
db_surahs = cur.execute(
    "SELECT id, name_bn, name_en, name_ar, total_ayahs, start_page FROM surahs ORDER BY id"
).fetchall()
con.close()

surah_map = {}
for r in db_surahs:
    sid = r[0]
    # Find volume
    vol_num = 1
    for v, vinfo in VOLUMES.items():
        if vinfo['surah_start'] <= sid <= vinfo['surah_end']:
            vol_num = v
            break
            
    surah_map[str(sid)] = {
        'surah_id': sid,
        'name_bn': r[1],
        'name_en': r[2],
        'name_ar': r[3],
        'total_ayahs': r[4],
        'mushaf_page': r[5],
        'volume': vol_num,
    }

output = {
    'volumes': VOLUMES,
    'surahs': surah_map
}

os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
with open(OUT_JSON, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"✅ Generated Tafsir Usmani Volume & Surah mapping -> {OUT_JSON}")
