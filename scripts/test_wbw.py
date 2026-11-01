import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

url = "https://api.quran.com/api/v4/verses/by_chapter/1?language=bn&words=true&word_fields=text_indopak,text_uthmani,translation&fields=text_indopak"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=10) as resp:
    data = json.loads(resp.read().decode('utf-8'))
    v1 = data['verses'][0]
    print(f"Verse {v1['verse_key']} has {len(v1['words'])} words:")
    for w in v1['words']:
        print(f"  Word {w['position']}: Ar: '{w.get('text_indopak')}' / Bn: '{w.get('translation', {}).get('text')}'")
