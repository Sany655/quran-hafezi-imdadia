"""
run_full_maariful_background.py
===============================
Runs the complete background conversion of Maariful Quran Short Complete:
1. Multi-process OCR across all 1492 pages (with automatic resume).
2. Performs incremental DB sync every 50 pages so the database is updated continuously.
3. Performs final assignment & DB ingestion upon completion.
"""

import subprocess
import sqlite3
import json
import time
import sys
import os
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

TOTAL_PAGES = 1492
OCR_DIR = Path("data/tafsir/maariful_short")
OCR_DIR.mkdir(parents=True, exist_ok=True)

def get_completed_count():
    return len(list(OCR_DIR.glob("page_*.txt")))

def sync_db():
    print(f"\n[Sync] Running assign_ayahs_maariful.py & import_maariful_to_db.py...")
    subprocess.run([sys.executable, "scripts/assign_ayahs_maariful.py"], check=False)
    subprocess.run([sys.executable, "scripts/import_maariful_to_db.py"], check=False)
    
    con = sqlite3.connect("data/quran_imdadia.db")
    cur = con.cursor()
    row = cur.execute(
        "SELECT COUNT(*), SUM(CASE WHEN text_bn != '' THEN 1 ELSE 0 END) "
        "FROM tafsirs WHERE tafsir_name = 'maariful_quran_short'"
    ).fetchone()
    con.close()
    if row:
        print(f"[Sync Complete] Populated ayahs in DB: {row[1]}/{row[0]}")

def main():
    start_time = time.time()
    initial_done = get_completed_count()
    print(f"=== Starting Full Background Run: Maariful Quran Short ===")
    print(f"Total pages: {TOTAL_PAGES}")
    print(f"Already completed: {initial_done}")
    print(f"Remaining: {TOTAL_PAGES - initial_done}")
    print(f"Workers: 3, DPI: 200")
    print("=" * 60)
    
    # Run OCR with 3 workers
    ocr_cmd = [
        sys.executable, "scripts/ocr_maariful_short.py",
        "--workers", "3",
        "--dpi", "200"
    ]
    
    proc = subprocess.Popen(ocr_cmd)
    
    last_sync_count = initial_done
    
    while proc.poll() is None:
        time.sleep(30)
        current_done = get_completed_count()
        elapsed = time.time() - start_time
        rate = (current_done - initial_done) / elapsed if elapsed > 0 else 0
        rem_pages = TOTAL_PAGES - current_done
        eta_min = (rem_pages / rate / 60) if rate > 0 else 0
        
        print(f"[Progress] {current_done}/{TOTAL_PAGES} pages done "
              f"({current_done/TOTAL_PAGES*100:.1f}%) | "
              f"Speed: {rate*60:.1f} p/min | ETA: {eta_min:.1f} min")
        
        # Periodic DB sync every 50 new pages
        if current_done - last_sync_count >= 50:
            sync_db()
            last_sync_count = current_done
            
    print("\nOCR process finished. Running final database sync...")
    sync_db()
    
    total_elapsed = time.time() - start_time
    print(f"\n🎉 FULL RUN COMPLETED in {total_elapsed/60:.1f} minutes!")

if __name__ == '__main__':
    main()
