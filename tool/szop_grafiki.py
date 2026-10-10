#!/usr/bin/env python3
"""Szop'en's drawings for the website, from app/assets/szop/audiokiddo-szop-12-grafik.

  python3 tool/szop_grafiki.py

Each drawing is trimmed to its figure and saved as WebP (at most 760 px on the longer side) in
strona/audiokiddo-strona/assets/img/szop/. The ones that lean out of an edge keep that edge flush,
so they can sit against the side or the bottom of a section without a gap.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "app/assets/szop/audiokiddo-szop-12-grafik"
OUT = ROOT / "strona/audiokiddo-strona/assets/img/szop"
MAX = 760
FILES = {
    "01-hero-mikrofon.png": "mikrofon",
    "02-wychyla-sie-z-prawej.png": "zza-prawej",
    "exec-19107202-f69c-4526-95ba-bb041fc487b8.png": "zza-lewej",
    "04-wychyla-sie-od-dolu.png": "zza-dolu",
    "05-kupujesz-raz.png": "prezent",
    "06-jak-to-dziala.png": "sluchawki",
    "07-samochod.png": "dzien-auto",
    "08-po-przedszkolu.png": "dzien-przedszkole",
    "09-obiad.png": "dzien-obiad",
    "10-zero-mocy.png": "dzien-zero-mocy",
    "11-przed-snem.png": "dzien-sen",
    "12-nudzi-mi-sie.png": "dzien-nuda",
}

if __name__ == "__main__":
    for src, name in FILES.items():
        im = Image.open(SRC / src).convert("RGBA")
        box = im.split()[3].point(lambda a: 255 if a > 8 else 0).getbbox()
        im = im.crop(box)
        im.thumbnail((MAX, MAX), Image.LANCZOS)
        path = OUT / f"{name}.webp"
        im.save(path, "WEBP", quality=90, method=6)
        print(f"{name}.webp {im.size} ({path.stat().st_size // 1024} KB)")
