import sqlite3
import urllib.request
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"

def fetch_and_save_tafsir(tafsir_id, tafsir_name, chapter_id):
    conn = sqlite3.connect(db_path, timeout=30)
    cur = conn.cursor()
    
    page = 1
    total_saved = 0
    while True:
        url = f"https://api.quran.com/api/v4/tafsirs/{tafsir_id}/by_chapter/{chapter_id}?per_page=50&page={page}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        
        data = None
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=15) as resp:
                    data = json.loads(resp.read().decode('utf-8'))
                    break
            except Exception as e:
                time.sleep(1.0 * (attempt + 1))
                
        if not data:
            break
            
        tafsirs = data.get('tafsirs', [])
        if not tafsirs:
            break
            
        for t in tafsirs:
            vk = t.get('verse_key', '')
            text = t.get('text', '')
            if vk and ':' in vk:
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

print("Testing Tafsir Ahsanul Bayaan on Surah 1:")
saved_1 = fetch_and_save_tafsir(165, "ahsanul_bayan", 1)
print(f"Saved {saved_1} ayahs for Surah 1")

print("Testing Tafsir Ibn Kathir on Surah 1:")
saved_2 = fetch_and_save_tafsir(164, "ibn_kathir", 1)
print(f"Saved {saved_2} ayahs for Surah 1")
