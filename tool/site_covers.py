#!/usr/bin/env python3
"""Makes the website's pack and set covers from the app's pack covers (app/assets/covers).

  python3 tool/site_covers.py

Writes strona/audiokiddo-strona/assets/img/site/okladka-{wyobraznia,slowa,detektyw,zestaw2,zestaw3}.webp
(720 x 720). The sets are a fan of the pack covers they contain.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "app/assets/covers"
OUT = ROOT / "strona/audiokiddo-strona/assets/img/site"
SIZE = 720
PACKS = {"wyobraznia": "pakiet-wyobraznia", "slowa": "pakiet-slowa-i-wiedza", "detektyw": "pakiet-detektyw"}


def load(name: str, size: int) -> Image.Image:
    return Image.open(SRC / f"{name}.jpg").convert("RGB").resize((size, size), Image.LANCZOS)


def rounded(im: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, im.size[0] - 1, im.size[1] - 1), radius, fill=255)
    out = im.convert("RGBA")
    out.putalpha(mask)
    return out


def fan(names: list[str], bg=(255, 241, 194)) -> Image.Image:
    """Covers side by side, slightly turned, the first at the back."""
    canvas = Image.new("RGBA", (SIZE, SIZE), bg + (255,))
    n = len(names)
    tile = int(SIZE * (0.62 if n == 2 else 0.54))
    angles = {2: [-7, 7], 3: [-9, 0, 9]}[n]
    centres = {2: [(0.34, 0.5), (0.66, 0.5)], 3: [(0.27, 0.56), (0.5, 0.44), (0.73, 0.56)]}[n]
    for name, angle, (cx, cy) in zip(names, angles, centres):
        card = rounded(load(name, tile), tile // 12)
        shadow = Image.new("RGBA", (tile + 60, tile + 60), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((30, 40, tile + 30, tile + 40), tile // 12, fill=(36, 27, 58, 90))
        shadow = shadow.filter(ImageFilter.GaussianBlur(14)).rotate(-angle, expand=True, resample=Image.BICUBIC)
        card = card.rotate(-angle, expand=True, resample=Image.BICUBIC)
        for layer in (shadow, card):
            canvas.alpha_composite(layer, (int(cx * SIZE - layer.size[0] / 2), int(cy * SIZE - layer.size[1] / 2)))
    return canvas.convert("RGB")


def save(im: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{name}.webp"
    im.save(path, "WEBP", quality=88, method=6)
    print(f"{path.relative_to(ROOT)} ({path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    for key, src in PACKS.items():
        save(load(src, SIZE), f"okladka-{key}")
    save(fan([PACKS["wyobraznia"], PACKS["slowa"]]), "okladka-zestaw2")
    save(fan([PACKS["wyobraznia"], PACKS["slowa"], PACKS["detektyw"]]), "okladka-zestaw3")
