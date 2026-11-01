import os
from PIL import Image, ImageDraw, ImageFont

fonts_to_check = [
    r"C:\Windows\Fonts\cambriab.ttf",
    r"C:\Windows\Fonts\georgiab.ttf",
    r"C:\Windows\Fonts\timesbd.ttf",
    r"C:\Windows\Fonts\arialbd.ttf",
]

for f in fonts_to_check:
    print(f, "exists:", os.path.exists(f))
