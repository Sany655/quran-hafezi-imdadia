import sqlite3
import json
import os
import sys

db_path = 'data/quran_imdadia.db'
if not os.path.exists(db_path):
    print(f'Error: Database file not found at {db_path}')
    sys.exit(1)

with open(db_path, 'rb') as f:
    header = f.read(16)

if not header.startswith(b'SQLite format 3'):
    print(f'Notice: {db_path} is an LFS pointer text file (not checked out with Git LFS).')
    print('Static web data is already up-to-date in repository. Skipping generation safely.')
    sys.exit(0)

con = sqlite3.connect(db_path)
cur = con.cursor()

# 1. Surahs
surahs = []
surahs_by_id = {}
for r in cur.execute('SELECT id, name_ar, name_en, name_bn, meaning_bn, revelation_type, total_ayahs, start_page FROM surahs ORDER BY id').fetchall():
    item = {
        'id': r[0],
        'name_ar': r[1],
        'name_en': r[2],
        'name_bn': r[3],
        'meaning_bn': r[4] or '',
        'revelation_type': r[5],
        'total_ayahs': r[6],
        'start_page': r[7]
    }
    surahs.append(item)
    surahs_by_id[r[0]] = item

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

# 3. Load 15-line Hafezi page-verse map
with open('data/imdadia_page_verse_map.json', 'r', encoding='utf-8') as f:
    page_verse_map = json.load(f)

# 4. Page mapping 1..612
page_map = {}
for p in range(1, 613):
    p_info = page_verse_map.get(str(p), {
        'start_surah': 1,
        'start_ayah': 1,
        'end_surah': 1,
        'end_ayah': 7,
        'all_verses': ['1:1']
    })
    
    start_s = surahs_by_id.get(p_info['start_surah'], surahs[0])
    
    curr_j = juz_list[0]
    for j in juz_list:
        if p >= j['start_page']:
            curr_j = j
        else:
            break
            
    page_map[p] = {
        's': start_s['id'],
        'sn': start_s['name_bn'],
        'sa': start_s['name_ar'],
        'se': start_s['name_en'],
        'start_ayah': p_info['start_ayah'],
        'end_surah': p_info['end_surah'],
        'end_ayah': p_info['end_ayah'],
        'verses': p_info['all_verses'],
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

for fname in ['surahs.json', 'juz.json', 'page_map.json']:
    with open(os.path.join('docs/data', fname), 'w', encoding='utf-8') as f:
        with open(os.path.join('landing/data', fname), 'r', encoding='utf-8') as sf:
            f.write(sf.read())

# 5. Generate per-surah JSON for translation study sheet
for s in surahs:
    sid = s['id']
    ayah_rows = cur.execute(
        'SELECT ayah_number, text_indopak, page_number FROM ayahs WHERE surah_id = ? ORDER BY ayah_number ASC',
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

    # Word-by-word data
    wbw_rows = cur.execute(
        "SELECT ayah_number, position, text_arabic, meaning_bn FROM words_wbw WHERE surah_id = ? ORDER BY ayah_number ASC, position ASC",
        (sid,)
    ).fetchall()
    wbw_map = {}
    for an, pos, ar_w, bn_w in wbw_rows:
        if an not in wbw_map:
            wbw_map[an] = []
        wbw_map[an].append({'w': ar_w, 'm': bn_w or ''})

    ayahs_data = []
    for an, text_ar, p_num in ayah_rows:
        ayahs_data.append({
            'a': an,
            'p': p_num,
            'ar': text_ar,
            'bn_t': trans_map.get(an, ''),
            'bn_z': trans_zakaria_map.get(an, ''),
            'words': wbw_map.get(an, [])
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

# 6. Generate per-page Tafsir JSON for Study Sheet
print('Generating per-page Tafsir data...')
for folder in ['landing/data/tafsir', 'docs/data/tafsir']:
    os.makedirs(folder, exist_ok=True)

all_tafsirs = cur.execute('SELECT surah_id, ayah_number, tafsir_id, text_bn FROM tafsirs').fetchall()
tafsir_cache = {}
for s_id, a_num, t_id, txt in all_tafsirs:
    tafsir_cache[(s_id, a_num, t_id)] = txt or ''

for p in range(2, 612):
    p_info = page_map.get(p, {})
    verses = p_info.get('verses', [])
    page_data = {}
    for vk in verses:
        s_id, a_num = map(int, vk.split(':'))
        page_data[vk] = {
            's': s_id,
            'a': a_num,
            'ik': tafsir_cache.get((s_id, a_num, 164), ''),
            'ab': tafsir_cache.get((s_id, a_num, 165), '')
        }
    for folder in ['landing/data/tafsir', 'docs/data/tafsir']:
        with open(os.path.join(folder, f'{p}.json'), 'w', encoding='utf-8') as f:
            json.dump(page_data, f, ensure_ascii=False)

# 7. Generate Search Index
print('Generating global search index...')
import re
def remove_tashkeel(text):
    text = re.sub(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0610-\u061A\u08D4-\u08E1\u08E3-\u08FF]', '', text)
    text = re.sub(r'[إأآٱ]', 'ا', text)
    text = re.sub(r'[يى]', 'ي', text)
    text = re.sub(r'ة', 'ه', text)
    text = re.sub(r'ـ', '', text)
    return text.strip()

search_index = []
for sid in range(1, 115):
    path = f'landing/data/surahs/{sid}.json'
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            s_data = json.load(f)
        for ayah in s_data.get('ayahs', []):
            search_index.append({
                's': sid,
                'sn': s_data['name_bn'],
                'sna': s_data.get('name_ar', ''),
                'a': ayah['a'],
                'p': ayah['p'],
                'ar': ayah.get('ar', ''),
                'arc': remove_tashkeel(ayah.get('ar', '')),
                'bnt': ayah.get('bn_t', ''),
                'bnz': ayah.get('bn_z', '')
            })

for folder in ['landing/data', 'docs/data']:
    with open(os.path.join(folder, 'search_index.json'), 'w', encoding='utf-8') as f:
        json.dump(search_index, f, ensure_ascii=False, separators=(',', ':'))

print('All web data generated successfully with synced page-verse mapping, Tafsir, and Search Index!')
con.close()
