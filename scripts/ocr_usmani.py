"""
ocr_usmani.py
=============
OCR engine for Tafsir Usmani 4 volumes.
Saves raw OCR text to data/tafsir/tafsir_usmani/vol{V}_page_{P:04d}.txt
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

OUT_DIR = r"data/tafsir/tafsir_usmani"

VOL_FILES = {
    1: r"reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_1_Surah_1-6.pdf",
    2: r"reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_2_Surah_7-18.pdf",
    3: r"reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_3_Surah_19-38.pdf",
    4: r"reference_books/tafsir_usmani_bangla/Tafsir_Usmani_Vol_4_Surah_39-114.pdf"
}

def ocr_single_page(args: tuple) -> tuple[int, int, str]:
    vol, pdf_path, out_dir, page_idx, dpi, skip_existing, lang, psm = args
    out_file = os.path.join(out_dir, f"vol{vol}_page_{page_idx:04d}.txt")
    
    if skip_existing and os.path.exists(out_file):
        with open(out_file, encoding='utf-8') as f:
            return vol, page_idx, f.read()
            
    doc = pymupdf.open(pdf_path)
    page = doc[page_idx]
    
    scale = dpi / 72.0
    mat = pymupdf.Matrix(scale, scale)
    pix = page.get_pixmap(matrix=mat, colorspace=pymupdf.csGRAY)
    img = Image.open(io.BytesIO(pix.tobytes("png")))
    doc.close()
    
    text = pytesseract.image_to_string(img, lang=lang, config=f'--psm {psm}')
    
    os.makedirs(out_dir, exist_ok=True)
    with open(out_file, 'w', encoding='utf-8') as f:
        f.write(text)
        
    return vol, page_idx, text

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--volume', type=int, default=1, choices=[1, 2, 3, 4],
                        help='Volume number to OCR (default: 1)')
    parser.add_argument('--workers', type=int, default=4,
                        help='Number of parallel worker processes (default: 4)')
    parser.add_argument('--resume', action='store_true', default=True,
                        help='Skip already-processed pages')
    parser.add_argument('--no-resume', action='store_false', dest='resume')
    parser.add_argument('--dpi', type=int, default=200,
                        help='Render DPI (default: 200)')
    parser.add_argument('--lang', type=str, default='ben+ara',
                        help='OCR language (default: ben+ara)')
    parser.add_argument('--psm', type=int, default=3,
                        help='Tesseract PSM (default: 3)')
    parser.add_argument('--start', type=int, default=0,
                        help='Starting PDF page index (0-based)')
    parser.add_argument('--end', type=int, default=None,
                        help='Ending PDF page index exclusive')
    args = parser.parse_args()

    pdf_path = VOL_FILES[args.volume]
    if not os.path.exists(pdf_path):
        print(f"Error: {pdf_path} not found.")
        sys.exit(1)

    os.makedirs(OUT_DIR, exist_ok=True)
    doc = pymupdf.open(pdf_path)
    total_pages = len(doc)
    doc.close()

    end_page = args.end if args.end is not None else total_pages
    page_range = range(args.start, min(end_page, total_pages))

    task_args = [
        (args.volume, pdf_path, OUT_DIR, pi, args.dpi, args.resume, args.lang, args.psm)
        for pi in page_range
    ]

    print(f"Tafsir Usmani OCR (Volume {args.volume})")
    print(f"  Pages: {args.start} to {end_page-1} ({len(task_args)} pages)")
    print(f"  Workers: {args.workers}, DPI: {args.dpi}, Resume: {args.resume}")

    start_time = time.time()
    completed = 0
    errors = 0

    if args.workers == 1:
        for ta in task_args:
            pi = ta[3]
            try:
                _, _, text = ocr_single_page(ta)
                completed += 1
                if completed % 10 == 0 or pi == page_range[-1]:
                    print(f"  [{completed}/{len(task_args)}] Vol {args.volume} page {pi+1}")
            except Exception as e:
                errors += 1
                print(f"  ERROR Vol {args.volume} page {pi+1}: {e}")
    else:
        with ProcessPoolExecutor(max_workers=args.workers) as executor:
            futures = {executor.submit(ocr_single_page, ta): ta[3] for ta in task_args}
            for future in as_completed(futures):
                pi = futures[future]
                try:
                    future.result()
                    completed += 1
                    if completed % 10 == 0 or completed == len(task_args):
                        print(f"  [{completed}/{len(task_args)}] Vol {args.volume} page {pi+1}")
                except Exception as e:
                    errors += 1
                    print(f"  ERROR Vol {args.volume} page {pi+1}: {e}")

    elapsed = time.time() - start_time
    print(f"\n✅ OCR finished: {completed} pages in {elapsed/60:.1f} min (errors: {errors})")

if __name__ == '__main__':
    main()
