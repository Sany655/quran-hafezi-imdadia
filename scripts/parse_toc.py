import zipfile
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            config = inner_z.read('assets/javascript/config.js').decode('utf-8', errors='ignore')

# Find tableOfContent
match = re.search(r'var tableOfContent\s*=\s*(\[.*?\]);', config, re.DOTALL)
if match:
    toc_str = match.group(1)
    # Parse JSON
    try:
        toc = json.loads(toc_str)
        print("TOC parsed successfully! Items:", len(toc))
        for item in toc[:10]:
            print(item)
        with open(r"C:\All\works\Quran\data\imdadia_toc.json", "w", encoding="utf-8") as f:
            json.dump(toc, f, ensure_ascii=False, indent=2)
        print("Saved to imdadia_toc.json")
    except Exception as e:
        print("JSON parse error:", e)
else:
    print("Could not find tableOfContent regex match")
