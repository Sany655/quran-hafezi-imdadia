import urllib.request
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
url = 'http://quran.gov.bd/'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, timeout=10) as r:
        html = r.read().decode('utf-8')
        scripts = re.findall(r'<script[^>]*src=["\']([^"\']+)["\']', html)
        print('Scripts:', scripts)
        links = re.findall(r'href=["\']([^"\']+)["\']', html)
        api_links = [l for l in links if 'api' in l or 'quran' in l or 'surah' in l]
        print('Links:', api_links[:10])
except Exception as e:
    print('Error:', e)
