#!/usr/bin/env python3
"""App icons from the Szop'en stickers (app/assets/szop): he climbs up from the bottom edge of
a mint-to-teal tile. Writes the iOS default icon, one alternate icon set per pose (chosen by
the parent in the app, Apple guideline 4.6), and the Android launcher icons.
    python3 tool/make_icons.py"""
import json
import pathlib
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
SZOP = ROOT / "app/assets/szop"
IOS = ROOT / "app/ios/Runner/Assets.xcassets"
RES = ROOT / "app/android/app/src/main/res"
DEFAULT = "prosi"
POSES = ["prosi", "zadowolony", "klaszcze", "chytry", "nasluchuje", "zdziwiony", "zestresowany",
         "zmeczony", "znudzony", "placze"]
TOP, BOTTOM = (205, 240, 234), (62, 173, 178)


def tile(size):
    bg = Image.new("RGB", (size, size))
    d = ImageDraw.Draw(bg)
    for y in range(size):
        t = y / (size - 1)
        d.line([(0, y), (size, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    # A soft sun behind his head.
    glow = Image.new("L", (size, size), 0)
    ImageDraw.Draw(glow).ellipse([size * .18, size * .08, size * .82, size * .72], fill=150)
    glow = glow.filter(ImageFilter.GaussianBlur(size * .08))
    bg.paste((255, 247, 220), mask=glow)
    return bg


def icon(pose, size=1024, fill=.9):
    bg = tile(size).convert("RGBA")
    art = Image.open(SZOP / f"{pose}.png").convert("RGBA")
    art = art.crop(art.getbbox())
    scale = min(size * fill / art.height, size * .96 / art.width)
    art = art.resize((round(art.width * scale), round(art.height * scale)), Image.LANCZOS)
    # Feet a little below the edge: he is peeking in from the bottom.
    x = (size - art.width) // 2
    y = size - art.height + round(size * .06)
    shadow = Image.new("RGBA", art.size, (20, 40, 40, 0))
    shadow.putalpha(art.getchannel("A").point(lambda a: a * .35))
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * .012))
    bg.alpha_composite(shadow, (x, y + round(size * .012)))
    bg.alpha_composite(art, (x, y))
    return bg.convert("RGB")


def ios_set(name, image):
    folder = IOS / f"{name}.appiconset"
    folder.mkdir(exist_ok=True)
    for old in folder.glob("*.png"):
        old.unlink()
    image.save(folder / "icon-1024.png", optimize=True)
    (folder / "Contents.json").write_text(json.dumps({
        "images": [{"filename": "icon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")


def android(image):
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, px in sizes.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(exist_ok=True)
        image.resize((px, px), Image.LANCZOS).save(folder / "ic_launcher.png", optimize=True)
        # Round launchers get the same art in a circle.
        mask = Image.new("L", (px * 4, px * 4), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, px * 4, px * 4], fill=255)
        rnd = image.resize((px, px), Image.LANCZOS).convert("RGBA")
        rnd.putalpha(mask.resize((px, px), Image.LANCZOS))
        rnd.save(folder / "ic_launcher_round.png", optimize=True)


def main():
    ios_set("AppIcon", icon(DEFAULT))
    for pose in POSES:
        ios_set(f"AppIcon-{pose}", icon(pose))
        icon(pose, 240).save(ROOT / f"app/assets/szop/ikona-{pose}.png", optimize=True)
    android(icon(DEFAULT, 512))
    print("icons:", ", ".join(POSES))


if __name__ == "__main__":
    main()
