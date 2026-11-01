import zipfile
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"
audio_dir = r"C:\All\works\Quran\assets\audio"
os.makedirs(audio_dir, exist_ok=True)

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            for item in inner_z.infolist():
                if item.filename.endswith(('.mp3', '.ogg')):
                    dest_path = os.path.join(audio_dir, os.path.basename(item.filename))
                    with inner_z.open(item) as src, open(dest_path, 'wb') as dst:
                        dst.write(src.read())
                    print("Extracted audio:", item.filename, "->", dest_path)
