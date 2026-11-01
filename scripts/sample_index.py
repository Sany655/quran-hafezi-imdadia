import sys

sys.stdout.reconfigure(encoding='utf-8')
# Let's check the last page of Juz and Surahs
import json

with open(r"C:\All\works\Quran\data\imdadia_index.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print("Last 3 Surahs:")
for s in data[0]['children'][-3:]:
    print(" ", s)

print("Last Juz:")
print(" ", data[1]['children'][-1])
