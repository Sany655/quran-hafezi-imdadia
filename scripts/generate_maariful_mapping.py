import sqlite3
import json
import os

con = sqlite3.connect('data/quran_imdadia.db')
cur = con.cursor()

def to_bn_num(n):
    bn_digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯']
    return ''.join(bn_digits[int(d)] if d.isdigit() else d for d in str(n))

surahs = {s[0]: s[1] for s in cur.execute("SELECT id, name_bn FROM surahs").fetchall()}

vol_info = {
    1: {'title': '১ম খণ্ড (সূরা আল-ফাতিহা ও সূরা আল-বাকারা)', 'item': 'mareful-quran-01-new-edition', 'leaves': 654, 'start_leaf': 63},
    2: {'title': '২য় খণ্ড (সূরা আলে-ইমরান ও সূরা আন-নিসা)', 'item': 'mareful-quran-02-new-edition', 'leaves': 578, 'start_leaf': 25},
    3: {'title': '৩য় খণ্ড (সূরা আল-মায়িদাহ ও সূরা আল-আনআম)', 'item': 'mareful-quran-03-new-edition', 'leaves': 564, 'start_leaf': 20},
    4: {'title': '৪র্থ খণ্ড (সূরা আল-আরাফ, আল-আনফাল ও আত-তাওবাহ)', 'item': 'mareful-quran-04-new-edition', 'leaves': 671, 'start_leaf': 20},
    5: {'title': '৫ম খণ্ড (সূরা ইউনুস থেকে সূরা আন-নাহল)', 'item': 'mareful-quran-05-new-edition', 'leaves': 670, 'start_leaf': 20},
    6: {'title': '৬ষ্ঠ খণ্ড (সূরা বনী-ইসরাঈল থেকে সূরা আল-ফুরকান)', 'item': 'mareful-quran-06-new-edition', 'leaves': 750, 'start_leaf': 20},
    7: {'title': '৭ম খণ্ড (সূরা আশ-শুআরা থেকে সূরা ছোয়াদ)', 'item': 'mareful-quran-07-new-edition', 'leaves': 825, 'start_leaf': 20},
    8: {'title': '৮ম খণ্ড (সূরা আয-যুমার থেকে সূরা আন-নাস)', 'item': 'mareful-quran-08-new-edition', 'leaves': 924, 'start_leaf': 20},
}

def get_volume(surah_id):
    if surah_id in [1, 2]: return 1
    if surah_id in [3, 4]: return 2
    if surah_id in [5, 6]: return 3
    if surah_id in [7, 8, 9]: return 4
    if 10 <= surah_id <= 16: return 5
    if 17 <= surah_id <= 25: return 6
    if 26 <= surah_id <= 38: return 7
    return 8

vol_mushaf_range = {
    1: [1, 50],
    2: [51, 107],
    3: [108, 151],
    4: [152, 208],
    5: [209, 282],
    6: [283, 367],
    7: [368, 459],
    8: [460, 612],
}

mapping = []
for p in range(1, 613):
    rows = cur.execute("""
        SELECT surah_id, ayah_number 
        FROM ayahs 
        WHERE page_number = ? 
        ORDER BY id ASC
    """, (p,)).fetchall()
    
    if not rows:
        if p == 2:
            s_start, a_start = 1, 1
            s_end, a_end = 1, 7
        elif p == 612:
            s_start, a_start = 114, 1
            s_end, a_end = 114, 6
        else:
            prev_row = cur.execute("SELECT surah_id, ayah_number FROM ayahs WHERE page_number < ? ORDER BY id DESC LIMIT 1", (p,)).fetchone()
            s_start = prev_row[0] if prev_row else 1
            a_start = prev_row[1] if prev_row else 1
            s_end, a_end = s_start, a_start
    else:
        s_start, a_start = rows[0]
        s_end, a_end = rows[-1]
        
    v = get_volume(s_start)
    v_info = vol_info[v]
    m_start_p, m_end_p = vol_mushaf_range[v]
    
    total_m_pages = max(1, m_end_p - m_start_p)
    progress = (p - m_start_p) / total_m_pages
    
    start_leaf = v_info['start_leaf']
    end_leaf = v_info['leaves'] - 5
    leaf_num = int(start_leaf + progress * (end_leaf - start_leaf))
    leaf_num = max(1, min(leaf_num, v_info['leaves']))
    
    printed_page = max(1, leaf_num - 15)
    item_name = v_info['item']
    reader_url = f"https://archive.org/details/mareful/new/{item_name}/page/n{leaf_num}/mode/1up"
    
    surah_str = surahs.get(s_start, '')
    if s_start != s_end and s_end in surahs:
        surah_str += f" - {surahs[s_end]}"
        
    verse_range_str = f"{s_start}:{a_start} – {s_end}:{a_end}"
    
    mapping.append({
        'mushaf_page': p,
        'volume': v,
        'volume_title_bn': v_info['title'],
        'surah_name_bn': surah_str,
        'verse_range': verse_range_str,
        'leaf_number': leaf_num,
        'printed_page': printed_page,
        'printed_page_bn': to_bn_num(printed_page),
        'reader_url': reader_url,
        'pdf_filename': f"Maariful_Quran_Vol_0{v}.pdf"
    })

print(f"Generated exactly {len(mapping)} page mappings (1 to 612).")

cur.execute("DROP TABLE IF EXISTS maariful_quran_map;")
cur.execute("""
CREATE TABLE maariful_quran_map (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mushaf_page INTEGER UNIQUE NOT NULL,
    volume INTEGER NOT NULL,
    volume_title_bn TEXT NOT NULL,
    surah_name_bn TEXT NOT NULL,
    verse_range TEXT NOT NULL,
    leaf_number INTEGER NOT NULL,
    printed_page INTEGER NOT NULL,
    printed_page_bn TEXT NOT NULL,
    reader_url TEXT NOT NULL,
    pdf_filename TEXT NOT NULL
);
""")

for m in mapping:
    cur.execute("""
        INSERT INTO maariful_quran_map (
            mushaf_page, volume, volume_title_bn, surah_name_bn, 
            verse_range, leaf_number, printed_page, printed_page_bn, 
            reader_url, pdf_filename
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        m['mushaf_page'], m['volume'], m['volume_title_bn'], m['surah_name_bn'],
        m['verse_range'], m['leaf_number'], m['printed_page'], m['printed_page_bn'],
        m['reader_url'], m['pdf_filename']
    ))

con.commit()
print("Saved to SQLite table maariful_quran_map.")

os.makedirs('landing/data', exist_ok=True)
with open('data/maariful_quran_map.json', 'w', encoding='utf-8') as f:
    json.dump(mapping, f, ensure_ascii=False, indent=2)

with open('landing/data/maariful_quran_map.json', 'w', encoding='utf-8') as f:
    json.dump(mapping, f, ensure_ascii=False)

print("Saved JSON files.")
con.close()
