import sys

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r"C:\All\works\Quran\quran - word by word al quran\shobde_shobde_al_quran_01 ( 1-2).pdf"

with open(pdf_path, 'rb') as f:
    header = f.read(1024)
    print("PDF Header:", header[:64])
    f.seek(-2048, 2)
    tail = f.read(2048)
    print("PDF Trailer contains /XObject /Image?", b"/Image" in tail or b"/Image" in header)

# Check first 50KB to see if text or image stream
with open(pdf_path, 'rb') as f:
    chunk = f.read(100000)
    has_fonts = b"/Font" in chunk
    has_images = b"/Image" in chunk
    print(f"Contains /Font definitions: {has_fonts}")
    print(f"Contains /Image definitions: {has_images}")
