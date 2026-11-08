"""
Step 4: import_maariful_to_db.py
==================================
Imports the extracted Maariful Quran Short tafsir JSON into the SQLite DB.

tafsir_id  = 200   (Maariful Quran Short, Bengali)
tafsir_name = 'maariful_quran_short'

Features:
  - Clears existing maariful_quran_short rows before inserting (idempotent)
  - Fills missing ayahs with empty string (so all 6236 have a row)
  - Prints coverage stats
  - Verifies sample verses

Usage:
    python scripts/import_maariful_to_db.py [--dry-run] [--fill-missing]
"""

import sqlite3
import json
import sys
import argparse
import os

sys.stdout.reconfigure(encoding='utf-8')

TAFSIR_JSON  = r"data/tafsir/maariful_short_tafsir.json"
DB_PATH      = r"data/quran_imdadia.db"
TAFSIR_ID    = 200
TAFSIR_NAME  = 'maariful_quran_short'


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
                        help='Insert empty rows for ayahs with no tafsir text (default: True)')
    parser.add_argument('--no-fill-missing', action='store_false', dest='fill_missing')
    args = parser.parse_args()

    # ── Load JSON ──────────────────────────────────────────────────────────────
    if not os.path.exists(TAFSIR_JSON):
        print(f"ERROR: {TAFSIR_JSON} not found. Run assign_ayahs_maariful.py first.")
        sys.exit(1)

    with open(TAFSIR_JSON, encoding='utf-8') as f:
        tafsir_data = json.load(f)

    print(f"Loaded {len(tafsir_data)} entries from {TAFSIR_JSON}")

    # ── Load all ayahs from DB ─────────────────────────────────────────────────
    conn = get_conn(DB_PATH)
    cur = conn.cursor()

    all_ayahs = cur.execute(
        "SELECT surah_id, ayah_number FROM ayahs ORDER BY surah_id, ayah_number"
    ).fetchall()
    total_ayahs = len(all_ayahs)
    all_ayah_set = set(all_ayahs)
    print(f"DB has {total_ayahs} ayahs total.")

    # ── Validate JSON data ─────────────────────────────────────────────────────
    valid_rows = []
    invalid_count = 0
    seen_keys = set()

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
            # Duplicate: append text
            for r in valid_rows:
                if r[0] == sid and r[1] == ayn:
                    r[5] = r[5] + '\n\n' + txt
                    break
            continue

        seen_keys.add((sid, ayn))
        valid_rows.append([sid, ayn, vk, TAFSIR_ID, TAFSIR_NAME, txt])

    print(f"Valid rows: {len(valid_rows)}, Invalid/skipped: {invalid_count}")

    # ── Fill missing ayahs ─────────────────────────────────────────────────────
    if args.fill_missing:
        missing_ayahs = all_ayah_set - seen_keys
        for sid, ayn in sorted(missing_ayahs):
            vk = f'{sid}:{ayn}'
            valid_rows.append([sid, ayn, vk, TAFSIR_ID, TAFSIR_NAME, ''])
        print(f"Added {len(missing_ayahs)} placeholder rows for missing ayahs.")

    # Sort by surah_id, ayah_number
    valid_rows.sort(key=lambda r: (r[0], r[1]))

    # ── Coverage stats ─────────────────────────────────────────────────────────
    non_empty = sum(1 for r in valid_rows if r[5].strip())
    print(f"\n=== Coverage ===")
    print(f"  Total rows to insert: {len(valid_rows)}")
    print(f"  Non-empty tafsir text: {non_empty} ({100*non_empty/total_ayahs:.1f}%)")
    print(f"  Empty/placeholder: {len(valid_rows) - non_empty}")

    # Print per-surah coverage
    surah_coverage: dict[int, dict] = {}
    for r in valid_rows:
        sid = r[0]
        if sid not in surah_coverage:
            surah_coverage[sid] = {'total': 0, 'non_empty': 0}
        surah_coverage[sid]['total'] += 1
        if r[5].strip():
            surah_coverage[sid]['non_empty'] += 1

    low_coverage = [(sid, v) for sid, v in surah_coverage.items()
                    if v['non_empty'] < v['total'] * 0.5]
    if low_coverage:
        print(f"\n  ⚠️  Surahs with <50% coverage ({len(low_coverage)}):")
        for sid, v in sorted(low_coverage)[:20]:
            print(f"    Surah {sid}: {v['non_empty']}/{v['total']} ayahs")

    if args.dry_run:
        print("\n[DRY RUN] No DB writes performed.")
        # Show sample rows
        print("\n=== Sample rows (first 5 non-empty) ===")
        shown = 0
        for r in valid_rows:
            if r[5].strip():
                print(f"  {r[2]}: {r[5][:200]}...")
                shown += 1
                if shown >= 5:
                    break
        return

    # ── Write to DB ────────────────────────────────────────────────────────────
    print(f"\nWriting {len(valid_rows)} rows to DB...")

    # Remove existing maariful_quran_short entries
    deleted = cur.execute(
        "DELETE FROM tafsirs WHERE tafsir_name = ?", (TAFSIR_NAME,)
    ).rowcount
    if deleted:
        print(f"  Removed {deleted} existing {TAFSIR_NAME} rows.")

    # Bulk insert
    cur.executemany(
        "INSERT INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        [tuple(r) for r in valid_rows]
    )
    conn.commit()
    print(f"  Inserted {cur.rowcount} rows.")

    # ── Verification ───────────────────────────────────────────────────────────
    print("\n=== Verification ===")
    cur.execute("SELECT tafsir_name, COUNT(*), SUM(CASE WHEN text_bn != '' THEN 1 ELSE 0 END) "
                "FROM tafsirs WHERE tafsir_name = ? GROUP BY tafsir_name", (TAFSIR_NAME,))
    row = cur.fetchone()
    if row:
        print(f"  DB: {row[0]}: {row[1]} total rows, {row[2]} non-empty")

    # Sample lookup for Surah Al-Fatiha
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
