"""
build_maariful_short_toc.py
===========================
Builds the complete and verified mapping of all 114 Surahs for
Maariful Quran Short Complete edition using the verified TOC page.
"""

import json
import sqlite3
import re
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

DB_PATH   = r"data/quran_imdadia.db"
TOC_JSON  = r"data/tafsir/maariful_short_toc.json"
PDF_PATH  = r"reference_books/maariful_quran_bangla/Maariful_Quran_Short_Complete.pdf"

# Connect to DB to load authentic Surah metadata
con = sqlite3.connect(DB_PATH)
cur = con.cursor()
db_surahs = cur.execute(
    "SELECT id, name_bn, name_en, name_ar, total_ayahs, start_page FROM surahs ORDER BY id"
).fetchall()
con.close()

# The TOC on Page 2 has 57 rows of Surahs:
# Row 1 (index 0): Surah 1 (left) & Surah 58 (right)
# ...
# Row 57 (index 56): Surah 57 (left) & Surah 114 (right)
#
# Below are the verified printed Tafsir page numbers extracted directly
# from the TOC and verified against the PDF.

TOC_PRINTED_PAGES = {
    1: 1,      58: 1343,
    2: 11,     59: 1348,
    3: 163,    60: 1358,
    4: 227,    61: 1364,
    5: 302,    62: 1368,
    6: 366,    63: 1370,
    7: 429,    64: 1376,
    8: 514,    65: 1379,
    9: 552,    66: 1383,
    10: 599,   67: 1390,
    11: 619,   68: 1394,
    12: 650,   69: 1399,
    13: 696,   70: 1401,
    14: 710,   71: 1405,
    15: 720,   72: 1408,
    16: 733,   73: 1413,
    17: 763,   74: 1419,
    18: 796,   75: 1422,
    19: 829,   76: 1426,
    20: 843,   77: 1429,
    21: 869,   78: 1431,
    22: 891,   79: 1433,
    23: 911,   80: 1436,
    24: 924,   81: 1438,
    25: 954,   82: 1440,
    26: 971,   83: 1441,
    27: 986,   84: 1444,
    28: 1005,  85: 1446,
    29: 1023,  86: 1447,
    30: 1035,  87: 1449,
    31: 1051,  88: 1449,
    32: 1062,  89: 1452,
    33: 1068,  90: 1457,
    34: 1102,  91: 1457,
    35: 1116,  92: 1459,
    36: 1126,  93: 1461,
    37: 1138,  94: 1461,
    38: 1158,  95: 1464,
    39: 1172,  96: 1464,
    40: 1184,  97: 1467,
    41: 1197,  98: 1467,
    42: 1210,  99: 1470,
    43: 1223,  100: 1470,
    44: 1234,  101: 1472,
    45: 1240,  102: 1472,
    46: 1246,  103: 1474,
    47: 1253,  104: 1474,
    48: 1264,  105: 1474,
    49: 1273,  106: 1476,
    50: 1287,  107: 1476,
    51: 1292,  108: 1476,
    52: 1298,  109: 1476,
    53: 1302,  110: 1480,
    54: 1310,  111: 1480,
    55: 1315,  112: 1480,
    56: 1323,  113: 1484,
    57: 1330,  114: 1484,
}

# The offset between printed book page and PDF 0-based index:
# Book page 1 is PDF page 4 -> offset = 3
PAGE_OFFSET = 3
TOTAL_PDF_PAGES = 1492

surah_map = {}
for i in range(1, 115):
    db_s = db_surahs[i - 1]
    p_start = TOC_PRINTED_PAGES[i]
    pdf_start = p_start + PAGE_OFFSET - 1  # 0-indexed PDF page
    
    # Calculate end page
    if i < 114:
        p_next = TOC_PRINTED_PAGES[i + 1]
        pdf_end = p_next + PAGE_OFFSET - 1
    else:
        pdf_end = TOTAL_PDF_PAGES - 1
        
    surah_map[str(i)] = {
        'surah_id': i,
        'name_bn': db_s[1],
        'name_en': db_s[2],
        'name_ar': db_s[3],
        'total_ayahs': db_s[4],
        'mushaf_page': db_s[5],
        'printed_tafsir_page_start': p_start,
        'pdf_page_start': pdf_start,  # 0-based
        'pdf_page_end': pdf_end,      # 0-based
        'total_pdf_pages': pdf_end - pdf_start + 1
    }

# Build continuous page_to_surah lookup for all 1492 pages
page_to_surah = []
for p in range(TOTAL_PDF_PAGES):
    # Find which surah this PDF page belongs to
    assigned_sid = 1
    if p < PAGE_OFFSET:
        assigned_sid = 0  # Intro / TOC
    else:
        for sid in range(114, 0, -1):
            if p >= surah_map[str(sid)]['pdf_page_start']:
                assigned_sid = sid
                break
                
    page_to_surah.append({
        'pdf_page': p,
        'surah_id': assigned_sid,
        'surah_name_bn': surah_map[str(assigned_sid)]['name_bn'] if assigned_sid > 0 else 'ভূমিকা ও সূচীপত্র'
    })

os.makedirs(os.path.dirname(TOC_JSON), exist_ok=True)
output = {
    'pdf_path': PDF_PATH,
    'total_pdf_pages': TOTAL_PDF_PAGES,
    'page_offset': PAGE_OFFSET,
    'surahs': surah_map,
    'page_to_surah': page_to_surah
}

with open(TOC_JSON, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"✅ Generated accurate TOC mapping for all 114 Surahs -> {TOC_JSON}")
print("Sample entries:")
for s in [1, 2, 3, 113, 114]:
    entry = surah_map[str(s)]
    print(f"  Surah {s:3d} ({entry['name_bn']:18s}): Tafsir p.{entry['printed_tafsir_page_start']:4d} -> PDF p.{entry['pdf_page_start']+1:4d}–{entry['pdf_page_end']+1:4d}")
