import urllib.request
import re

url = 'https://apkpure.com/imdadia-15-lines-hafezi-quran/com.amanullah.quran.imdadia/download'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'})
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        html = resp.read().decode('utf-8', errors='ignore')
        matches = re.findall(r'href=["\'](https?://[^"\']+)["\']', html)
        print("Total links:", len(matches))
        apk_links = [m for m in matches if 'download' in m.lower() or 'apk' in m.lower()]
        for link in apk_links[:10]:
            print("Candidate:", link)
except Exception as e:
    print("Error:", e)
