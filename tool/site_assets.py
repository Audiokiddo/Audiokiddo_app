#!/usr/bin/env python3
"""Copies and shrinks the app's art for the website plugin (strona/audiokiddo-strona/assets).

Covers and Szop'en become small WebP files, the guide's first page becomes a mockup image,
fonts and three short previews are copied. Run again after new covers: python3 tool/site_assets.py
"""
import pathlib
import shutil

import fitz
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "strona" / "audiokiddo-strona" / "assets"
APP = ROOT / "app" / "assets"


def webp(src: pathlib.Path, dst: pathlib.Path, width: int, quality: int = 80) -> None:
    img = Image.open(src)
    img = img.convert("RGBA" if img.mode in ("RGBA", "LA", "P") else "RGB")
    if img.width > width:
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "WEBP", quality=quality, method=6)


def main() -> None:
    for cover in sorted((APP / "covers").glob("*.jpg")):
        webp(cover, OUT / "img" / "covers" / f"{cover.stem}.webp", 520)
    for mood in ("nasluchuje", "zadowolony", "klaszcze", "zdziwiony", "chytry", "prosi"):
        webp(APP / "szop" / f"{mood}.png", OUT / "img" / "szop" / f"{mood}.webp", 420, 85)
    shutil.copy(APP / "brand" / "logo.png", OUT / "img" / "logo.png")

    # The guide's cover for the sign-up section.
    doc = fitz.open(ROOT / "docs" / "marketing" / "podroz-bez-ekranu.pdf")
    pix = doc[0].get_pixmap(dpi=110)
    tmp = OUT / "img" / "przewodnik.png"
    pix.save(tmp)
    webp(tmp, OUT / "img" / "przewodnik.webp", 520, 82)
    tmp.unlink()

    (OUT / "fonts").mkdir(parents=True, exist_ok=True)
    for weight in ("Regular", "Medium", "SemiBold", "Bold"):
        shutil.copy(APP / "fonts" / f"Poppins-{weight}.ttf", OUT / "fonts" / f"Poppins-{weight}.ttf")

    previews = ROOT / "dev_content" / "previews"
    (OUT / "audio").mkdir(parents=True, exist_ok=True)
    for pack, play in (("wyobraznia", "magiczny-teatr"), ("slowa-i-wiedza", "co-to-za-przedmiot"),
                       ("detektyw", "znikajace-dzwonki")):
        shutil.copy(previews / pack / f"{play}.m4a", OUT / "audio" / f"{pack}.m4a")


if __name__ == "__main__":
    main()
