#!/usr/bin/env python3
"""Turns the photos and drawings from the first audiokiddo.pl (strona/stare-zasoby) into small
WebP files for the website plugin (strona/audiokiddo-strona/assets/img/site).

Our photos, the specialists, the hero with Max and Mila, the pack covers, the icons, the posters
of the children's videos and the parents' avatars cut out of the review cards.
Run again after a new photo: python3 tool/site_old_assets.py
"""
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "strona" / "stare-zasoby"
OUT = ROOT / "strona" / "audiokiddo-strona" / "assets" / "img" / "site"


def load(name: str) -> Image.Image:
    img = Image.open(SRC / name)
    return img.convert("RGBA" if img.mode in ("RGBA", "LA", "P") else "RGB")


def save(img: Image.Image, name: str, width: int, quality: int = 82) -> None:
    if img.width > width:
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / f"{name}.webp", "WEBP", quality=quality, method=6)


def trim(img: Image.Image) -> Image.Image:
    """Cuts the empty, see-through margin around a drawing."""
    box = img.split()[3].getbbox() if img.mode == "RGBA" else None
    return img.crop(box) if box else img


def main() -> None:
    # Max and Mila with the clouds, for the hero.
    save(trim(load("2025_03_Projekt-bez-nazwy-35.png")), "hero", 1200, 84)

    # Nela and Dawid: the photo on the coloured card with the drawn heart, the name beside it rubbed out.
    for src, name, left, text in (("2025_02_Bez-nazwy-800-x-400-px-1.png", "nela", 262, (0, 140, 280, 235)),
                                  ("2025_02_Bez-nazwy-800-x-400-px-2.png", "dawid", 278, (0, 150, 306, 235))):
        img = load(src)
        img.paste((0, 0, 0, 0), text)
        save(trim(img.crop((left, 0, img.width, img.height))), name, 640, 86)

    # The specialists.
    save(trim(load("2025_04_julia-800-x-800-px-6.png")), "kasielska", 560, 86)
    save(trim(load("2025_04_julia-800-x-800-px-7.png")), "lewandowska", 560, 86)

    # Pack covers.
    for src, name in (("2025_03_Okladki-pakietow.jpg", "okladka-wyobraznia"),
                      ("2025_03_Okladki-pakietow-1.jpg", "okladka-slowa"),
                      ("2025_03_Okladki-pakietow_Strona.jpg", "okladka-detektyw"),
                      ("2025_03_Okladki-pakietow_Strona-3.jpg", "okladka-zestaw2"),
                      ("2025_03_Okladki-pakietow_Strona-4.jpg", "okladka-zestaw3")):
        save(load(src), name, 720)

    # The free pack (newsletter).
    save(load("2025_03_Naglowek-1.jpg"), "darmowy-pakiet", 1100)

    # What the child does while listening (coloured circles).
    for src, name in (("2025_07_Slucha-3.png", "i-slucha"), ("2025_07_Slucha-1.png", "i-odpowiada"),
                      ("2025_07_Slucha3.png", "i-zadania"), ("2025_07_Slucha-2.png", "i-wiedza")):
        save(trim(load(src)), name, 240, 88)

    # Why parents choose us (line drawings).
    for src, name in (("2025_07_Projekt-bez-nazwy-22.png", "w-bezpieczne"), ("2025_07_7.png", "w-wyobraznia"),
                      ("2025_07_10.png", "w-pedagodzy"), ("2025_07_11.png", "w-natychmiast"),
                      ("2025_07_12.png", "w-wszedzie"), ("2025_07_8.png", "w-odpoczynek")):
        save(trim(load(src)), name, 200, 88)

    # White line drawings for the dark products section.
    for src, name in (("2025_07_Projekt-bez-nazwy-24.png", "d-bez-ekranow"), ("2025_07_Projekt-bez-nazwy-23.png", "d-podroz"),
                      ("2025_07_Projekt-bez-nazwy-25.png", "d-druk")):
        save(trim(load(src)), name, 160, 88)

    # Posters of the children's videos.
    for src, name in (("2025_07_Projekt-bez-nazwy-16.jpg", "wideo-pilka"), ("2025_07_Projekt-bez-nazwy-14.jpg", "wideo-planeta"),
                      ("2025_07_Projekt-bez-nazwy-15.jpg", "wideo-drzewo")):
        save(load(src), name, 720, 78)

    # Parents' avatars from the review cards (the photo in the pill, top left).
    for i, name in enumerate(("laura", "agata-tosia", "ewelina", "agata-stas", "pam"), start=1):
        card = load(f"2025_05_{i}-2-1024x1024.jpg").convert("RGBA")
        face = card.crop((97, 104, 189, 196)).resize((112, 112), Image.LANCZOS)
        mask = Image.new("L", face.size, 0)
        ImageDraw.Draw(mask).ellipse((0, 0, face.width - 1, face.height - 1), fill=255)
        face.putalpha(mask)
        save(face, f"rodzic-{name}", 112, 86)


if __name__ == "__main__":
    main()
