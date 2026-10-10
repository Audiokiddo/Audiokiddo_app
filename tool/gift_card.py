#!/usr/bin/env python3
"""Printable AudioKiddo gift card (A4 landscape, folds into an A5 card) with Szop'en.

    python3 tool/gift_card.py                                  # blank card: the code is written by hand
    python3 tool/gift_card.py --code AK-7K3M-9QXD --to "Zosi" --from "Babci i Dziadka" \\
        --gift "Wszystkie zabawy na rok" -o ~/Desktop/kartka-zosia.pdf

Needs PyMuPDF (pip3 install --user pymupdf). Fonts and stickers come from the app's assets.
"""
import argparse
import pathlib

import pymupdf

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "app/assets"
INK = (0x21 / 255, 0x1C / 255, 0x35 / 255)
TEAL = (0x1D / 255, 0x74 / 255, 0x78 / 255)
SUN = (0xFF / 255, 0xD1 / 255, 0x66 / 255)
CREAM = (0xFF / 255, 0xFB / 255, 0xF2 / 255)
MUTED = (0.42, 0.40, 0.48)


def card(code: str | None, to: str | None, sender: str | None, gift: str) -> pymupdf.Document:
    doc = pymupdf.open()
    w, h = pymupdf.paper_size("a4-l")
    page = doc.new_page(width=w, height=h)
    for name in ("Regular", "SemiBold", "Bold"):
        page.insert_font(fontname=f"P{name[0]}", fontfile=str(ASSETS / f"fonts/Poppins-{name}.ttf"))
    half = w / 2
    page.draw_rect(page.rect, color=None, fill=CREAM)
    # Fold line, faint: left half is the back, right half the front.
    page.draw_line((half, 20), (half, h - 20), color=(0.85, 0.83, 0.8), dashes="[4 6] 0", width=0.6)

    def text(rect, s, size, font="PR", color=INK, align=pymupdf.TEXT_ALIGN_CENTER):
        page.insert_textbox(pymupdf.Rect(*rect), s, fontsize=size, fontname=font, color=color, align=align)

    # Front (right half): Szop'en, the gift and who it is for.
    page.draw_rect(pymupdf.Rect(half + 30, 30, w - 30, h - 30), color=None, fill=SUN, radius=0.06)
    page.insert_image(pymupdf.Rect(half + 120, 60, w - 120, 300), filename=str(ASSETS / "szop/zadowolony.png"), keep_proportion=True)
    text((half + 40, 295, w - 40, 360), "Prezent", 30, "PB")
    text((half + 40, 360, w - 40, 405), gift, 16, "PS")
    text((half + 40, 408, w - 40, 435), f"dla {to}" if to else "dla ........................................", 14)
    text((half + 40, 438, w - 40, 468), f"od {sender}" if sender else "od ........................................", 14)
    text((half + 40, 500, w - 40, 540), "AUDIOKIDDO · audiozabawy bez ekranu", 11, "PS", TEAL)

    # Back (left half): the code and how to use it, for the parent.
    text((40, 50, half - 40, 90), "Jak odebrać prezent", 20, "PB")
    page.draw_rect(pymupdf.Rect(70, 105, half - 70, 175), color=TEAL, fill=(1, 1, 1), width=2, radius=0.15)
    text((70, 112, half - 70, 132), "Kod prezentowy", 10, "PR", MUTED)
    text((70, 130, half - 70, 172), code or "AK-____-____", 24, "PB", TEAL)
    steps = [
        "1. Pobierz aplikację AudioKiddo z App Store albo Google Play.",
        "2. Wejdź w Sklep › „Masz już dostęp z audiokiddo.pl?” › „Mam kod”.",
        "3. Wpisz kod. Zabawy od razu są Wasze, także bez internetu po pobraniu.",
    ]
    text((60, 195, half - 60, 345), "\n".join(steps), 12, "PR", INK, pymupdf.TEXT_ALIGN_LEFT)
    text(
        (60, 355, half - 60, 440),
        "AudioKiddo to interaktywne audiozabawy dla dzieci 3–9 lat: dziecko słucha, szuka, "
        "zgaduje i odpowiada, a rodzic ma chwilę dla siebie. Bez ekranu i bez reklam.",
        11, "PR", MUTED, pymupdf.TEXT_ALIGN_LEFT,
    )
    page.insert_image(pymupdf.Rect(60, 440, 140, 540), filename=str(ASSETS / "szop/klaszcze.png"), keep_proportion=True)
    text((150, 470, half - 60, 530), "Pytania? kontakt@audiokiddo.pl\naudiokiddo.pl", 11, "PR", TEAL, pymupdf.TEXT_ALIGN_LEFT)
    return doc


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--code", help="the access code (AK-XXXX-XXXX); empty card when left out")
    ap.add_argument("--to", help="who gets it, e.g. 'Zosi'")
    ap.add_argument("--from", dest="sender", help="who gives it, e.g. 'Babcia i Dziadek'")
    ap.add_argument("--gift", default="Audiozabawy AudioKiddo", help="what the gift is")
    ap.add_argument("-o", "--out", default=str(ROOT / "docs/marketing/prezent/kartka-prezentowa.pdf"))
    a = ap.parse_args()
    out = pathlib.Path(a.out).expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)
    card(a.code, a.to, a.sender, a.gift).save(out, garbage=4, deflate=True)
    print(out)


if __name__ == "__main__":
    main()
