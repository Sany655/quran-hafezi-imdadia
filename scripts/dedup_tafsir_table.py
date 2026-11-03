import sqlite3

conn = sqlite3.connect('data/quran_imdadia.db')
cur = conn.cursor()

# Check count before
cur.execute("SELECT tafsir_name, COUNT(*), COUNT(DISTINCT surah_id || ':' || ayah_number) FROM tafsirs GROUP BY tafsir_name")
print("Before deduplication:")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} rows, {r[2]} distinct ayahs")

# Deduplicate by creating temp table or deleting duplicates
cur.execute("""
    DELETE FROM tafsirs 
    WHERE id NOT IN (
        SELECT MIN(id) 
        FROM tafsirs 
        GROUP BY surah_id, ayah_number, tafsir_id
    )
""")
conn.commit()

# Create UNIQUE index
cur.execute("DROP INDEX IF EXISTS idx_tafsirs_lookup;")
cur.execute("CREATE UNIQUE INDEX idx_tafsirs_unique ON tafsirs(surah_id, ayah_number, tafsir_id);")
conn.commit()

# Vacuum database
print("Vacuuming database...")
conn.execute("VACUUM;")
conn.commit()

cur.execute("SELECT tafsir_name, COUNT(*), COUNT(DISTINCT surah_id || ':' || ayah_number) FROM tafsirs GROUP BY tafsir_name")
print("\nAfter deduplication & unique index:")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} rows, {r[2]} distinct ayahs")

conn.close()
print("Deduplication complete!")
