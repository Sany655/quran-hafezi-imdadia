import sqlite3
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

def count(table):
    cur.execute(f"SELECT COUNT(*) FROM {table}")
    return cur.fetchone()[0]

print("=== FINAL COMPLETE QURAN DATABASE REPORT ===")
print("Database File:", db_path)
print("File Size:", f"{os.path.getsize(db_path) / (1024*1024):.2f} MB")
print("Surahs:", count("surahs"))
print("Juz:", count("juz"))
print("Pages:", count("pages"))
print("Ayahs:", count("ayahs"))
print("Translations (Taisirul + Zakaria):", count("translations"))
print("Word-by-Word entries (words_wbw):", count("words_wbw"))
print("Tafsir entries (Ahsanul Bayaan + Ibn Kathir):", count("tafsirs"))
print("FTS5 Full-Text Search indexed:", count("search_translations_fts"))

# Demonstrate a real app query: User opens Page 2 (Surah Al-Fatihah)
print("\n--- APP SIMULATION: USER OPENS PAGE 2 (Surah Al-Fatihah) ---")
cur.execute("SELECT image_file, juz_number FROM pages WHERE page_number = 2")
p_img, p_juz = cur.fetchone()
print(f"Display Image: {p_img} (Juz {p_juz})")

# Fetch Ayah 1 with Translation, Word-by-Word and Tafsir
print("\nAyah 1:1 Detail:")
cur.execute("SELECT text_indopak FROM ayahs WHERE surah_id = 1 AND ayah_number = 1")
print("  Arabic (Indo-Pak):", cur.fetchone()[0])

cur.execute("SELECT edition, text_bn FROM translations WHERE surah_id = 1 AND ayah_number = 1")
for ed, t in cur.fetchall():
    print(f"  Translation [{ed}]: {t}")

cur.execute("SELECT position, text_arabic, meaning_bn FROM words_wbw WHERE surah_id = 1 AND ayah_number = 1 ORDER BY position")
words = cur.fetchall()
print("  Word-by-Word:")
for w in words:
    print(f"    {w[1]} -> {w[2]}")

cur.execute("SELECT tafsir_name, substr(text_bn, 1, 150) FROM tafsirs WHERE surah_id = 1 AND ayah_number = 1")
for tname, snippet in cur.fetchall():
    clean_snippet = snippet.replace('<p>', '').replace('</p>', '').strip()
    print(f"  Tafsir [{tname}]: {clean_snippet}...")

conn.close()
