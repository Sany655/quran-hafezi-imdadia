import sqlite3
import sys

sys.stdout.reconfigure(encoding='utf-8')

db_path = r"C:\All\works\Quran\data\quran_imdadia.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Islamic dictionary map: Banglish / Synonyms -> Bengali search terms
ISLAMIC_SEARCH_SYNONYMS = {
    # Banglish to Bengali
    'salat': ['সালাত', 'নামায', 'নামাজ'],
    'salah': ['সালাত', 'নামায', 'নামাজ'],
    'namaz': ['নামায', 'নামাজ', 'সালাত'],
    'namaj': ['নামায', 'নামাজ', 'সালাত'],
    'roza': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'roja': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'sawm': ['সাওম', 'সিয়াম', 'রোজা'],
    'siyam': ['সিয়াম', 'সাওম', 'রোজা'],
    'ramadan': ['রমযান', 'রমজান', 'সাওম'],
    'ramzan': ['রমযান', 'রমজান', 'সাওম'],
    'zakat': ['যাকাত', 'জাকাত'],
    'jakat': ['যাকাত', 'জাকাত'],
    'jannat': ['জান্নাত', 'জান্নাতুল', 'উদ্যান'],
    'jannah': ['জান্নাত', 'জান্নাতুল'],
    'jahannam': ['জাহান্নাম', 'জাহান্নামের', 'আগুন', 'দোযখ'],
    'hell': ['জাহান্নাম'],
    'heaven': ['জান্নাত'],
    'paradise': ['জান্নাত'],
    'sabr': ['ধৈর্য', 'সবর'],
    'sobor': ['ধৈর্য', 'সবর'],
    'shirk': ['শিরক', 'শিরক্'],
    'tawhid': ['তাওহীদ', 'তৌহিদ'],
    'touhid': ['তাওহীদ', 'তৌহিদ'],
    'iman': ['ঈমান', 'বিশ্বাস'],
    'momin': ['মুমিন', 'ঈমানদার'],
    'munafik': ['মুনাফিক', 'কপট'],
    'kafir': ['কাফির', 'অবিশ্বাসী'],
    'riba': ['সুদ', 'রিবা'],
    'sud': ['সুদ', 'রিবা'],
    'qurbani': ['কুরবানী', 'কোরবানী'],
    'korbani': ['কুরবানী', 'কোরবানী'],
    'hajj': ['হজ্জ', 'হজ'],
    'haj': ['হজ্জ', 'হজ'],
    'umrah': ['উমরাহ', 'উমরা'],
    'dua': ['দুআ', 'দোয়া', 'প্রার্থনা'],
    'doya': ['দুআ', 'দোয়া', 'প্রার্থনা'],
    'zikr': ['যিকির', 'স্মরণ'],
    'dhikr': ['যিকির', 'স্মরণ'],
    'tawbah': ['তওবা', 'তাওবাহ', 'ক্ষমা'],
    'touba': ['তওবা', 'তাওবাহ', 'ক্ষমা'],
    'wudu': ['ওজু', 'উযূ', 'অযু'],
    'oju': ['ওজু', 'উযূ', 'অযু'],
    'quran': ['কুরআন', 'কোরআন', 'কিতাব'],
    'koran': ['কুরআন', 'কোরআন', 'কিতাব'],
    'bismillah': ['বিসমিল্লাহ', 'আল্লাহর নামে'],
    'alhamdulillah': ['আলহামদুলিল্লাহ', 'সকল প্রশংসা'],
    'subhanallah': ['সুবহানাল্লাহ', 'পবিত্র'],
    'astagfirullah': ['ক্ষমা'],
    'allah': ['আল্লাহ', 'আল্লাহর'],
    'rasul': ['রাসূল', 'রাসুল', 'নবী'],
    'prophet': ['নবী', 'রাসূল'],
    'feresta': ['ফেরেশতা', 'মালাইকা'],
    'angel': ['ফেরেশতা', 'মালাইকা'],

    # Bengali to Synonyms (Banglarobi / Bengali variants)
    'নামাজ': ['নামায', 'সালাত'],
    'নামায': ['নামাজ', 'সালাত'],
    'সালাত': ['সালাত', 'নামায', 'নামাজ'],
    'রোজা': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'রোযা': ['রোজা', 'রোযা', 'সাওম', 'সিয়াম'],
    'সাওম': ['সাওম', 'সিয়াম', 'রোজা'],
    'সিয়াম': ['সিয়াম', 'সাওম', 'রোজা'],
    'জাকাত': ['যাকাত', 'জাকাত'],
    'যাকাত': ['যাকাত', 'জাকাত'],
    'সুদ': ['সুদ', 'রিবা'],
    'দোয়া': ['দোয়া', 'দুআ', 'প্রার্থনা'],
    'দুআ': ['দুআ', 'দোয়া', 'প্রার্থনা'],
    'সবর': ['সবর', 'ধৈর্য'],
    'ধৈর্য': ['ধৈর্য', 'সবর'],
    'বেহেশত': ['জান্নাত'],
    'দোযখ': ['জাহান্নাম'],
    'ওজু': ['ওজু', 'উযূ', 'অযু'],
    'তওবা': ['তওবা', 'তাওবাহ', 'ক্ষমা'],
    'কোরবানী': ['কুরবানী', 'কোরবানী'],
    'কুরবানী': ['কুরবানী', 'কোরবানী'],
}

def search_smart(user_query):
    q = user_query.strip().lower()
    
    # 1. Expand query using synonyms / transliterations
    terms_to_search = [user_query.strip()]
    if q in ISLAMIC_SEARCH_SYNONYMS:
        terms_to_search.extend(ISLAMIC_SEARCH_SYNONYMS[q])
    
    # Deduplicate while preserving order
    unique_terms = []
    for t in terms_to_search:
        if t not in unique_terms:
            unique_terms.append(t)
            
    print(f"User Query: '{user_query}' -> Expanded Search Terms: {unique_terms}")
    
    # Build dynamic SQL with OR
    clauses = ["t.text_bn LIKE ?" for _ in unique_terms]
    sql = f'''
        SELECT s.id as surah_id, s.name_bn, s.name_en, t.ayah_number, t.edition, t.text_bn
        FROM translations t
        JOIN surahs s ON s.id = t.surah_id
        WHERE ({' OR '.join(clauses)})
        ORDER BY s.id ASC, t.ayah_number ASC
        LIMIT 100;
    '''
    params = [f"%{t}%" for t in unique_terms]
    cur.execute(sql, params)
    return cur.fetchall()

# Test various Banglish and Bengali terms
for test_term in ['salat', 'namaj', 'roza', 'jannat', 'জাহান্নাম', 'sabr', 'সুদ', 'bismillah']:
    results = search_smart(test_term)
    print(f"Results for '{test_term}': {len(results)} found")
    if results:
        print(f"  Sample: Surah {results[0][1]} ({results[0][3]}): {results[0][5][:70]}...\n")
