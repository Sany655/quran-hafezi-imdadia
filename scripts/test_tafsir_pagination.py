import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

url_ch = "https://api.quran.com/api/v4/tafsirs/165/by_chapter/2?per_page=50&page=1"
req = urllib.request.Request(url_ch, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        tafsirs = data.get('tafsirs', [])
        pagination = data.get('pagination', {})
        print("Tafsirs fetched:", len(tafsirs))
        print("Pagination:", pagination)
        if tafsirs:
            print("First item keys:", tafsirs[0].keys())
            print("First item verse_key:", tafsirs[0].get('verse_key'))
            print("First item verse_id:", tafsirs[0].get('verse_id'))
except Exception as e:
    print("Error:", e)
