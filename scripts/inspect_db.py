import sqlite3

con = sqlite3.connect('data/quran_imdadia.db')
cur = con.cursor()
tables = [r[0] for r in cur.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
print('Tables:', tables)

if 'translations' in tables:
    editions = cur.execute('SELECT edition, count(*) FROM translations GROUP BY edition').fetchall()
    print('Translations editions:', editions)

if 'tafsirs' in tables:
    tafsir_names = cur.execute('SELECT tafsir_name, count(*) FROM tafsirs GROUP BY tafsir_name').fetchall()
    print('Tafsir names:', tafsir_names)
