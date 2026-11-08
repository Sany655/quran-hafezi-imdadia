"""
Step 2: ocr_maariful_short.py
==============================
Runs Tesseract OCR on every page of Maariful_Quran_Short_Complete.pdf
and saves raw text to data/tafsir/maariful_short/page_XXXX.txt

Features:
  - Resume mode: skips pages already OCR'd
  - Parallel worker support (--workers N)
  - Progress reporting every 50 pages

Usage:
    python scripts/ocr_maariful_short.py [--workers 4] [--resume] [--dpi 300]
    python scripts/ocr_maariful_short.py --start 100 --end 200   # partial range
"""

import pymupdf
import pytesseract
from PIL import Image
import io
import os
import sys
import argparse
import time
from concurrent.futures import ProcessPoolExecutor, as_completed

sys.stdout.reconfigure(encoding='utf-8')

PDF_PATH = r"reference_books/maariful_quran_bangla/Maariful_Quran_Short_Complete.pdf"
OUT_DIR  = r"data/tafsir/maariful_short"


def ocr_single_page(args: tuple) -> tuple[int, str]:
    """
    OCR one page. Returns (page_index, ocr_text).
    Designed to run in a subprocess (ProcessPoolExecutor).
    """
    pdf_path, out_dir, page_idx, dpi, skip_existing = args
    
    out_file = os.path.join(out_dir, f"page_{page_idx:04d}.txt")
    
    if skip_existing and os.path.exists(out_file):
        with open(out_file, encoding='utf-8') as f:
            return page_idx, f.read()
    
    doc = pymupdf.open(pdf_path)
    page = doc[page_idx]
    
    scale = dpi / 72.0
    mat = pymupdf.Matrix(scale, scale)
    pix = page.get_pixmap(matrix=mat, colorspace=pymupdf.csGRAY)
    img = Image.open(io.BytesIO(pix.tobytes("png")))
    doc.close()
    
    text = pytesseract.image_to_string(img, lang='ben+eng', config='--psm 6')
    
    os.makedirs(out_dir, exist_ok=True)
    with open(out_file, 'w', encoding='utf-8') as f:
        f.write(text)
    
    return page_idx, text


def main():
    parser = argparse.ArgumentParser(description='OCR Maariful Quran Short Complete PDF')
    parser.add_argument('--workers', type=int, default=1,
                        help='Number of parallel worker processes (default: 1)')
    parser.add_argument('--resume', action='store_true', default=True,
                        help='Skip already-processed pages (default: True)')
    parser.add_argument('--no-resume', action='store_false', dest='resume',
                        help='Re-OCR all pages even if already done')
    parser.add_argument('--dpi', type=int, default=300,
                        help='Render DPI (default: 300, higher = better quality but slower)')
    parser.add_argument('--start', type=int, default=0,
                        help='Starting PDF page index (0-based, default: 0)')
    parser.add_argument('--end', type=int, default=None,
                        help='Ending PDF page index exclusive (default: all pages)')
    args = parser.parse_args()

    os.makedirs(OUT_DIR, exist_ok=True)

    doc = pymupdf.open(PDF_PATH)
    total_pages = len(doc)
    doc.close()

    end_page = args.end if args.end is not None else total_pages
    page_range = range(args.start, min(end_page, total_pages))

    # Count already-done
    already_done = sum(
        1 for pi in page_range
        if os.path.exists(os.path.join(OUT_DIR, f"page_{pi:04d}.txt"))
    ) if args.resume else 0

    print(f"Maariful Quran Short Complete OCR Pipeline")
    print(f"  PDF: {PDF_PATH}")
    print(f"  Pages: {args.start}–{end_page-1} ({len(page_range)} pages)")
    print(f"  Already done: {already_done} pages")
    print(f"  Remaining: {len(page_range) - already_done} pages")
    print(f"  Workers: {args.workers}, DPI: {args.dpi}, Resume: {args.resume}")
    print()

    task_args = [
        (PDF_PATH, OUT_DIR, pi, args.dpi, args.resume)
        for pi in page_range
    ]

    start_time = time.time()
    completed = 0
    errors = 0

    if args.workers == 1:
        # Single-threaded — simpler, safer
        for ta in task_args:
            pi = ta[2]
            try:
                _, text = ocr_single_page(ta)
                completed += 1
                if completed % 50 == 0 or pi == page_range[-1]:
                    elapsed = time.time() - start_time
                    rate = completed / elapsed if elapsed > 0 else 0
                    eta = (len(task_args) - completed) / rate if rate > 0 else 0
                    print(f"  [{completed:4d}/{len(task_args)}] page {pi+1:4d}  "
                          f"({rate:.1f} p/s, ETA {eta/60:.1f} min)")
            except Exception as e:
                errors += 1
                print(f"  ERROR page {pi+1}: {e}")
    else:
        # Multi-process
        with ProcessPoolExecutor(max_workers=args.workers) as executor:
            futures = {executor.submit(ocr_single_page, ta): ta[2] for ta in task_args}
            for future in as_completed(futures):
                pi = futures[future]
                try:
                    _, _ = future.result()
                    completed += 1
                    if completed % 50 == 0:
                        elapsed = time.time() - start_time
                        rate = completed / elapsed if elapsed > 0 else 0
                        eta = (len(task_args) - completed) / rate if rate > 0 else 0
                        print(f"  [{completed:4d}/{len(task_args)}]  "
                              f"({rate:.1f} p/s, ETA {eta/60:.1f} min)")
                except Exception as e:
                    errors += 1
                    print(f"  ERROR page {pi+1}: {e}")

    elapsed = time.time() - start_time
    print(f"\n✅ OCR complete!")
    print(f"   Processed: {completed} pages in {elapsed/60:.1f} min")
    print(f"   Errors: {errors}")
    print(f"   Output: {OUT_DIR}/page_XXXX.txt")


if __name__ == '__main__':
    main()
