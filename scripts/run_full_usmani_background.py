"""
run_full_usmani_background.py
=============================
Background automation pipeline for Tafsir Usmani (4 volumes, 3037 pages):
1. OCRs Volume 1 through Volume 4 with multi-processing and automatic resume.
2. Periodically synchronizes extracted text to SQLite DB.
3. Automatically updates coverage stats.
"""

import subprocess
import sqlite3
import time
import sys
import os
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

VOLUMES = [1, 2, 3, 4]
OCR_DIR = Path("data/tafsir/tafsir_usmani")
OCR_DIR.mkdir(parents=True, exist_ok=True)

def get_completed_count():
    return len(list(OCR_DIR.glob("vol*_page_*.txt")))

def sync_db():
    print(f"\n[Sync] Running assign_ayahs_usmani.py & import_usmani_to_db.py...")
    subprocess.run([sys.executable, "scripts/assign_ayahs_usmani.py"], check=False)
    subprocess.run([sys.executable, "scripts/import_usmani_to_db.py"], check=False)
    
    con = sqlite3.connect("data/quran_imdadia.db")
    cur = con.cursor()
    row = cur.execute(
        "SELECT COUNT(*), SUM(CASE WHEN text_bn != '' THEN 1 ELSE 0 END) "
        "FROM tafsirs WHERE tafsir_name = 'tafsir_usmani'"
    ).fetchone()
    con.close()
    if row:
        print(f"[Sync Complete] Populated ayahs in DB: {row[1]}/{row[0]}")

def main():
    start_time = time.time()
    initial_done = get_completed_count()
    print(f"=== Starting Background Run: Tafsir Usmani (4 Volumes) ===")
    print(f"Already completed OCR files: {initial_done}")
    print("=" * 60)
    
    for vol in VOLUMES:
        print(f"\n>>> Processing Volume {vol}...")
        cmd = [
            sys.executable, "scripts/ocr_usmani.py",
            "--volume", str(vol),
            "--workers", "2",
            "--dpi", "150",
            "--resume"
        ]
        res = subprocess.run(cmd)
        sync_db()
        
    print("\nAll volumes finished! Running final database sync...")
    sync_db()
    total_elapsed = time.time() - start_time
    print(f"\n🎉 FULL USMANI RUN COMPLETED in {total_elapsed/60:.1f} minutes!")

if __name__ == '__main__':
    main()
