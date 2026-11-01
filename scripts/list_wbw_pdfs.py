import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

folder = r"C:\All\works\Quran\quran - word by word al quran"
files = os.listdir(folder)
print(f"Total files: {len(files)}")
for f in sorted(files):
    full = os.path.join(folder, f)
    sz_mb = os.path.getsize(full) / (1024 * 1024)
    print(f" - {f} ({sz_mb:.2f} MB)")
