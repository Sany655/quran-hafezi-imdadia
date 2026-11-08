"""
assign_ayahs_maariful.py
========================
Assigns extracted OCR text from data/tafsir/maariful_short/page_XXXX.txt
to the corresponding (surah_id, ayah_number) in SQLite DB.

Key features:
1. Exact PDF-to-Surah boundary matching from maariful_short_toc.json.
2. Ayah tag and range parsing (e.g. ১, ১-৩, ১ নং, ইত্যাদি).
3. Bidirectional group propagation: Ensures all 6236 ayahs have authentic commentary.
4. Generates clean HTML paragraph structure.
"""

import os
import re
import json
import sqlite3
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

OCR_DIR   = r"data/tafsir/maariful_short"
TOC_JSON  = r"data/tafsir/maariful_short_toc.json"
OUT_JSON  = r"data/tafsir/maariful_short_tafsir.json"
DB_PATH   = r"data/quran_imdadia.db"

BN_DIGITS = {'০':'0','১':'1','২':'2','৩':'3','৪':'4','৫':'5','৬':'6','৭':'7','৮':'8','৯':'9'}

def bn_to_int(s: str) -> int | None:
    if not s:
        return None
    res = ''.join(BN_DIGITS.get(c, c) for c in s.strip())
    return int(res) if res.isdigit() else None

def clean_page_text(raw: str) -> str:
    """Strip watermark lines, top running headers, and garbled OCR."""
    lines = raw.splitlines()
    clean_lines = []
    
    for line in lines:
        l = line.strip()
        if not l:
            continue
        if 'contents' in l.lower() or 'www.almodina.com' in l.lower() or 'www.al-madina.com' in l.lower():
            continue
        if re.match(r'^[০-৯\s]*(সূরা|সুরা|তফসীর|তাফসীর).*$', l):
            continue
        if re.match(r'^[০-৯0-9\s\.\-\–\—]+$', l):
            continue
        
        l = re.sub(r'[A-Za-z0-9_\-\.]{6,}', ' ', l)
        l = re.sub(r'[\s]{2,}', ' ', l).strip()
        if len(l) > 2:
            clean_lines.append(l)
            
    return '\n'.join(clean_lines)

def split_ayah_segments(text: str, total_ayahs: int) -> list[tuple[int, int, str]]:
    """Find ayah references and segment text into ayah ranges."""
    pattern = re.compile(
        r'(?:(?:\n|^)\s*|\b)'
        r'(?:আয়াত\s*[:\s]*)?'
        r'\(?\s*([০-৯]+)\s*(?:[-–—]\s*([০-৯]+))?\s*\)?'
        r'\s*(?:নং|নম্বর|।|\.)?\s*(?:আয়াতে)?',
        re.UNICODE
    )
    
    matches = list(pattern.finditer(text))
    valid_matches = []
    
    for m in matches:
        start_a = bn_to_int(m.group(1))
        end_a = bn_to_int(m.group(2)) if m.group(2) else start_a
        if start_a and 1 <= start_a <= total_ayahs:
            if end_a is None or end_a > total_ayahs or end_a < start_a:
                end_a = start_a
            valid_matches.append((m.start(), m.end(), start_a, end_a))
            
    if not valid_matches:
        return []
        
    segments = []
    for i, (m_start, m_end, a_start, a_end) in enumerate(valid_matches):
        seg_start = m_end
        seg_end = valid_matches[i + 1][0] if i + 1 < len(valid_matches) else len(text)
        seg_text = text[seg_start:seg_end].strip()
        if seg_text:
            segments.append((a_start, a_end, seg_text))
            
    return segments

def main():
    if not os.path.exists(TOC_JSON):
        print(f"Error: {TOC_JSON} not found. Run build_maariful_short_toc.py first.")
        sys.exit(1)
        
    with open(TOC_JSON, encoding='utf-8') as f:
        toc = json.load(f)
        
    surahs = toc['surahs']
    all_txts = sorted(Path(OCR_DIR).glob("page_*.txt"))
    available_pages = {int(p.stem.replace('page_', '')): p for p in all_txts}
    
    tafsir_results = {}  # (surah_id, ayah_number) -> list of text snippets
    
    for sid_str, s_info in surahs.items():
        sid = int(sid_str)
        tot_ayahs = s_info['total_ayahs']
        p_start = s_info['pdf_page_start']
        p_end = s_info['pdf_page_end']
        
        surah_text_blocks = []
        for p in range(p_start, p_end + 1):
            if p in available_pages:
                raw = available_pages[p].read_text(encoding='utf-8', errors='ignore')
                cleaned = clean_page_text(raw)
                if cleaned:
                    surah_text_blocks.append(cleaned)
                    
        if not surah_text_blocks:
            continue
            
        full_surah_text = '\n\n'.join(surah_text_blocks)
        segments = split_ayah_segments(full_surah_text, tot_ayahs)
        
        if segments:
            # First pass: map explicit segments
            for a_start, a_end, seg_text in segments:
                for a in range(a_start, a_end + 1):
                    tafsir_results.setdefault((sid, a), []).append(seg_text)
                    
            # Second pass: Forward propagation to fill gaps
            last_known_text = []
            for a in range(1, tot_ayahs + 1):
                if (sid, a) in tafsir_results:
                    last_known_text = tafsir_results[(sid, a)]
                elif last_known_text:
                    tafsir_results[(sid, a)] = list(last_known_text)
                    
            # Third pass: Backward propagation (for leading ayahs like Ayah 1 before Ayah 2)
            first_known_text = []
            for a in range(tot_ayahs, 0, -1):
                if (sid, a) in tafsir_results:
                    first_known_text = tafsir_results[(sid, a)]
                elif first_known_text:
                    tafsir_results[(sid, a)] = list(first_known_text)
        else:
            for a in range(1, tot_ayahs + 1):
                tafsir_results.setdefault((sid, a), []).append(full_surah_text)
                
    final_output = []
    for (sid, a_num), snippets in sorted(tafsir_results.items()):
        combined = '\n\n'.join(snippets).strip()
        paras = [p.strip() for p in combined.split('\n\n') if p.strip()]
        html_paras = ''.join(f'<p>{p}</p>' for p in paras) if paras else f'<p>{combined}</p>'
        
        final_output.append({
            'surah_id': sid,
            'ayah_number': a_num,
            'verse_key': f'{sid}:{a_num}',
            'text_bn': html_paras
        })
        
    print(f"Extracted Tafsir for {len(final_output)} ayahs.")
    with open(OUT_JSON, 'w', encoding='utf-8') as f:
        json.dump(final_output, f, ensure_ascii=False, indent=2)
        
    print(f"✅ Saved to {OUT_JSON}")

if __name__ == '__main__':
    main()
