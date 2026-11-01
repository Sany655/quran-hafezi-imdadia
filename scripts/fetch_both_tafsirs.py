import sqlite3
import urllib.request
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"

def get_conn():
    conn = sqlite3.connect(db_path, timeout=30)
    conn.execute("PRAGMA journal_mode=WAL;")
    return conn

# Clean up any partial test data for clean slate
conn = get_conn()
cur = conn.cursor()
cur.execute("DELETE FROM tafsirs;")
conn.commit()
conn.close()

tafsirs_to_fetch = [
    (165, "ahsanul_bayan", "আহসানুল বায়ান"),
    (164, "ibn_kathir", "ইবনে কাসীর")
]

def fetch_chapter_tafsir(tafsir_id, tafsir_name, chapter_id):
    conn = get_conn()
    cur = conn.cursor()
    
    page = 1
    total_saved = 0
    
    while True:
        url = f"https://api.quran.com/api/v4/tafsirs/{tafsir_id}/by_chapter/{chapter_id}?per_page=50&page={page}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        
        data = None
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=20) as resp:
                    data = json.loads(resp.read().decode('utf-8'))
                    break
            except Exception as e:
                time.sleep(1.2 * (attempt + 1))
                
        if not data:
            break
            
        items = data.get('tafsirs', [])
        if not items:
            break
            
        for t in items:
            vk = t.get('verse_key', '')
            text = t.get('text', '')
            if vk and ':' in vk and text:
                sid, aid = map(int, vk.split(':'))
                cur.execute("""
                    INSERT INTO tafsirs (surah_id, ayah_number, verse_key, tafsir_id, tafsir_name, text_bn)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (sid, aid, vk, tafsir_id, tafsir_name, text))
                total_saved += 1
                
        pagination = data.get('pagination', {})
        if page >= pagination.get('total_pages', 1):
            break
        page += 1
        time.sleep(0.15)
        
    conn.commit()
    conn.close()
    return total_saved

print("Starting bulk Tafsir collection (Ahsanul Bayaan & Ibn Kathir)...")

for tid, tname, bn_label in tafsirs_to_fetch:
    print(f"\n==========================================")
    print(f"Fetching {bn_label} ({tname} - ID {tid})")
    print(f"==========================================")
    
    for ch in range(1, 115):
        saved = fetch_chapter_tafsir(tid, tname, ch)
        if ch % 10 == 0 or ch == 114:
            print(f"  Surahs 1 to {ch:03d} complete... (Latest: {saved} verses)")
        time.sleep(0.1)

print("\nAll Tafsir collections completed successfully!")

# Summary
conn = get_conn()
cur = conn.cursor()
cur.execute("SELECT tafsir_name, COUNT(*) FROM tafsirs GROUP BY tafsir_name")
print("\nFinal Tafsir Records Summary:")
for r in cur.fetchall():
    print(f" - {r[0]}: {r[1]} ayahs")
conn.close()
