import zipfile
import sys

sys.stdout.reconfigure(encoding='utf-8')
xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            config = inner_z.read('assets/javascript/config.js').decode('utf-8', errors='ignore')
            print("Config length:", len(config))
            for line in config.splitlines():
                if any(k in line.lower() for k in ['totalpage', 'page', 'title', 'toc', 'bookmark', 'index']):
                    if len(line) < 200:
                        print("  ", line.strip())
