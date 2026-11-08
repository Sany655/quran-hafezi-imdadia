"""
re_ocr_maariful_full.py
=======================
Executes end-to-end full re-OCR of Maariful Quran Short (all 1492 pages):
1. Re-OCR all 1492 pages with Tesseract PSM 3 (multi-column) and 200 DPI using multi-processing.
2. Ingests and cleans lines (zero Latin artifacts).
3. Assigns ayahs and updates SQLite database.
4. Regenerates web JSON pages.
5. Verifies database consistency and quality.
"""

import subprocess
import sys
import time
import os
import sqlite3

sys.stdout.reconfigure(encoding='utf-8')

def run_step(desc: str, cmd: list[str]):
    print(f"\n=======================================================")
    print(f"▶ Step: {desc}")
    print(f"  Command: {' '.join(cmd)}")
    print(f"=======================================================")
    t0 = time.time()
    res = subprocess.run(cmd, capture_output=False)
    if res.returncode != 0:
        print(f"❌ Error: {desc} failed with exit code {res.returncode}")
        sys.exit(res.returncode)
    t1 = time.time()
    print(f"✅ Completed: {desc} in {(t1 - t0) / 60:.1f} minutes")

def main():
    print("Starting Complete Re-OCR & Update for Maariful Quran Short...")
    t_start = time.time()

    # Step 1: Run Full OCR with PSM 3, 4 workers, and ben+ara
    run_step(
        "Re-OCR All 1492 Pages with PSM 3 and ben+ara",
        [sys.executable, "scripts/ocr_maariful_short.py", "--no-resume", "--workers", "4", "--dpi", "200", "--psm", "3", "--lang", "ben+ara"]
    )

    # Step 2: Assign Ayahs with rigorous Bengali cleaning
    run_step(
        "Assign Ayahs and Generate Commentary JSON",
        [sys.executable, "scripts/assign_ayahs_maariful.py"]
    )

    # Step 3: Ingest into SQLite DB
    run_step(
        "Import into SQLite Database (quran_imdadia.db)",
        [sys.executable, "scripts/import_maariful_to_db.py"]
    )

    # Step 4: Regenerate Web Data
    run_step(
        "Regenerate Web Data JSONs",
        [sys.executable, "scripts/generate_web_data.py"]
    )

    # Step 5: Verification
    print("\n=======================================================")
    print("▶ Verification of Ingested Commentary")
    print("=======================================================")
    conn = sqlite3.connect("data/quran_imdadia.db")
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*), COUNT(CASE WHEN text_bn IS NOT NULL AND length(trim(text_bn)) > 0 THEN 1 END) FROM tafsirs WHERE tafsir_name = 'maariful_quran_short'")
    total, non_empty = cur.fetchone()
    print(f"Total Maariful rows in DB: {total}, Non-empty rows: {non_empty}")

    # Check for any residual Latin characters outside HTML tags in Maariful Short
    cur.execute("SELECT surah_id, ayah_number, text_bn FROM tafsirs WHERE tafsir_name = 'maariful_quran_short'")
    dirty = []
    import re
    for s, a, text in cur.fetchall():
        clean = re.sub(r'<[^>]+>', '', text or '')
        latin = re.findall(r'[a-zA-Z]+', clean)
        if latin:
            dirty.append((s, a, latin))

    print(f"Rows containing Latin letters outside HTML tags in Maariful Short: {len(dirty)}")
    if dirty:
        print("Sample with Latin characters:")
        for r in dirty[:3]:
            print(f"  Surah {r[0]}:{r[1]} -> Latin words: {r[2]}")
    else:
        print("🎉 100% CLEAN: Zero Latin characters detected across all 6,236 Maariful Quran Short ayahs!")
    conn.close()

    total_time = (time.time() - t_start) / 60
    print(f"\n✨ All done in {total_time:.1f} minutes!")

if __name__ == '__main__':
    main()
