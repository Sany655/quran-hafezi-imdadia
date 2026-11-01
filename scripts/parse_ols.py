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

idx = config.find("var ols = ")
end_idx = config.find(";\n", idx)
ols_str = config[idx + len("var ols = "):end_idx].strip()

# Let's save and inspect
try:
    ols_data = json.loads(ols_str)
    print(f"Parsed {len(ols_data)} top-level sections:")
    for sec in ols_data:
        print(f" - Section: '{sec.get('caption')}', Children: {len(sec.get('children', []))}")
        
    with open(r"C:\All\works\Quran\data\imdadia_index.json", "w", encoding="utf-8") as f:
        json.dump(ols_data, f, ensure_ascii=False, indent=2)
    print("Saved to C:\\All\\works\\Quran\\data\\imdadia_index.json")
except Exception as e:
    print("JSON Parse error:", e)
    # Print near error
    print(ols_str[:500])
