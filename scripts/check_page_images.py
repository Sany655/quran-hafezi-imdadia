import zipfile
import struct
import sys

sys.stdout.reconfigure(encoding='utf-8')

def get_jpeg_size(data):
    # Parse JPEG to get dimensions
    pos = 2
    while pos < len(data):
        marker, length = struct.unpack(">2sH", data[pos:pos+4])
        if marker in [b"\xff\xc0", b"\xff\xc2"]: # SOF0 or SOF2
            h, w = struct.unpack(">HH", data[pos+5:pos+9])
            return w, h
        pos += 2 + length
    return None, None

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            for page_name in ['assets/files/page/1-min.jpg', 'assets/files/page/2-min.jpg', 'assets/files/page/3-min.jpg']:
                img_bytes = inner_z.read(page_name)
                w, h = get_jpeg_size(img_bytes)
                print(f"{page_name}: File Size = {len(img_bytes)/1024:.1f} KB, Resolution = {w}x{h} px")
