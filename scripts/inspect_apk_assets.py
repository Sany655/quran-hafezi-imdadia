import zipfile

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            non_images = [f for f in inner_z.namelist() if f.startswith('assets/') and not f.endswith(('.jpg', '.png', '.webp', '.prof', '.profm'))]
            print(f"Non-image assets ({len(non_images)}):")
            for f in non_images:
                print("  ", f)
            
            # Count total page images
            pages = [f for f in inner_z.namelist() if f.startswith('assets/files/page/') and f.endswith('-min.jpg')]
            print(f"\nTotal page images: {len(pages)}")
