# Composes the App Store screenshots (2880x1800). Run via make.sh.
import math, os, subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter
W, H = 2880, 1800
R = os.environ['RENDERER']
TMP = os.environ['TMPDIR_RENDER']

def font(size, weight):
    f = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', size)
    f.set_variation_by_name(weight)
    return f

def gradient(top, bottom):
    g = Image.new('RGBA', (1, H))
    for y in range(H):
        t = y / (H - 1)
        g.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return g.resize((W, H))

def eyes(img, style, center, cursor, scale, name):
    """Render the app's real EyeballView looking at `cursor`, centered at `center`."""
    ang = math.degrees(math.atan2(center[1] - cursor[1], cursor[0] - center[0]))
    out = f'{TMP}/{name}.png'
    subprocess.run([R, style, str(ang), str(scale), out], check=True)
    e = Image.open(out)
    img.alpha_composite(e, (int(center[0] - e.width / 2), int(center[1] - e.height / 2)))

ARROW = [(0, 0), (0, 21), (5, 16.2), (8.6, 24), (11.8, 22.6), (8.3, 15), (15, 15)]
def cursor(img, tip, k):
    pts = [(tip[0] + x * k, tip[1] + y * k) for x, y in ARROW]
    sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon([(x + k * .6, y + k * 1.2) for x, y in pts], fill=(0, 0, 0, 110))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(k * 1.2)))
    ImageDraw.Draw(img).polygon(pts, fill='black', outline='white', width=max(2, int(k * 1.3)))

def menubar(img, box, alpha=70, dark=False, clock=None, clock_size=0):
    layer = Image.new('RGBA', img.size, (0, 0, 0, 0))
    c = (0, 0, 0, alpha) if dark else (255, 255, 255, alpha)
    ImageDraw.Draw(layer).rectangle(box, fill=c)
    img.alpha_composite(layer)
    if clock:
        d = ImageDraw.Draw(img)
        f = font(clock_size, 'Medium')
        w = d.textlength(clock, font=f)
        d.text((box[2] - w - clock_size * 0.8, (box[1] + box[3]) / 2), clock, font=f,
               fill=(255, 255, 255, 235), anchor='lm')

def text(img, xy, s, size, weight, fill=(255, 255, 255, 255), anchor='mm'):
    ImageDraw.Draw(img).text(xy, s, font=font(size, weight), fill=fill, anchor=anchor)

# 1: Googly eyes follow the cursor
img = gradient((74, 118, 214), (150, 92, 196))
menubar(img, (0, 0, W, 230), clock='Sat 9:41 AM', clock_size=64)
eye_c, cur = (1880, 115), (560, 1380)
eyes(img, 'googly', eye_c, cur, 10, 'e1')
text(img, (W / 2 + 200, 760), 'They watch your cursor.', 150, 'Bold')
text(img, (W / 2 + 200, 930), 'Googly eyes that live in your menu bar.', 76, 'Regular', (255, 255, 255, 220))
cursor(img, cur, 9)
img.convert('RGB').save('1-follow.png')

# 2: Every display gets its own pair
img = gradient((40, 150, 170), (60, 90, 190))
text(img, (W / 2, 250), 'Every display gets its own pair.', 140, 'Bold')
text(img, (W / 2, 410), 'Each set of eyes looks from where it sits.', 76, 'Regular', (255, 255, 255, 220))
d = ImageDraw.Draw(img)
monitors = [(180, 600, 1360, 1340), (1520, 600, 2700, 1340)]
for x0, y0, x1, y1 in monitors:
    d.rounded_rectangle((x0 + (x1 - x0) / 2 - 90, y1, x0 + (x1 - x0) / 2 + 90, y1 + 150), 12, fill=(200, 205, 215))
    d.rounded_rectangle((x0 + (x1 - x0) / 2 - 240, y1 + 140, x0 + (x1 - x0) / 2 + 240, y1 + 175), 14, fill=(215, 220, 228))
    d.rounded_rectangle((x0 - 26, y0 - 26, x1 + 26, y1 + 26), 40, fill=(28, 28, 32))
    screen = Image.new('RGBA', (x1 - x0, y1 - y0))
    screen.paste(gradient((95, 140, 225), (165, 110, 205)).resize((x1 - x0, y1 - y0)))
    img.paste(screen, (x0, y0))
    menubar(img, (x0, y0, x1, y0 + 80), clock='9:41', clock_size=38)
cur = (1720, 1120)
for i, (x0, y0, x1, y1) in enumerate(monitors):
    eyes(img, 'googly', (x1 - 300, y0 + 40), cur, 5, f'e2{i}')
cursor(img, cur, 6)
img.convert('RGB').save('2-displays.png')

# 3: The lidless eye
img = gradient((22, 8, 6), (95, 22, 6))
glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
ImageDraw.Draw(glow).ellipse((900, 1100, 2700, 2300), fill=(255, 90, 10, 70))
img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(220)))
menubar(img, (0, 0, W, 230), alpha=110, dark=True, clock='Sat 9:41 AM', clock_size=64)
eye_c, cur = (1880, 115), (2350, 1300)
eyes(img, 'sauron', eye_c, cur, 11, 'e3')
text(img, (W / 2 - 250, 760), 'Or summon the lidless eye.', 150, 'Bold', (255, 236, 200, 255))
text(img, (W / 2 - 250, 930), 'One fiery eye. It never blinks.', 76, 'Regular', (255, 220, 180, 220))
cursor(img, cur, 9)
img.convert('RGB').save('3-lidless.png')
