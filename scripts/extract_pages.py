import zipfile
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"
output_dir = r"C:\All\works\Quran\assets\pages"
os.makedirs(output_dir, exist_ok=True)

print(f"Extracting Imdadia pages to: {output_dir}")

extracted_count = 0
with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            for item in inner_z.infolist():
                if item.filename.startswith('assets/files/page/') and item.filename.endswith('-min.jpg'):
                    # e.g. assets/files/page/1-min.jpg -> 1
                    base = os.path.basename(item.filename)
                    page_num_str = base.replace('-min.jpg', '')
                    try:
                        page_num = int(page_num_str)
                        # Zero-pad to 3 digits: page_001.jpg, page_002.jpg ...
                        dest_filename = f"page_{page_num:03d}.jpg"
                        dest_path = os.path.join(output_dir, dest_filename)
                        with inner_z.open(item) as src, open(dest_path, 'wb') as dst:
                            dst.write(src.read())
                        extracted_count += 1
                    except ValueError:
                        print(f"Skipping non-numeric page item: {item.filename}")

print(f"Extraction complete! Successfully extracted {extracted_count} pages to {output_dir}")
