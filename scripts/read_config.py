import zipfile
import sys

sys.stdout.reconfigure(encoding='utf-8')

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            config = inner_z.read('assets/files/search/book_config.js').decode('utf-8', errors='ignore')
            print("--- book_config.js (first 500 chars) ---")
            print(config[:500])
            
            sample_pos = inner_z.read('assets/files/search/text_position[1].js').decode('utf-8', errors='ignore')
            print("\n--- text_position[1].js (first 500 chars) ---")
            print(sample_pos[:500])
