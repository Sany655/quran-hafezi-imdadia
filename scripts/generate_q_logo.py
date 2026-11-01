import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_q_logo():
    size = 512
    # Create image with transparent background
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Base Circular Background (Islamic Emerald Green)
    # Deep Emerald Green: #0B4627 -> (11, 70, 39)
    # Highlight Green: #0F5A32
    padding = 16
    draw.ellipse([padding, padding, size - padding, size - padding], fill=(11, 70, 39, 255))

    # 2. Concentric Decorative Gold Ring
    ring_padding = 34
    draw.ellipse(
        [ring_padding, ring_padding, size - ring_padding, size - ring_padding],
        outline=(212, 175, 55, 230), # Islamic Gold #D4AF37
        width=6
    )

    # Thin inner gold ring
    inner_ring_pad = 44
    draw.ellipse(
        [inner_ring_pad, inner_ring_pad, size - inner_ring_pad, size - inner_ring_pad],
        outline=(212, 175, 55, 120),
        width=2
    )

    # 3. Draw the "Q" Letter in the Center
    font_path = r"C:\Windows\Fonts\georgiab.ttf"
    font_size = 280
    font = ImageFont.truetype(font_path, font_size)

    text = "Q"
    # Calculate bounding box to center accurately
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]

    # Center position with slight visual offset for the Q's tail
    x = (size - text_w) / 2 - bbox[0] - 4
    y = (size - text_h) / 2 - bbox[1] - 12

    # Drop shadow for depth
    draw.text((x + 4, y + 6), text, font=font, fill=(5, 35, 20, 220))

    # Golden Q
    gold_color = (245, 218, 120, 255) # Light Radiant Gold
    draw.text((x, y), text, font=font, fill=gold_color)

    # 4. Save Master 512x512 Icon
    icon_dir = r"C:\All\works\Quran\assets\icon"
    os.makedirs(icon_dir, exist_ok=True)
    master_path = os.path.join(icon_dir, "app_icon.png")
    img.save(master_path, "PNG")
    print(f"Saved master icon: {master_path}")

    # 5. Export to Android Mipmap Folders
    mipmap_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    res_base = r"C:\All\works\Quran\android\app\src\main\res"
    for folder, dim in mipmap_sizes.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        resized_img = img.resize((dim, dim), Image.Resampling.LANCZOS)
        out_path = os.path.join(folder_path, "ic_launcher.png")
        resized_img.save(out_path, "PNG")
        print(f"Generated {dim}x{dim} -> {out_path}")

if __name__ == '__main__':
    create_q_logo()
