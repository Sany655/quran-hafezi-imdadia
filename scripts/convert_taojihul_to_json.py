import sqlite3
import json
import os
import re

# Output directory
out_dir = 'data/tafsir/tawzeehul_quran'
os.makedirs(out_dir, exist_ok=True)

con = sqlite3.connect('drafts/ashraf_db/taojihul.db')
cur = con.cursor()

# 1. Fetch Surah list
surahs = cur.execute("""
    SELECT id, sura_no, name_arabic, name_bengali, meaning_bengali, ayah_count, type, preface
    FROM surah ORDER BY id
""").fetchall()

surah_dict = {}
for s in surahs:
    s_id, s_no, name_ar, name_bn, meaning_bn, ayah_cnt, s_type, preface = s
    surah_dict[s_id] = {
        'surah_id': s_id,
        'name_arabic': name_ar,
        'name_bengali': name_bn,
        'meaning_bengali': meaning_bn,
        'ayah_count': ayah_cnt,
        'type': s_type,
        'preface': preface
    }

# 2. Fetch all Ayahs
ayahs = cur.execute("""
    SELECT sura_no, ayah_no, arabic_indo, translate, tafseer
    FROM ayah ORDER BY sura_no, ayah_no
""").fetchall()

print(f"Total Ayahs fetched: {len(ayahs)}")

# Group by Surah
by_surah = {}
for a in ayahs:
    s_no, a_no, ar_text, tr_text, taf_text = a
    if s_no not in by_surah:
        by_surah[s_no] = []
    
    # Clean translation: extract footnotes markers if any
    markers = re.findall(r'<sup>([^<]+)</sup>', tr_text or '')
    
    by_surah[s_no].append({
        'surah': s_no,
        'ayah': a_no,
        'verse_key': f"{s_no}:{a_no}",
        'arabic': ar_text,
        'translation': tr_text,
        'footnote_markers': markers,
        'tafsir': taf_text if taf_text else None
    })

# Write individual Surah JSON files
total_tafsir_count = 0
for s_no, verses in by_surah.items():
    s_meta = surah_dict.get(s_no, {})
    file_path = os.path.join(out_dir, f"surah_{s_no:03d}.json")
    surah_data = {
        'edition': 'tawzeehul_quran',
        'book_name': 'তাফসীরে তাওযীহুল কুরআন',
        'author': 'মুফতী মুহাম্মদ তাকী উসমানী',
        'translator': 'মাওলানা আবুল বাশার মুহাম্মদ সাইফুল ইসলাম',
        'publisher': 'মাকতাবাতুল আশরাফ',
        'surah_id': s_no,
        'surah_name_bn': s_meta.get('name_bengali', ''),
        'surah_name_ar': s_meta.get('name_arabic', ''),
        'type': s_meta.get('type', ''),
        'ayah_count': len(verses),
        'preface': s_meta.get('preface', ''),
        'verses': verses
    }
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(surah_data, f, ensure_ascii=False, indent=2)
    
    total_tafsir_count += sum(1 for v in verses if v['tafsir'])

print(f"Wrote {len(by_surah)} Surah JSON files to {out_dir}/")
print(f"Verses with active Tafsir commentary: {total_tafsir_count} / {len(ayahs)}")
