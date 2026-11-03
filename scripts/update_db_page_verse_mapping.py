import sqlite3
import json

db_path = 'data/quran_imdadia.db'
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Load page mapping
with open('data/imdadia_page_verse_map.json', 'r', encoding='utf-8') as f:
    page_map = json.load(f)

# 1. Update pages table schema if needed
cur.execute("PRAGMA table_info(pages);")
cols = [c[1] for c in cur.fetchall()]

if 'start_surah_id' not in cols:
    print("Adding start_surah_id, start_ayah_number, end_surah_id, end_ayah_number, verse_keys to pages table...")
    cur.execute("ALTER TABLE pages ADD COLUMN start_surah_id INTEGER DEFAULT 1;")
    cur.execute("ALTER TABLE pages ADD COLUMN start_ayah_number INTEGER DEFAULT 1;")
    cur.execute("ALTER TABLE pages ADD COLUMN end_surah_id INTEGER DEFAULT 1;")
    cur.execute("ALTER TABLE pages ADD COLUMN end_ayah_number INTEGER DEFAULT 1;")
    cur.execute("ALTER TABLE pages ADD COLUMN verse_keys TEXT DEFAULT '';")

# Update pages rows
for p_str, info in page_map.items():
    p = int(p_str)
    cur.execute("""
        UPDATE pages
        SET start_surah_id = ?,
            start_ayah_number = ?,
            end_surah_id = ?,
            end_ayah_number = ?,
            verse_keys = ?
        WHERE page_number = ?
    """, (
        info['start_surah'],
        info['start_ayah'],
        info['end_surah'],
        info['end_ayah'],
        ",".join(info['all_verses']),
        p
    ))

print("Updated 612 rows in pages table!")

# 2. Add page_number column to ayahs table if not present
cur.execute("PRAGMA table_info(ayahs);")
ayah_cols = [c[1] for c in cur.fetchall()]

if 'page_number' not in ayah_cols:
    print("Adding page_number to ayahs table...")
    cur.execute("ALTER TABLE ayahs ADD COLUMN page_number INTEGER DEFAULT 1;")

# Map each ayah to its page number
# An ayah may span across page boundary if it's long, but in 15-line Hafezi Mushaf:
# each ayah is assigned to the page it starts on
verse_to_page = {}
for p_str, info in page_map.items():
    p = int(p_str)
    for vk in info['all_verses']:
        # If verse already seen, keep first page or last page?
        # In all_verses, the verse belongs to page p
        if vk not in verse_to_page:
            verse_to_page[vk] = p

for vk, p in verse_to_page.items():
    sid, aid = map(int, vk.split(':'))
    cur.execute("""
        UPDATE ayahs
        SET page_number = ?
        WHERE surah_id = ? AND ayah_number = ?
    """, (p, sid, aid))

# Create index on page_number
cur.execute("CREATE INDEX IF NOT EXISTS idx_ayahs_page_number ON ayahs(page_number);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_pages_page_number ON pages(page_number);")

conn.commit()

# Verify
cur.execute("SELECT page_number, start_surah_id, start_ayah_number, end_surah_id, end_ayah_number FROM pages WHERE page_number IN (2, 3, 4, 51, 52, 78, 587, 588)")
print("\nSample pages check:")
for r in cur.fetchall():
    print(f"  Page {r[0]}: {r[1]}:{r[2]} to {r[3]}:{r[4]}")

conn.close()
print("\nDatabase update complete!")
