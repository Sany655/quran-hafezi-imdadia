import os
import sys
import time
import urllib.request
import urllib.parse

sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'reference_books'))

DOWNLOAD_LIST = [
    # 1. Tawzeehul Quran Bangla (Mufti Taqi Usmani - 3 Volumes)
    {
        'subfolder': 'tawzeehul_quran_bangla',
        'filename': 'Tafseer_Tawzeehul_Quran_Vol_1.pdf',
        'url': 'https://archive.org/download/tawzeehul/Tafseer-e-Tawzeehul-Quran-1.pdf',
        'expected_mb': 24.7
    },
    {
        'subfolder': 'tawzeehul_quran_bangla',
        'filename': 'Tafseer_Tawzeehul_Quran_Vol_2.pdf',
        'url': 'https://archive.org/download/tawzeehul/Tafseer-e-Tawzeehul-Quran-2.pdf',
        'expected_mb': 33.2
    },
    {
        'subfolder': 'tawzeehul_quran_bangla',
        'filename': 'Tafseer_Tawzeehul_Quran_Vol_3.pdf',
        'url': 'https://archive.org/download/tawzeehul/Tafseer-e-Tawzeehul-Quran-3.pdf',
        'expected_mb': 33.5
    },

    # 2. Tafsir Usmani Bangla (Allama Shabbir Ahmad Usmani - 4 Volumes)
    {
        'subfolder': 'tafsir_usmani_bangla',
        'filename': 'Tafsir_Usmani_Vol_1_Surah_1-6.pdf',
        'url': 'https://archive.org/download/20251118_20251118_1818/' + urllib.parse.quote('তাফসীরে উসমানী ১ম খণ্ড (সূরা ১—৬).pdf'),
        'expected_mb': 17.4
    },
    {
        'subfolder': 'tafsir_usmani_bangla',
        'filename': 'Tafsir_Usmani_Vol_2_Surah_7-18.pdf',
        'url': 'https://archive.org/download/20251118_20251118_1906/' + urllib.parse.quote('তাফসীরে উসমানী ২য় খণ্ড (সূরা ৭—১৮).pdf'),
        'expected_mb': 16.4
    },
    {
        'subfolder': 'tafsir_usmani_bangla',
        'filename': 'Tafsir_Usmani_Vol_3_Surah_19-38.pdf',
        'url': 'https://archive.org/download/20251118_20251118_1940/' + urllib.parse.quote('তাফসীরে উসমানী ৩য় খণ্ড (সূরা ১৯—৩৮).pdf'),
        'expected_mb': 14.0
    },
    {
        'subfolder': 'tafsir_usmani_bangla',
        'filename': 'Tafsir_Usmani_Vol_4_Surah_39-114.pdf',
        'url': 'https://archive.org/download/20251118_20251118_2000/' + urllib.parse.quote('তাফসীরে উসমানী ৪র্থ খণ্ড (সূরা ৩৯—১১৪) মাওলানা শাব্বির আহমদ উসমানী রহ..pdf'),
        'expected_mb': 14.6
    },

    # 3. Maariful Quran Bangla (Mufti Shafi - Short + 8 Volumes)
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Short_Complete.pdf',
        'url': 'https://archive.org/download/mareful/MarefulQuran-short.pdf',
        'expected_mb': 75.4
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_01.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-01(Almodina.com).pdf',
        'expected_mb': 64.6
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_02.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-02(Almodina.com).pdf',
        'expected_mb': 54.8
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_03.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-03(Almodina.com).pdf',
        'expected_mb': 54.1
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_04.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-04(Almodina.com).pdf',
        'expected_mb': 72.5
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_05.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-05(Almodina.com).pdf',
        'expected_mb': 61.7
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_06.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-06(Almodina.com).pdf',
        'expected_mb': 77.9
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_07.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-07(Almodina.com).pdf',
        'expected_mb': 73.8
    },
    {
        'subfolder': 'maariful_quran_bangla',
        'filename': 'Maariful_Quran_Vol_08.pdf',
        'url': 'https://archive.org/download/mareful/Maariful-Quran-08(Almodina.com).pdf',
        'expected_mb': 76.4
    },
]

def download_file(item, index, total):
    dest_dir = os.path.join(BASE_DIR, item['subfolder'])
    os.makedirs(dest_dir, exist_ok=True)
    dest_file = os.path.join(dest_dir, item['filename'])

    if os.path.exists(dest_file):
        existing_size = os.path.getsize(dest_file)
        if existing_size > 1024 * 1024:
            print(f"[{index}/{total}] Already downloaded: {item['filename']} ({existing_size // (1024*1024)} MB)", flush=True)
            return

    print(f"[{index}/{total}] Downloading: {item['filename']} (~{item['expected_mb']} MB)...", flush=True)
    req = urllib.request.Request(item['url'], headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    
    start_time = time.time()
    try:
        with urllib.request.urlopen(req, timeout=120) as resp, open(dest_file, 'wb') as f:
            total_size = int(resp.headers.get('content-length', 0))
            downloaded = 0
            chunk_size = 1024 * 512 # 512 KB
            last_report = time.time()
            while True:
                chunk = resp.read(chunk_size)
                if not chunk:
                    break
                f.write(chunk)
                downloaded += len(chunk)
                if time.time() - last_report > 5:
                    pct = (downloaded / total_size * 100) if total_size else 0
                    print(f"   Progress: {downloaded // (1024*1024)} MB / {total_size // (1024*1024)} MB ({pct:.1f}%)", flush=True)
                    last_report = time.time()
        elapsed = time.time() - start_time
        print(f"-> Finished: {item['filename']} in {elapsed:.1f}s", flush=True)
    except Exception as e:
        print(f"-> Error downloading {item['filename']}: {e}", flush=True)
        if os.path.exists(dest_file) and os.path.getsize(dest_file) == 0:
            os.remove(dest_file)

def main():
    print(f"Target Directory: {BASE_DIR}", flush=True)
    total = len(DOWNLOAD_LIST)
    for i, item in enumerate(DOWNLOAD_LIST, 1):
        download_file(item, i, total)
    print("\nAll downloads finished successfully!", flush=True)

if __name__ == '__main__':
    main()
