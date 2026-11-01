import sqlite3
import json
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Load chapters and imdadia index
with open(r"C:\All\works\Quran\data\chapters_bn.json", "r", encoding="utf-8") as f:
    chapters = json.load(f)

with open(r"C:\All\works\Quran\data\imdadia_index.json", "r", encoding="utf-8") as f:
    imdadia_index = json.load(f)

surah_items = imdadia_index[0]['children']
juz_items = imdadia_index[1]['children']

# Map Surah start pages from Imdadia index
surah_start_pages = {}
for item in surah_items:
    # caption format: "1. Al-Fatiha (The Opening)"
    m = re.match(r"^(\d+)\.", item['caption'])
    if m:
        surah_start_pages[int(m.group(1))] = item['page']

# Bengali names map for standard Surah names
bn_surah_names = {
    1: "আল-ফাতিহা", 2: "আল-বাকারাহ", 3: "আলে ইমরান", 4: "আন-নিসা", 5: "আল-মায়িদাহ",
    6: "আল-আনআম", 7: "আল-আরাফ", 8: "আল-আনফাল", 9: "আত-তাওবাহ", 10: "ইউনুস",
    11: "হুদ", 12: "ইউসুফ", 13: "আর-রাদ", 14: "ইবরাহীম", 15: "আল-হিজর",
    16: "আন-নাহল", 17: "বনী ইসরাঈল", 18: "আল-কাহফ", 19: "মারিয়াম", 20: "ত্বা-হা",
    21: "আল-আম্বিয়া", 22: "আল-হাজ্জ", 23: "আল-মুমিনূন", 24: "আন-নূর", 25: "আল-ফুরকান",
    26: "আশ-শুআরা", 27: "আন-নামল", 28: "আল-কাসাস", 29: "আল-আনকাবূত", 30: "আর-রূম",
    31: "লুকমান", 32: "আস-সাজদাহ", 33: "আল-আহযাব", 34: "সাবা", 35: "ফাতির",
    36: "ইয়াসীন", 37: "আস-সাফফাত", 38: "সোয়াদ", 39: "আয-যুমার", 40: "গাফির",
    41: "ফুসসিলাত", 42: "আশ-শূরা", 43: "আয-যুখরুফ", 44: "আদ-দুখান", 45: "আল-জাসিয়াহ",
    46: "আল-আহকাফ", 47: "মুহাম্মদ", 48: "আল-ফাতহ", 49: "আল-হুজুরাত", 50: "ক্বাফ",
    51: "আয-যারিয়াত", 52: "আত-তূর", 53: "আন-নাজম", 54: "আল-কামার", 55: "আর-রাহমান",
    56: "আল-ওয়াকিয়াহ", 57: "আল-হাদীদ", 58: "আল-মুজাদালাহ", 59: "আল-হাশর", 60: "আল-মুমতাহিনাহ",
    61: "আস-সফ", 62: "আল-জুমুআহ", 63: "আল-মুনাফিকূন", 64: "আত-তাগাবুন", 65: "আত-ত্বালাক",
    66: "আত-তাহরীম", 67: "আল-মুলক", 68: "আল-কলম", 69: "আল-হাক্কাহ", 70: "আল-মাআরিজ",
    71: "নূহ", 72: "আল-জিন", 73: "আল-মুযযাম্মিল", 74: "আল-মুদ্দাসসির", 75: "আল-কিয়ামাহ",
    76: "আল-ইনসান", 77: "আল-মুরসালাত", 78: "আন-নাবা", 79: "আন-নাযিআত", 80: "আবাসা",
    81: "আত-তাকবীর", 82: "আল-ইনফিতার", 83: "আল-মুতাফফিফীন", 84: "আল-ইনশিকাক", 85: "আল-বুরূজ",
    86: "আত-তারিক", 87: "আল-আলা", 88: "আল-গাশিয়াহ", 89: "আল-ফজর", 90: "আল-বালাদ",
    91: "আশ-শামস", 92: "আল-লাইল", 93: "আদ-দুহা", 94: "আল-ইনশিরাহ", 95: "আত-তীন",
    96: "আল-আলাক", 97: "আল-কদর", 98: "আল-বাইয়িনাহ", 99: "আল-যিলযাল", 100: "আল-আদিয়াত",
    101: "আল-কারিআহ", 102: "আত-তাকাসুর", 103: "আল-আসর", 104: "আল-হুমাযাহ", 105: "আল-ফীল",
    106: "কুরাইশ", 107: "আল-মাউন", 108: "আল-কাওসার", 109: "আল-কাফিরূন", 110: "আন-নাসর",
    111: "আল-লাহাব", 112: "আল-ইখলাস", 113: "আল-ফালাক", 114: "আন-নাস"
}

# 1. Insert Surahs
cur.execute("DELETE FROM surahs;")
for ch in chapters:
    sid = ch['id']
    name_ar = ch['name_arabic']
    name_en = ch['name_simple']
    name_bn = bn_surah_names.get(sid, ch['name_simple'])
    meaning_bn = ch['translated_name']['name']
    rev_type = "মাক্কী" if ch['revelation_place'] == 'makkah' else "মাদানী"
    total_ayahs = ch['verses_count']
    start_page = surah_start_pages.get(sid, ch['pages'][0])
    
    cur.execute("""
        INSERT INTO surahs (id, name_ar, name_en, name_bn, meaning_bn, revelation_type, total_ayahs, start_page)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, (sid, name_ar, name_en, name_bn, meaning_bn, rev_type, total_ayahs, start_page))

print(f"Inserted {len(chapters)} surahs.")

# 2. Insert Juz
juz_names = [
    ("الم", "Alif-Lam-Meem", "আলিফ লাম মীম"),
    ("سيقول", "Sayaqool", "সায়াকুলু"),
    ("تلك الرسل", "Tilka-r-Rusul", "তিলকার রুসুল"),
    ("لن تنالوا", "Lan Tanaalu", "লান তানালূ"),
    ("والمحصنات", "Wal-Muhsanat", "ওয়াল মুহসানাত"),
    ("لا يحب الله", "La Yuhibbullah", "লা ইউহিব্বুল্লাহ"),
    ("واذا سمعوا", "Wa Iza Sami'u", "ওয়া ইযা সামিউ"),
    ("ولو اننا", "Wa Law Annana", "ওয়া লাও আন্নানা"),
    ("قال الملا", "Qalal Mala'u", "ক্বলাল মালাউ"),
    ("واعلموا", "Wa'lamu", "ওয়ালামূ"),
    ("يعتذرون", "Ya'tazirun", "ইয়াতাযিরূন"),
    ("وما من دابة", "Wa Ma Min Dabbah", "ওয়া মা মিন দাব্বাহ"),
    ("وما ابرئ", "Wa Ma Ubri'u", "ওয়া মা উবাররিউ"),
    ("ربما", "Rubama", "রুবামা"),
    ("سبحان الذي", "Subhanallazi", "সুবহানাল্লাযী"),
    ("قال الم", "Qala Alam", "ক্বলা আলাম"),
    ("اقترب", "Iqtaraba", "ইক্বতারা বা"),
    ("قد افلح", "Qad Aflaha", "ক্বাদ আফলাহা"),
    ("وقال الذين", "Wa Qalallazina", "ওয়া ক্বালাল্লাযীনা"),
    ("امن خلق", "Amman Khalaqa", "আম্মান খালাক্বা"),
    ("اتل ما اوحي", "Utlu Ma Oohiya", "উতলু মা উহিয়া"),
    ("ومن يقنت", "Wa Man Yaqnut", "ওয়া মান ইয়াক্বনুত"),
    ("وما لي", "Wa Mali", "ওয়া মা লিয়া"),
    ("فمن اظلم", "Faman Azlamu", "ফামান আযলামু"),
    ("اليه يرد", "Ilayhi Yuraddu", "ইলাইহি ইউরাদ্দু"),
    ("حم", "Ha-Meem", "হা-মীম"),
    ("قال فما خطبكم", "Qala Fama Khatbukum", "ক্বলা ফামা খাতবুকুম"),
    ("قد سمع الله", "Qad Sami'allah", "ক্বাদ সামিয়াল্লাহ"),
    ("تبارك الذي", "Tabarakallazi", "তাবারাকাল্লাযী"),
    ("عم", "Amma", "আম্মা")
]

cur.execute("DELETE FROM juz;")
for idx, item in enumerate(juz_items, start=1):
    page = item['page']
    ar, en, bn = juz_names[idx-1]
    cur.execute("""
        INSERT INTO juz (id, name_ar, name_en, name_bn, start_page)
        VALUES (?, ?, ?, ?, ?)
    """, (idx, ar, en, bn, page))

print(f"Inserted {len(juz_items)} juz.")

# 3. Insert Pages (1 to 612)
cur.execute("DELETE FROM pages;")
for p in range(1, 613):
    img_file = f"assets/pages/page_{p:03d}.jpg"
    # Determine which Juz this page belongs to
    juz_num = 1
    for j_idx, item in enumerate(juz_items, start=1):
        if p >= item['page']:
            juz_num = j_idx
        else:
            break
    cur.execute("""
        INSERT INTO pages (page_number, image_file, juz_number)
        VALUES (?, ?, ?)
    """, (p, img_file, juz_num))

print("Inserted 612 pages.")

conn.commit()
conn.close()
print("Metadata population complete!")
