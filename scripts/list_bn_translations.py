import urllib.request
import json

url = "https://api.quran.com/api/v4/resources/translations"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        bn_translations = [t for t in data.get('translations', []) if t.get('language_name') == 'bengali']
        print(f"Found {len(bn_translations)} Bengali translations:")
        for t in bn_translations:
            print(f"ID: {t['id']}, Name: {t['name']}, Author: {t['author_name']}")
except Exception as e:
    print("Error:", e)
