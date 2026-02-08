#!/usr/bin/env python3
"""Generate PLACEHOLDER-DSHMC-REPLACE-WITH-CONTROLAPP.png for docs."""
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Run: pip install Pillow")
    raise

W, H = 640, 360
img = Image.new("RGB", (W, H), color=(255, 250, 205))  # light yellow
draw = ImageDraw.Draw(img)

# Try a built-in font; fallback to default
try:
    font = ImageFont.truetype("arial.ttf", 22)
except OSError:
    font = ImageFont.load_default()

text = "TODO: Replace with ControlApp screenshot\n(was DSHMC.exe)"
# Pillow 8+: textbbox; older: use getbbox or approximate
try:
    bbox = draw.textbbox((0, 0), text, font=font)
except AttributeError:
    bbox = draw.textsize(text, font=font)
    bbox = (0, 0, bbox[0], bbox[1])
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
xy = ((W - tw) // 2, (H - th) // 2)
draw.rectangle([xy[0] - 8, xy[1] - 8, xy[0] + tw + 8, xy[1] + th + 8], outline=(180, 160, 80), width=2)
draw.text(xy, text, fill=(80, 60, 40), font=font)

out = __file__.replace("generate_placeholder.py", "PLACEHOLDER-DSHMC-REPLACE-WITH-CONTROLAPP.png")
img.save(out)
print("Saved:", out)
