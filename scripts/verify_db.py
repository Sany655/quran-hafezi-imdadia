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

print("=== DATABASE INTEGRITY REPORT ===")
print("DB File Size:", f"{os.path.getsize(db_path) / (1024*1024):.2f} MB")
print("Surahs count:", count("surahs"))
print("Juz count:", count("juz"))
print("Pages count:", count("pages"))
print("Ayahs count:", count("ayahs"))
print("Translations count:", count("translations"))
print("Word-by-Word count:", count("words_wbw"))
print("Search FTS index count:", count("search_translations_fts"))

# Sample test search in Bengali
cur.execute("""
    SELECT s.name_bn, t.ayah_number, t.text_bn 
    FROM search_translations_fts f
    JOIN surahs s ON s.id = f.surah_id
    JOIN translations t ON t.surah_id = f.surah_id AND t.ayah_number = f.ayah_number AND t.edition = f.edition
    WHERE search_translations_fts MATCH 'করুণাময়'
    LIMIT 3;
""")
print("\nSample Bengali FTS Search ('করুণাময়'):")
for row in cur.fetchall():
    print(f"  Surah {row[0]} ({row[1]}): {row[2]}")

# Sample Word-by-Word inspection
cur.execute("""
    SELECT position, text_arabic, meaning_bn 
    FROM words_wbw 
    WHERE surah_id = 112 AND ayah_number = 1
    ORDER BY position ASC;
""")
print("\nSample Word-by-Word (Surah Al-Ikhlas 112:1):")
for row in cur.fetchall():
    print(f"  Word {row[0]}: {row[1]} -> {row[2]}")

conn.close()
