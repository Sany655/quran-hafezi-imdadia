import urllib.request
import json

try:
    # Test Quran.com API
    url = "https://api.quran.com/api/v4/chapters"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        print("Quran.com chapters fetched successfully. Count:", len(data.get('chapters', [])))
        print("Chapter 1 sample:", data['chapters'][0])
except Exception as e:
    print("Error querying Quran.com:", e)
