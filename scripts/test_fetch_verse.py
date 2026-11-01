import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

url = "https://api.quran.com/api/v4/verses/by_chapter/1?language=bn&words=false&translations=161,213&fields=text_indopak,text_uthmani,chapter_id"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=10) as resp:
    data = json.loads(resp.read().decode('utf-8'))
    print("Verses in Surah 1:", len(data.get('verses', [])))
    v1 = data['verses'][0]
    print("Verse key:", v1.get('verse_key'))
    print("Indo-Pak text:", v1.get('text_indopak'))
    print("Translations count:", len(v1.get('translations', [])))
    for t in v1.get('translations', []):
        print(f"  [ID {t['resource_id']}]: {t['text']}")
