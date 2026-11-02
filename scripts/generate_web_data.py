import sqlite3
import json
import os

con = sqlite3.connect('data/quran_imdadia.db')
cur = con.cursor()

# 1. Surahs
surahs = []
for r in cur.execute('SELECT id, name_ar, name_en, name_bn, meaning_bn, revelation_type, total_ayahs, start_page FROM surahs ORDER BY id').fetchall():
    surahs.append({
        'id': r[0],
        'name_ar': r[1],
        'name_en': r[2],
        'name_bn': r[3],
        'meaning_bn': r[4] or '',
        'revelation_type': r[5],
        'total_ayahs': r[6],
        'start_page': r[7]
    })

# 2. Juz
juz_list = []
for r in cur.execute('SELECT id, name_ar, name_en, name_bn, start_page FROM juz ORDER BY id').fetchall():
    juz_list.append({
        'id': r[0],
        'name_ar': r[1],
        'name_en': r[2],
        'name_bn': r[3],
        'start_page': r[4]
    })

# 3. Page mapping 1..612
page_map = {}
for p in range(1, 613):
    curr_s = surahs[0]
    for s in surahs:
        if p >= s['start_page']:
            curr_s = s
        else:
            break
    
    curr_j = juz_list[0]
    for j in juz_list:
        if p >= j['start_page']:
            curr_j = j
        else:
            break
            
    page_map[p] = {
        's': curr_s['id'],
        'sn': curr_s['name_bn'],
        'sa': curr_s['name_ar'],
        'se': curr_s['name_en'],
        'j': curr_j['id'],
        'jn': f'পারা {curr_j["id"]}',
        'ja': curr_j['name_ar'],
        'jb': curr_j['name_bn']
    }

for folder in ['landing/data', 'docs/data']:
    os.makedirs(folder, exist_ok=True)
    os.makedirs(os.path.join(folder, 'surahs'), exist_ok=True)

with open('landing/data/surahs.json', 'w', encoding='utf-8') as f:
    json.dump(surahs, f, ensure_ascii=False, indent=2)

with open('landing/data/juz.json', 'w', encoding='utf-8') as f:
    json.dump(juz_list, f, ensure_ascii=False, indent=2)

with open('landing/data/page_map.json', 'w', encoding='utf-8') as f:
    json.dump(page_map, f, ensure_ascii=False, indent=2)

# 4. Generate per-surah JSON for translation study sheet
for s in surahs:
    sid = s['id']
    ayah_rows = cur.execute(
        'SELECT ayah_number, text_indopak FROM ayahs WHERE surah_id = ? ORDER BY ayah_number ASC',
        (sid,)
    ).fetchall()
    
    trans_rows = cur.execute(
        "SELECT ayah_number, text_bn FROM translations WHERE surah_id = ? AND edition = 'taisirul' ORDER BY ayah_number ASC",
        (sid,)
    ).fetchall()
    trans_map = {r[0]: r[1] for r in trans_rows}

    # Also Zakaria if available
    trans_zakaria_rows = cur.execute(
        "SELECT ayah_number, text_bn FROM translations WHERE surah_id = ? AND edition = 'zakaria' ORDER BY ayah_number ASC",
        (sid,)
    ).fetchall()
    trans_zakaria_map = {r[0]: r[1] for r in trans_zakaria_rows}

    ayahs_data = []
    for an, text_ar in ayah_rows:
        ayahs_data.append({
            'a': an,
            'ar': text_ar,
            'bn_t': trans_map.get(an, ''),
            'bn_z': trans_zakaria_map.get(an, '')
        })

    surah_payload = {
        'id': sid,
        'name_ar': s['name_ar'],
        'name_bn': s['name_bn'],
        'name_en': s['name_en'],
        'meaning_bn': s['meaning_bn'],
        'revelation_type': s['revelation_type'],
        'total_ayahs': s['total_ayahs'],
        'start_page': s['start_page'],
        'ayahs': ayahs_data
    }

    for folder in ['landing/data/surahs', 'docs/data/surahs']:
        with open(os.path.join(folder, f'{sid}.json'), 'w', encoding='utf-8') as f:
            json.dump(surah_payload, f, ensure_ascii=False)

print('All web data generated successfully (Surahs, Juz, Page Map, 114 Translation files).')
