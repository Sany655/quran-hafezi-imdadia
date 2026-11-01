import sqlite3
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Enable WAL mode for high performance
cur.execute("PRAGMA journal_mode=WAL;")

# 1. Surahs table
cur.execute("""
CREATE TABLE IF NOT EXISTS surahs (
    id INTEGER PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_bn TEXT NOT NULL,
    meaning_bn TEXT,
    revelation_type TEXT NOT NULL,
    total_ayahs INTEGER NOT NULL,
    start_page INTEGER NOT NULL
);
""")

# 2. Juz table
cur.execute("""
CREATE TABLE IF NOT EXISTS juz (
    id INTEGER PRIMARY KEY,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    name_bn TEXT NOT NULL,
    start_page INTEGER NOT NULL
);
""")

# 3. Pages table
cur.execute("""
CREATE TABLE IF NOT EXISTS pages (
    page_number INTEGER PRIMARY KEY,
    image_file TEXT NOT NULL,
    juz_number INTEGER
);
""")

# 4. Ayahs table
cur.execute("""
CREATE TABLE IF NOT EXISTS ayahs (
    id INTEGER PRIMARY KEY,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    verse_key TEXT NOT NULL,
    text_indopak TEXT NOT NULL,
    text_uthmani TEXT NOT NULL,
    FOREIGN KEY(surah_id) REFERENCES surahs(id)
);
""")

# 5. Translations table
cur.execute("""
CREATE TABLE IF NOT EXISTS translations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    edition TEXT NOT NULL,
    text_bn TEXT NOT NULL,
    FOREIGN KEY(surah_id) REFERENCES surahs(id)
);
""")

# 6. Word-by-Word table
cur.execute("""
CREATE TABLE IF NOT EXISTS words_wbw (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    surah_id INTEGER NOT NULL,
    ayah_number INTEGER NOT NULL,
    position INTEGER NOT NULL,
    text_arabic TEXT NOT NULL,
    meaning_bn TEXT NOT NULL,
    FOREIGN KEY(surah_id) REFERENCES surahs(id)
);
""")

# Indexes
cur.execute("CREATE INDEX IF NOT EXISTS idx_ayahs_lookup ON ayahs(surah_id, ayah_number);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_trans_lookup ON translations(surah_id, ayah_number, edition);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_words_lookup ON words_wbw(surah_id, ayah_number);")

# 7. FTS5 Search Index
cur.execute("""
CREATE VIRTUAL TABLE IF NOT EXISTS search_translations_fts USING fts5(
    surah_id UNINDEXED,
    ayah_number UNINDEXED,
    edition UNINDEXED,
    text_bn
);
""")

conn.commit()
print("Database schema created successfully at:", db_path)
conn.close()
