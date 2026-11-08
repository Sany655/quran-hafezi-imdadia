"""
import_usmani_to_db.py
=====================
Imports the extracted Tafsir Usmani JSON into SQLite DB (data/quran_imdadia.db).

tafsir_id   = 210
tafsir_name = 'tafsir_usmani'

Features:
  - Idempotent: deletes old 'tafsir_usmani' records before inserting
  - Fills all 6236 ayahs with placeholder rows if not yet extracted
  - Prints coverage stats and sample records
"""

import sqlite3
import json
import sys
import argparse
import os

sys.stdout.reconfigure(encoding='utf-8')

TAFSIR_JSON = r"data/tafsir/tafsir_usmani_tafsir.json"
DB_PATH     = r"data/quran_imdadia.db"
TAFSIR_ID   = 210
TAFSIR_NAME = 'tafsir_usmani'

def get_conn(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path, timeout=30)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute("PRAGMA synchronous=NORMAL;")
    return conn

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true',
                        help='Parse and validate without writing to DB')
    parser.add_argument('--fill-missing', action='store_true', default=True,
                        help='Insert empty rows for missing ayahs (default: True)')
    parser.add_argument('--no-fill-missing', action='store_false', dest='fill_missing')
    args = parser.parse_args()

    if not os.path.exists(TAFSIR_JSON):
        print(f"ERROR: {TAFSIR_JSON} not found. Run assign_ayahs_usmani.py first.")
        sys.exit(1)

    with open(TAFSIR_JSON, encoding='utf-8') as f:
        tafsir_data = json.load(f)

    print(f"Loaded {len(tafsir_data)} entries from {TAFSIR_JSON}")

    conn = get_conn(DB_PATH)
    cur = conn.cursor()

    all_ayahs = cur.execute(
        "SELECT surah_id, ayah_number FROM ayahs ORDER BY surah_id, ayah_number"
    ).fetchall()
    total_ayahs = len(all_ayahs)
    all_ayah_set = set(all_ayahs)
    print(f"DB has {total_ayahs} ayahs total.")

    valid_rows = []
    seen_keys = set()
    invalid_count = 0

    for entry in tafsir_data:
        sid = entry.get('surah_id')
        ayn = entry.get('ayah_number')
        vk  = entry.get('verse_key', f'{sid}:{ayn}')
        txt = entry.get('text_bn', '').strip()

        if not isinstance(sid, int) or not isinstance(ayn, int):
            invalid_count += 1
            continue
        if (sid, ayn) not in all_ayah_set:
            invalid_count += 1
            continue
        if (sid, ayn) in seen_keys:
            for r in valid_rows:
                if r[0] == sid and r[1] == ayn:
                    r[5] = r[5] + '\n\n' + txt
                    break
            continue

        seen_keys.add((sid, ayn))
        valid_rows.append([sid, ayn, vk, TAFSIR_ID, TAFSIR_NAME, txt])

    print(f"Valid extracted rows: {len(valid_rows)}, Invalid/skipped: {invalid_count}")

    if args.fill_missing:
        missing_ayahs = all_ayah_set - seen_keys
        for sid, ayn in sorted(missing_ayahs):
            vk = f'{sid}:{ayn}'
            valid_rows.append([sid, ayn, vk, TAFSIR_ID, TAFSIR_NAME, ''])
        print(f"Added {len(missing_ayahs)} placeholder rows for missing ayahs.")

    valid_rows.sort(key=lambda r: (r[0], r[1]))

    non_empty = sum(1 for r in valid_rows if r[5].strip())
    print(f"\n=== Coverage ===")
    print(f"  Total rows to insert: {len(valid_rows)}")
    print(f"  Non-empty tafsir text: {non_empty} ({100*non_empty/total_ayahs:.1f}%)")
    print(f"  Empty/placeholder: {len(valid_rows) - non_empty}")

    if args.dry_run:
        print("\n[DRY RUN] No DB writes performed.")
        return

    print(f"\nWriting {len(valid_rows)} rows to DB...")
    deleted = cur.execute(
        "DELETE FROM tafsirs WHERE tafsir_name = ?", (TAFSIR_NAME,)
    ).rowcount
    if deleted:
        print(f"  Removed {deleted} existing {TAFSIR_NAME} rows.")

    cur.executemany(
        "INSERT INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        [tuple(r) for r in valid_rows]
    )
    conn.commit()
    print(f"  Inserted {cur.rowcount} rows.")

    print("\n=== Verification ===")
    cur.execute("SELECT tafsir_name, COUNT(*), SUM(CASE WHEN text_bn != '' THEN 1 ELSE 0 END) "
                "FROM tafsirs WHERE tafsir_name = ? GROUP BY tafsir_name", (TAFSIR_NAME,))
    row = cur.fetchone()
    if row:
        print(f"  DB: {row[0]}: {row[1]} total rows, {row[2]} non-empty")

    sample = cur.execute(
        "SELECT verse_key, text_bn FROM tafsirs WHERE tafsir_name=? AND surah_id=1 AND ayah_number=1",
        (TAFSIR_NAME,)
    ).fetchone()
    if sample:
        print(f"\n  Sample 1:1:\n  {sample[1][:300]}...")

    cur.execute(
        "SELECT tafsir_name, COUNT(*) FROM tafsirs GROUP BY tafsir_name"
    )
    print("\n  All tafsirs in DB:")
    for r in cur.fetchall():
        print(f"    {r[0]}: {r[1]} rows")

    conn.close()
    print(f"\n✅ Import complete! tafsir_name='{TAFSIR_NAME}', tafsir_id={TAFSIR_ID}")

if __name__ == '__main__':
    main()
