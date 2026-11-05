import sqlite3
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

app_db_path = 'data/quran_imdadia.db'
source_db_path = 'drafts/ashraf_db/taojihul.db'

print(f"Connecting to source DB: {source_db_path}...")
src_con = sqlite3.connect(source_db_path)
src_cur = src_con.cursor()

print(f"Connecting to target DB: {app_db_path}...")
dest_con = sqlite3.connect(app_db_path)
dest_cur = dest_con.cursor()

# 1. Fetch all 6,236 Ayahs from source
rows = src_cur.execute("""
    SELECT sura_no, ayah_no, translate, tafseer 
    FROM ayah 
    ORDER BY sura_no, ayah_no
""").fetchall()

print(f"Fetched {len(rows)} verses from source database.")

# 2. Prepare data for `translations` table
# Clean translation text by removing <sup>...</sup> tags
translation_rows = []
for s_no, a_no, tr_raw, _ in rows:
    clean_tr = re.sub(r'<sup>[^<]*</sup>', '', tr_raw or '').strip()
    translation_rows.append((s_no, a_no, 'tawzeehul', clean_tr))

# 3. Prepare data for `tafsirs` table
# Tafsir text keeps full formatted HTML notes
tafsir_rows = []
active_tafsir_count = 0
for s_no, a_no, _, taf_raw in rows:
    vk = f"{s_no}:{a_no}"
    taf_clean = taf_raw.strip() if taf_raw else ""
    if taf_clean:
        active_tafsir_count += 1
    tafsir_rows.append((s_no, a_no, vk, 170, 'tawzeehul_quran', taf_clean))

print(f"Prepared {len(translation_rows)} translations (edition='tawzeehul').")
print(f"Prepared {len(tafsir_rows)} tafsir entries (name='tawzeehul_quran', active={active_tafsir_count}).")

# 4. Insert into `translations` table
print("Updating `translations` table...")
dest_cur.execute("DELETE FROM translations WHERE edition = 'tawzeehul'")
dest_cur.executemany(
    "INSERT INTO translations (surah_id, ayah_number, edition, text_bn) VALUES (?, ?, ?, ?)",
    translation_rows
)
print(f"Inserted {dest_cur.rowcount} rows into translations.")

# 5. Insert into `tafsirs` table
print("Updating `tafsirs` table...")
dest_cur.execute("DELETE FROM tafsirs WHERE tafsir_name = 'tawzeehul_quran'")
dest_cur.executemany(
    "INSERT INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn) VALUES (?, ?, ?, ?, ?, ?)",
    tafsir_rows
)
print(f"Inserted {dest_cur.rowcount} rows into tafsirs.")

# 6. Rebuild FTS search index
print("Rebuilding `search_translations_fts` index...")
dest_cur.execute("DELETE FROM search_translations_fts;")
dest_cur.execute("""
    INSERT INTO search_translations_fts(rowid, surah_id, ayah_number, edition, text_bn)
    SELECT id, surah_id, ayah_number, edition, text_bn FROM translations;
""")
print("Rebuilt search_translations_fts.")

dest_con.commit()

# 7. Verification queries
print("\n--- Verification Summary ---")
dest_cur.execute("SELECT edition, count(*) FROM translations GROUP BY edition")
print("Translations Editions:", dest_cur.fetchall())

dest_cur.execute("SELECT tafsir_name, count(*) FROM tafsirs GROUP BY tafsir_name")
print("Tafsirs Editions:", dest_cur.fetchall())

# Check sample Surah 1:1
sample_tr = dest_cur.execute("SELECT text_bn FROM translations WHERE edition='tawzeehul' AND surah_id=1 AND ayah_number=1").fetchone()[0]
sample_taf = dest_cur.execute("SELECT text_bn FROM tafsirs WHERE tafsir_name='tawzeehul_quran' AND surah_id=1 AND ayah_number=1").fetchone()[0]

print(f"\nSample Surah 1:1 Translation:\n{sample_tr}")
print(f"\nSample Surah 1:1 Tafsir:\n{sample_taf[:150]}...")

src_con.close()
dest_con.close()
print("\nIngestion successfully completed!")
