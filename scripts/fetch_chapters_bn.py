import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

url = "https://api.quran.com/api/v4/chapters?language=bn"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, timeout=10) as resp:
    data = json.loads(resp.read().decode('utf-8'))
    chapters = data.get('chapters', [])
    print("Fetched chapters:", len(chapters))
    print("Chapter 1:", json.dumps(chapters[0], ensure_ascii=False, indent=2))
    print("Chapter 2:", json.dumps(chapters[1], ensure_ascii=False, indent=2))
    with open(r"C:\All\works\Quran\data\chapters_bn.json", "w", encoding="utf-8") as f:
        json.dump(chapters, f, ensure_ascii=False, indent=2)
    print("Saved to C:\\All\\works\\Quran\\data\\chapters_bn.json")
