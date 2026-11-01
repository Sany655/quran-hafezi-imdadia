import zipfile
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"
res_dir = r"C:\All\works\Quran\android\app\src\main\res"

with zipfile.ZipFile(xapk_path, 'r') as z:
    icon_bytes = z.read('icon.png')
    print("Found icon.png in XAPK, size:", len(icon_bytes))

# Populate mipmap folders
mipmap_folders = [
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
]

for folder in mipmap_folders:
    target_dir = os.path.join(res_dir, folder)
    os.makedirs(target_dir, exist_ok=True)
    icon_path = os.path.join(target_dir, 'ic_launcher.png')
    with open(icon_path, 'wb') as f:
        f.write(icon_bytes)
    print(f"Created: {icon_path}")

print("All ic_launcher mipmaps created successfully!")
