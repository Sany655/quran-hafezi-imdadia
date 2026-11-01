import zipfile
import json
import os

xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

print("Checking XAPK:", xapk_path)
with zipfile.ZipFile(xapk_path, 'r') as z:
    file_list = z.namelist()
    print("Files inside XAPK:", file_list[:20])
    
    # Read manifest.json if exists
    if 'manifest.json' in file_list:
        manifest_raw = z.read('manifest.json').decode('utf-8', errors='ignore')
        manifest_data = json.loads(manifest_raw)
        print("\n--- XAPK MANIFEST DETAILS ---")
        print("Package Name:", manifest_data.get('package_name'))
        print("App Name:", manifest_data.get('name'))
        print("Version Code:", manifest_data.get('version_code'))
        print("Version Name:", manifest_data.get('version_name'))
        print("Min SDK:", manifest_data.get('min_sdk_version'))
        print("Target SDK:", manifest_data.get('target_sdk_version'))

    # Check the APK inside the XAPK
    apk_files = [f for f in file_list if f.endswith('.apk')]
    print("\nAPK files in XAPK:", apk_files)
    
    for apk_file in apk_files:
        print(f"\nInspecting inner APK: {apk_file}")
        with z.open(apk_file) as apk_bytes:
            with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
                inner_files = inner_z.namelist()
                print("Total files inside APK:", len(inner_files))
                
                # Check assets
                assets = [f for f in inner_files if f.startswith('assets/')]
                print("Total assets:", len(assets))
                print("Sample assets (first 25):")
                for a in assets[:25]:
                    print("  ", a)
                
                # Check for databases or page folders
                page_files = [f for f in inner_files if 'page' in f.lower() or 'quran' in f.lower() or f.endswith('.webp') or f.endswith('.png') or f.endswith('.jpg')]
                print(f"\nFound {len(page_files)} candidate page/image files in APK. Sample:")
                for p in page_files[:15]:
                    print("  ", p)
