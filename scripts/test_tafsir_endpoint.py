import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Check Tafsir endpoints for Tafsir Ibn Kathir (164) and Ahsanul Bayaan (165)
# Test 1: by_ayah
url_ayah = "https://api.quran.com/api/v4/tafsirs/164/by_ayah/1:1"
req = urllib.request.Request(url_ayah, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        print("Tafsir 164 for 1:1 fetched successfully:")
        tafsir_text = data.get('tafsir', {}).get('text', '')
        print("Length:", len(tafsir_text))
        print("Snippet:", tafsir_text[:200])
except Exception as e:
    print("Error by_ayah:", e)

# Test 2: by_chapter or bulk
url_ch = "https://api.quran.com/api/v4/tafsirs/164/by_chapter/1"
req2 = urllib.request.Request(url_ch, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req2, timeout=10) as resp:
        data2 = json.loads(resp.read().decode('utf-8'))
        print("\nChapter 1 tafsirs count:", len(data2.get('tafsirs', [])))
        if data2.get('tafsirs'):
            print("First item verse_id/key:", data2['tafsirs'][0].get('verse_key') or data2['tafsirs'][0].get('verse_id'))
except Exception as e:
    print("Error by_chapter:", e)

# Test 3: Ahsanul Bayaan (165)
url_ahsan = "https://api.quran.com/api/v4/tafsirs/165/by_ayah/1:1"
req3 = urllib.request.Request(url_ahsan, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req3, timeout=10) as resp:
        data3 = json.loads(resp.read().decode('utf-8'))
        print("\nAhsanul Bayaan 165 for 1:1 fetched:")
        print("Snippet:", data3.get('tafsir', {}).get('text', '')[:200])
except Exception as e:
    print("Error Ahsanul Bayaan:", e)
