import zipfile
import sys

sys.stdout.reconfigure(encoding='utf-8')
xapk_path = r"C:\All\works\Quran\quran - word by word al quran\Imdadia+15+lines+Hafezi+Quran_1.0.4_APKPure.xapk"

with zipfile.ZipFile(xapk_path, 'r') as z:
    with z.open('com.amanullah.quran.imdadia.apk') as apk_bytes:
        with zipfile.ZipFile(apk_bytes, 'r') as inner_z:
            config = inner_z.read('assets/javascript/config.js').decode('utf-8', errors='ignore')

idx = config.find("Al-Anaam")
start_idx = config.rfind("var ", 0, idx)
print("Variable declaration:")
print(config[start_idx:start_idx+150])
