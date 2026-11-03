import sqlite3
import urllib.request
import json
import time
import re
import sys
from concurrent.futures import ThreadPoolExecutor

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"data/quran_imdadia.db"

def get_conn():
    conn = sqlite3.connect(db_path, timeout=30)
    conn.execute("PRAGMA journal_mode=WAL;")
    return conn

print("=== STEP 1: FIX AHSANUL BAYAAN (ID 165) MISSING ENTRIES ===")
conn = get_conn()
cur = conn.cursor()

ahsanul_missing = [(6, 64), (18, 17), (27, 77)]
for sid, aid in ahsanul_missing:
    vk = f"{sid}:{aid}"
    url = f"https://api.quran.com/api/v4/tafsirs/165/by_ayah/{vk}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            text = data.get('tafsir', {}).get('text', '')
            if text:
                cur.execute("""
                    INSERT OR REPLACE INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (sid, aid, vk, 165, "ahsanul_bayan", text))
                print(f"  Fixed Ahsanul Bayaan for {vk} (length: {len(text)})")
    except Exception as e:
        print(f"  Error fixing {vk}: {e}")

conn.commit()
conn.close()

print("\n=== STEP 2: FIX IBN KATHIR (ID 164) GROUPED & MISSING ENTRIES ===")
conn = get_conn()
cur = conn.cursor()

# Get all 6236 ayahs
cur.execute("SELECT surah_id, ayah_number FROM ayahs ORDER BY surah_id, ayah_number")
all_ayahs = cur.fetchall()

# Get existing Ibn Kathir entries
cur.execute("SELECT surah_id, ayah_number, text_bn FROM tafsirs WHERE tafsir_id = 164")
existing_ik = { (r[0], r[1]): r[2] for r in cur.fetchall() }
print(f"Existing Ibn Kathir entries: {len(existing_ik)}/6236")

bn_digits = {'০':'0', '১':'1', '২':'2', '৩':'3', '৪':'4', '৫':'5', '৬':'6', '৭':'7', '৮':'8', '৯':'9'}
def bn_to_int(s):
    return int(''.join(bn_digits.get(ch, ch) for ch in s))

# Propagate grouped verses using Bengali range header (e.g. ৬-৭ নং, ৮-৯ নং, ১১-১২ নং)
propagated_count = 0
for (sid, aid), text in list(existing_ik.items()):
    # Check for verse range header in first 250 characters
    m = re.search(r'([০-৯]+)\s*[-–—]\s*([০-৯]+)\s*নং', text[:250])
    if m:
        start_a = bn_to_int(m.group(1))
        end_a = bn_to_int(m.group(2))
        if start_a <= aid <= end_a:
            for extra in range(start_a, end_a + 1):
                if (sid, extra) not in existing_ik:
                    vk = f"{sid}:{extra}"
                    cur.execute("""
                        INSERT OR REPLACE INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (sid, extra, vk, 164, "ibn_kathir", text))
                    existing_ik[(sid, extra)] = text
                    propagated_count += 1

conn.commit()
print(f"Propagated from Bengali range headers: {propagated_count} verses. Total now: {len(existing_ik)}")

# Now check remaining missing ayahs
missing_ik = [a for a in all_ayahs if a not in existing_ik]
print(f"Remaining Ibn Kathir verses to fetch via by_ayah: {len(missing_ik)}")

def fetch_ik_by_ayah(item):
    sid, aid = item
    vk = f"{sid}:{aid}"
    url = f"https://api.quran.com/api/v4/tafsirs/164/by_ayah/{vk}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                t = data.get('tafsir', {})
                text = t.get('text', '')
                verses_dict = t.get('verses', {})
                return vk, text, verses_dict
        except Exception:
            time.sleep(1.0 * (attempt + 1))
    return vk, '', {}

# Fetch remaining via ThreadPoolExecutor
fetched_new = 0
if missing_ik:
    print("Fetching remaining missing Ibn Kathir verses from api.quran.com...")
    # Group missing into unique queries (as by_ayah returns all verses in the cluster)
    visited = set()
    to_query = []
    for sid, aid in missing_ik:
        if (sid, aid) not in visited:
            to_query.append((sid, aid))
            visited.add((sid, aid))

    with ThreadPoolExecutor(max_workers=10) as executor:
        for vk, text, verses_dict in executor.map(fetch_ik_by_ayah, to_query):
            if text:
                # Insert for all verses returned in verses_dict
                if verses_dict:
                    for related_vk in verses_dict.keys():
                        if ':' in related_vk:
                            rs, ra = map(int, related_vk.split(':'))
                            cur.execute("""
                                INSERT OR REPLACE INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn)
                                VALUES (?, ?, ?, ?, ?, ?)
                            """, (rs, ra, related_vk, 164, "ibn_kathir", text))
                            fetched_new += 1
                else:
                    s, a = map(int, vk.split(':'))
                    cur.execute("""
                        INSERT OR REPLACE INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (s, a, vk, 164, "ibn_kathir", text))
                    fetched_new += 1

conn.commit()

# Final check
cur.execute("SELECT tafsir_name, COUNT(*) FROM tafsirs GROUP BY tafsir_name")
print("\n=== FINAL TAFSIR TABLE STATS ===")
for r in cur.fetchall():
    print(f" - {r[0]}: {r[1]} ayahs (out of 6236)")

conn.close()
print("\nTafsir fix complete!")
