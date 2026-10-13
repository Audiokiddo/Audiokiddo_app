#!/usr/bin/env python3
"""Hero and social images with Szop'en (he replaced Max i Mila on the site).

    python3 strona/grafika/szop_hero.py
writes assets/img/site/hero.webp (1200x776, transparent) and assets/img/site/og.jpg (1200x630).
"""
import pathlib
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2]
SZOP = ROOT / "app/assets/szop"
OUT = ROOT / "strona/audiokiddo-strona/assets/img/site"
FONT = ROOT / "strona/audiokiddo-strona/assets/fonts/Poppins-Bold.ttf"
SUN, TEAL, LAV, CREAM, INK = (250, 193, 25), (58, 175, 176), (169, 142, 193), (255, 251, 242), (29, 26, 43)


def blob(draw, cx, cy, r, color):
    for dx, dy, k in [(0, 0, 1), (-0.55, 0.18, .72), (0.55, 0.12, .78), (-0.2, -0.45, .66), (0.3, -0.38, .7)]:
        rr = r * k
        x, y = cx + dx * r, cy + dy * r
        draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color)


def hero():
    W, H = 1200, 776
    bg = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(bg)
    blob(d, 455, 560, 210, TEAL + (255,))
    blob(d, 770, 520, 245, SUN + (255,))
    d.ellipse([890, 170, 960, 240], fill=LAV + (255,))
    d.ellipse([250, 250, 290, 290], fill=SUN + (255,))
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse([380, 700, 840, 760], fill=(29, 26, 43, 70))
    bg = Image.alpha_composite(bg, shadow.filter(ImageFilter.GaussianBlur(14)))
    szop = Image.open(SZOP / "zadowolony.png").convert("RGBA")
    scale = 700 / szop.height
    szop = szop.resize((int(szop.width * scale), 700), Image.LANCZOS)
    bg.alpha_composite(szop, ((W - szop.width) // 2 + 10, H - szop.height - 36))
    bg.save(OUT / "hero.webp", "WEBP", quality=88)


def og():
    W, H = 1200, 630
    im = Image.new("RGB", (W, H), CREAM)
    d = ImageDraw.Draw(im, "RGBA")
    blob(d, 980, 480, 210, SUN + (255,))
    szop = Image.open(SZOP / "chytry.png").convert("RGBA")
    scale = 470 / szop.height
    szop = szop.resize((int(szop.width * scale), 470), Image.LANCZOS)
    im.paste(szop, (W - szop.width + 20, H - szop.height - 20), szop)
    big = ImageFont.truetype(str(FONT), 54)
    small = ImageFont.truetype(str(FONT), 30)
    y = 120
    for line in ["Dziecko potrzebuje", "zajęcia. Ty nie", "musisz go wymyślać."]:
        d.text((70, y), line, font=big, fill=INK)
        y += 74
    d.rounded_rectangle([70, y + 30, 70 + d.textlength("audiokiddo.pl", font=small) + 48, y + 92], 30, fill=SUN + (255,))
    d.text((94, y + 42), "audiokiddo.pl", font=small, fill=INK)
    d.text((70, 52), "AUDIOKIDDO · AUDIOZABAWY 3–9 LAT", font=ImageFont.truetype(str(FONT), 22), fill=(29, 116, 120))
    im.save(OUT / "og.jpg", "JPEG", quality=88)


if __name__ == "__main__":
    hero()
    og()
    print("ok")


DEEP = {"lav": (107, 76, 138), "teal": (29, 116, 120), "sun": (138, 98, 0)}
SOFT = {"lav": (241, 226, 253), "teal": (210, 236, 237), "sun": (255, 241, 194)}
MAIN = {"lav": LAV, "teal": TEAL, "sun": SUN}
PACKS = [
    ("okladka-wyobraznia", "lav", "klaszcze", "WYOBRAŹNIA", "10 zabaw · od 4 lat"),
    ("okladka-slowa", "teal", "nasluchuje", "SŁOWA I WIEDZA", "10 zabaw · od 4 lat"),
    ("okladka-detektyw", "sun", "chytry", "DETEKTYW", "5 spraw · od 7 lat"),
]


def font(size):
    return ImageFont.truetype(str(FONT), size)


def cover(name, color, pose, title, sub, size=720):
    im = Image.new("RGB", (size, size), SOFT[color])
    d = ImageDraw.Draw(im, "RGBA")
    blob(d, size * .6, size * .4, size * .27, MAIN[color] + (255,))
    szop = Image.open(SZOP / f"{pose}.png").convert("RGBA")
    h = int(size * .5)
    szop = szop.resize((int(szop.width * h / szop.height), h), Image.LANCZOS)
    im.paste(szop, (int(size * .93) - szop.width, int(size * .63) - szop.height), szop)
    d.text((size * .07, size * .07), "AUDIOKIDDO", font=font(int(size * .045)), fill=DEEP[color])
    d.text((size * .07, size * .66), "Pakiet", font=font(int(size * .05)), fill=INK)
    t = font(int(size * .085))
    while d.textlength(title, font=t) > size * .86:
        t = font(t.size - 2)
    d.text((size * .07, size * .72), title, font=t, fill=INK)
    sf = font(int(size * .04))
    w = d.textlength(sub, font=sf)
    d.rounded_rectangle([size * .07, size * .85, size * .07 + w + size * .06, size * .92], radius=size * .035, fill=(255, 255, 255, 235))
    d.text((size * .1, size * .862), sub, font=sf, fill=DEEP[color])
    return im


def covers():
    made = {}
    for name, color, pose, title, sub in PACKS:
        im = cover(name, color, pose, title, sub)
        im.save(OUT / f"{name}.webp", "WEBP", quality=88)
        im.save(ROOT / f"strona/grafika/{name}.jpg", "JPEG", quality=90)
        made[name] = im
    for name, title, keys in [("okladka-zestaw2", "ZESTAW DWÓCH", ["okladka-wyobraznia", "okladka-slowa"]),
                              ("okladka-zestaw3", "ZESTAW TRZECH", ["okladka-wyobraznia", "okladka-slowa", "okladka-detektyw"])]:
        im = Image.new("RGB", (720, 720), CREAM)
        d = ImageDraw.Draw(im, "RGBA")
        d.text((50, 50), "AUDIOKIDDO", font=font(32), fill=(29, 116, 120))
        d.text((50, 110), title, font=font(64), fill=INK)
        d.text((50, 190), f"{len(keys)} pakiety taniej razem", font=font(28), fill=(98, 92, 112))
        n = len(keys)
        tile = 300 if n == 2 else 205
        gap = 30 if n == 2 else 20
        x0 = (720 - (n * tile + (n - 1) * gap)) // 2
        for i, k in enumerate(keys):
            t = made[k].resize((tile, tile), Image.LANCZOS)
            shadow = Image.new("RGBA", (tile + 40, tile + 40), (0, 0, 0, 0))
            ImageDraw.Draw(shadow).rounded_rectangle([20, 26, tile + 20, tile + 26], 24, fill=(29, 26, 43, 60))
            shadow = shadow.filter(ImageFilter.GaussianBlur(10))
            im.paste(shadow, (x0 + i * (tile + gap) - 20, 300 - 20), shadow)
            mask = Image.new("L", (tile, tile), 0)
            ImageDraw.Draw(mask).rounded_rectangle([0, 0, tile, tile], 24, fill=255)
            im.paste(t, (x0 + i * (tile + gap), 300), mask)
        im.save(OUT / f"{name}.webp", "WEBP", quality=88)
        im.save(ROOT / f"strona/grafika/{name}.jpg", "JPEG", quality=90)
    # The free pack picture (newsletter): Szop'en with a gift.
    im = Image.new("RGB", (1100, 619), SOFT["sun"])
    d = ImageDraw.Draw(im, "RGBA")
    blob(d, 800, 400, 210, SUN + (255,))
    szop = Image.open(SZOP / "prosi.png").convert("RGBA")
    szop = szop.resize((int(szop.width * 440 / szop.height), 440), Image.LANCZOS)
    im.paste(szop, (1070 - szop.width, 600 - szop.height), szop)
    d.text((70, 70), "AUDIOKIDDO", font=font(30), fill=(138, 98, 0))
    d.text((70, 150), "Darmowy pakiet", font=font(62), fill=INK)
    d.text((70, 240), "3 audiozabawy", font=font(44), fill=INK)
    d.text((70, 300), "+ karty zabaw do druku", font=font(36), fill=(98, 92, 112))
    im.save(OUT / "darmowy-pakiet.webp", "WEBP", quality=88)


if __name__ == "__main__":
    covers()
    print("covers ok")
