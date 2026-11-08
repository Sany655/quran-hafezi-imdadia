"""
run_maariful_pipeline.py
=========================
Master pipeline runner for Maariful Quran Short → DB conversion.

Runs all 4 steps in sequence with optional step selection.

Usage:
    # Full pipeline (all steps):
    python scripts/run_maariful_pipeline.py

    # Resume OCR from where it stopped, then continue:
    python scripts/run_maariful_pipeline.py --steps ocr assign import

    # Just rebuild the DB from existing OCR + JSON:
    python scripts/run_maariful_pipeline.py --steps assign import

    # OCR with 4 workers:
    python scripts/run_maariful_pipeline.py --steps ocr --workers 4

    # Dry-run import (validate without writing):
    python scripts/run_maariful_pipeline.py --steps import --dry-run

Steps:
    toc     - Build TOC map (page → surah mapping)
    ocr     - OCR all 1492 PDF pages
    assign  - Assign OCR text to ayah keys
    import  - Import JSON to SQLite DB
"""

import subprocess
import sys
import argparse
import time
import os

sys.stdout.reconfigure(encoding='utf-8')

STEPS_ORDER = ['toc', 'ocr', 'assign', 'import']

STEP_SCRIPTS = {
    'toc':    'scripts/build_maariful_short_toc.py',
    'ocr':    'scripts/ocr_maariful_short.py',
    'assign': 'scripts/assign_ayahs_maariful.py',
    'import': 'scripts/import_maariful_to_db.py',
}

STEP_DESCRIPTIONS = {
    'toc':    'Build TOC map (page → surah mapping)',
    'ocr':    'OCR all PDF pages → data/tafsir/maariful_short/page_XXXX.txt',
    'assign': 'Assign OCR text to ayah keys → maariful_short_tafsir.json',
    'import': 'Import JSON → SQLite tafsirs table',
}


def run_step(name: str, script: str, extra_args: list[str]) -> bool:
    """Run a pipeline step subprocess. Returns True on success."""
    cmd = [sys.executable, script] + extra_args
    print(f"\n{'='*60}")
    print(f"STEP: {name.upper()} — {STEP_DESCRIPTIONS[name]}")
    print(f"CMD:  {' '.join(cmd)}")
    print(f"{'='*60}")
    
    start = time.time()
    result = subprocess.run(cmd, cwd=os.getcwd())
    elapsed = time.time() - start
    
    if result.returncode == 0:
        print(f"\n✅ Step '{name}' completed in {elapsed/60:.1f} min.")
        return True
    else:
        print(f"\n❌ Step '{name}' FAILED (exit code {result.returncode}) after {elapsed/60:.1f} min.")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Run Maariful Quran Short → DB pipeline'
    )
    parser.add_argument(
        '--steps', nargs='+',
        choices=STEPS_ORDER,
        default=STEPS_ORDER,
        help='Which steps to run (default: all)'
    )
    parser.add_argument('--workers', type=int, default=1,
                        help='OCR parallel workers (default: 1)')
    parser.add_argument('--dpi', type=int, default=300,
                        help='OCR DPI quality (default: 300)')
    parser.add_argument('--no-resume', action='store_true',
                        help='Re-OCR all pages even if already done')
    parser.add_argument('--dry-run', action='store_true',
                        help='Validate import without writing to DB')
    parser.add_argument('--stop-on-error', action='store_true',
                        help='Stop pipeline on first error (default: continue)')
    args = parser.parse_args()

    # Determine steps to run (preserve STEPS_ORDER order)
    steps_to_run = [s for s in STEPS_ORDER if s in args.steps]

    print(f"Maariful Quran Short → DB Pipeline")
    print(f"Steps: {' → '.join(steps_to_run)}")
    print(f"Workers: {args.workers}, DPI: {args.dpi}")
    print()

    overall_start = time.time()
    results = {}

    for step in steps_to_run:
        script = STEP_SCRIPTS[step]
        extra = []

        if step == 'ocr':
            extra += ['--dpi', str(args.dpi)]
            extra += ['--workers', str(args.workers)]
            if args.no_resume:
                extra += ['--no-resume']
        elif step == 'import' and args.dry_run:
            extra += ['--dry-run']

        success = run_step(step, script, extra)
        results[step] = success

        if not success and args.stop_on_error:
            print(f"\nPipeline stopped due to error in step '{step}'.")
            break

    # Summary
    total_elapsed = time.time() - overall_start
    print(f"\n{'='*60}")
    print(f"PIPELINE SUMMARY  ({total_elapsed/60:.1f} min total)")
    print(f"{'='*60}")
    for step in steps_to_run:
        status = "✅ OK" if results.get(step) else "❌ FAILED"
        print(f"  {step:8s}  {status}  —  {STEP_DESCRIPTIONS[step]}")

    all_ok = all(results.get(s, False) for s in steps_to_run)
    if all_ok:
        print(f"\n🎉 All steps completed successfully!")
        print(f"   Maariful Quran Short tafsir is now in the DB.")
        print(f"   tafsir_name='maariful_quran_short', tafsir_id=200")
    else:
        print(f"\n⚠️  Some steps failed. Check logs above.")
        sys.exit(1)


if __name__ == '__main__':
    main()
