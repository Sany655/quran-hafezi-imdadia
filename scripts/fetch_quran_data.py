import urllib.request
import urllib.error
import json
import sqlite3
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"

def get_connection():
    conn = sqlite3.connect(db_path, timeout=30)
    conn.execute("PRAGMA journal_mode=WAL;")
    return conn

def fetch_surah(surah_id, total_ayahs):
    conn = get_connection()
    cur = conn.cursor()
    
    # Check if surah already fully fetched
    cur.execute("SELECT COUNT(*) FROM ayahs WHERE surah_id = ?", (surah_id,))
    count = cur.fetchone()[0]
    if count == total_ayahs:
        conn.close()
        return True, count

    page = 1
    fetched_verses = 0
    
    while True:
        url = (
            f"https://api.quran.com/api/v4/verses/by_chapter/{surah_id}"
            f"?language=bn&words=true&word_fields=text_indopak,translation"
            f"&translations=161,213&fields=text_indopak,text_uthmani"
            f"&per_page=50&page={page}"
        )
        
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        
        success = False
        data = None
        for attempt in range(5):
            try:
                with urllib.request.urlopen(req, timeout=15) as resp:
                    data = json.loads(resp.read().decode('utf-8'))
                    success = True
                    break
            except Exception as e:
                time.sleep(1.5 * (attempt + 1))
        
        if not success or not data:
            conn.close()
            return False, fetched_verses

        verses = data.get('verses', [])
        if not verses:
            break

        for v in verses:
            ayah_num = v['verse_number']
            vk = v['verse_key']
            text_indo = v.get('text_indopak') or ''
            text_uth = v.get('text_uthmani') or ''
            
            # Insert ayah
            cur.execute("""
                INSERT OR REPLACE INTO ayahs (surah_id, ayah_number, verse_key, text_indopak, text_uthmani)
                VALUES (?, ?, ?, ?, ?)
            """, (surah_id, ayah_num, vk, text_indo, text_uth))
            
            # Insert translations
            for tr in v.get('translations', []):
                edition = 'taisirul' if tr['resource_id'] == 161 else 'zakaria'
                text_bn = tr['text']
                cur.execute("""
                    INSERT INTO translations (surah_id, ayah_number, edition, text_bn)
                    VALUES (?, ?, ?, ?)
                """, (surah_id, ayah_num, edition, text_bn))
                
                # FTS
                cur.execute("""
                    INSERT INTO search_translations_fts (surah_id, ayah_number, edition, text_bn)
                    VALUES (?, ?, ?, ?)
                """, (surah_id, ayah_num, edition, text_bn))

            # Insert word-by-word
            for w in v.get('words', []):
                pos = w.get('position', 1)
                w_ar = w.get('text_indopak') or w.get('text_uthmani') or ''
                w_bn = w.get('translation', {}).get('text') or ''
                cur.execute("""
                    INSERT INTO words_wbw (surah_id, ayah_number, position, text_arabic, meaning_bn)
                    VALUES (?, ?, ?, ?, ?)
                """, (surah_id, ayah_num, pos, w_ar, w_bn))

            fetched_verses += 1

        pagination = data.get('pagination', {})
        if page >= pagination.get('total_pages', 1):
            break
        page += 1
        time.sleep(0.2)

    conn.commit()
    conn.close()
    return True, fetched_verses

def main():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name_bn, total_ayahs FROM surahs ORDER BY id ASC")
    surahs = cur.fetchall()
    conn.close()

    total_surahs = len(surahs)
    print(f"Starting fetch for {total_surahs} surahs...")
    
    for idx, (sid, name_bn, total_ayahs) in enumerate(surahs, start=1):
        ok, count = fetch_surah(sid, total_ayahs)
        if ok:
            print(f"[{idx:03d}/{total_surahs}] Surah {sid:03d}: {name_bn} ({total_ayahs} ayahs) - Done")
        else:
            print(f"[{idx:03d}/{total_surahs}] Surah {sid:03d}: {name_bn} - Failed/Partial ({count} fetched)")
        time.sleep(0.1)

    print("Quran Data Collection Complete!")

if __name__ == '__main__':
    main()
