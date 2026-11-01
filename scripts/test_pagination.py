import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

url = "https://api.quran.com/api/v4/verses/by_chapter/2?language=bn&words=true&word_fields=text_indopak,translation&translations=161,213&fields=text_indopak,text_uthmani&per_page=50&page=1"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=10) as resp:
    data = json.loads(resp.read().decode('utf-8'))
    print("Verses fetched on page 1:", len(data.get('verses', [])))
    print("Total records:", data.get('pagination', {}).get('total_records'))
    print("Total pages:", data.get('pagination', {}).get('total_pages'))
