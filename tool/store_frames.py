#!/usr/bin/env python3
"""Store screenshots with captions, from the raw renders of tool/store_screens_test.dart.

    cd app && flutter test tool/store_screens_test.dart
    python3 tool/store_frames.py

Writes docs/sklepy/zrzuty/<size>/NN-name.jpg (JPEG, as both stores accept) for every size the stores ask for:
App Store iPhone 6.9" and 6.5", iPad 13", Google Play phone and 7"/10" tablet.
Needs PyMuPDF (pip3 install --user pymupdf). Captions are in CAPTIONS below.
"""
import pathlib

import pymupdf

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs/sklepy/zrzuty/surowe"
OUT = ROOT / "docs/sklepy/zrzuty"
FONTS = ROOT / "app/assets/fonts"

INK = (0x21 / 255, 0x1C / 255, 0x35 / 255)
WHITE = (1, 1, 1)


def rgb(h):
    return tuple(int(h[i : i + 2], 16) / 255 for i in (0, 2, 4))


# (raw name, headline, line under it, background, text colour)
CAPTIONS = [
    ("1-start", "Włącz, połóż telefon, odpocznij", "Audiozabawy bez ekranu dla dzieci 3–9 lat", rgb("FAC119"), INK),
    ("2-odtwarzacz", "Dziecko jest bohaterem przygody", "Słucha, szuka i odpowiada na głos", rgb("6B4C8A"), WHITE),
    ("3-biblioteka", "Wszystkie zabawy pod ręką", "Detektyw, Słowa i Wiedza, Wyobraźnia", rgb("B8E3DF"), INK),
    ("4-sytuacje", "Masz 20 minut? Dobierzemy zabawę", "Do czasu, nastroju i tego, co macie pod ręką", rgb("1D7478"), WHITE),
    ("5-podroz", "Cała podróż bez ekranu", "Zabawy i przerwy na wyglądanie przez okno", rgb("DED0EF"), INK),
    ("6-naklejki", "Naklejka za każdą przygodę", "Szop’en nagradza ukończone zabawy", rgb("FAC119"), INK),
    ("7-pakiet", "Zagadki Maxa i Mili", "Detektyw z aktami sprawy do rozwiązania", rgb("B8431C"), WHITE),
    ("8-pobrane", "Działa bez internetu", "W aucie, w samolocie i na działce", rgb("1D7478"), WHITE),
]

# (folder, width, height, raw device)
SIZES = [
    ("app-store-iphone-6.9", 1320, 2868, "phone"),
    ("app-store-iphone-6.5", 1284, 2778, "phone"),
    ("app-store-ipad-13", 2064, 2752, "tablet"),
    ("google-play-telefon", 1080, 1920, "phone"),
    ("google-play-tablet", 1600, 2560, "tablet"),
]


def frame(raw: pathlib.Path, title: str, sub: str, bg, fg, w: int, h: int) -> pymupdf.Pixmap:
    doc = pymupdf.open()
    page = doc.new_page(width=w, height=h)
    page.insert_font(fontname="PB", fontfile=str(FONTS / "Poppins-Bold.ttf"))
    page.insert_font(fontname="PR", fontfile=str(FONTS / "Poppins-Regular.ttf"))
    page.draw_rect(page.rect, color=None, fill=bg)

    # The caption: big headline, one smaller line, in the top fifth.
    margin = w * 0.07
    head = w * 0.075
    box = pymupdf.Rect(margin, h * 0.045, w - margin, h * 0.045 + head * 2.7)
    size = head
    # The largest size at which the headline fits in two lines.
    while page.insert_textbox(box, title, fontname="PB", fontsize=size, color=fg, align=pymupdf.TEXT_ALIGN_CENTER) < 0:
        size *= 0.94
    page.insert_textbox(
        pymupdf.Rect(margin, h * 0.045 + head * 2.6, w - margin, h * 0.045 + head * 2.6 + w * 0.09),
        sub, fontname="PR", fontsize=w * 0.038, color=fg, align=pymupdf.TEXT_ALIGN_CENTER,
    )

    # The phone: a dark bezel with the app screen, running off the bottom edge.
    img = pymupdf.Pixmap(str(raw))
    top = h * 0.045 + head * 2.6 + w * 0.12
    avail_h = h - top + h * 0.06  # bleeds past the bottom
    scale = min((w * 0.80) / img.width, avail_h / img.height)
    sw, sh = img.width * scale, img.height * scale
    pad = w * 0.022
    x0 = (w - sw) / 2
    bezel = pymupdf.Rect(x0 - pad, top - pad, x0 + sw + pad, top + sh + pad)
    page.draw_rect(bezel, color=None, fill=INK, radius=min(0.12, (w * 0.06) / bezel.width))
    page.insert_image(pymupdf.Rect(x0, top, x0 + sw, top + sh), pixmap=img)
    return page.get_pixmap(dpi=72, alpha=False)


def main() -> None:
    for folder, w, h, device in SIZES:
        out = OUT / folder
        out.mkdir(parents=True, exist_ok=True)
        for name, title, sub, bg, fg in CAPTIONS:
            raw = RAW / f"{device}-{name}.png"
            if not raw.exists():
                raise SystemExit(f"Brak {raw}. Najpierw: cd app && flutter test tool/store_screens_test.dart")
            pix = frame(raw, title, sub, bg, fg, w, h)
            assert (pix.width, pix.height) == (w, h), (folder, pix.width, pix.height)
            pix.save(out / f"{name}.jpg", jpg_quality=92)
        print(f"{folder}: {len(CAPTIONS)} zrzutów {w}×{h}")


if __name__ == "__main__":
    main()
