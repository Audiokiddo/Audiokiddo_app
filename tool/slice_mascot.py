#!/usr/bin/env python3
"""Cuts the raccoon sticker sheet (poses on white) into separate transparent PNGs.
    python3 tool/slice_mascot.py sheet.jpg app/assets/szop
Rows and columns are split on fully white bands; the white around each pose (reached from
the edge) becomes transparent, the white inside (eyes, mug) stays."""
import sys
import pathlib
from PIL import Image, ImageDraw, ImageFilter

NAMES = ["zmeczony", "nasluchuje", "zestresowany", "zdziwiony", "chytry",
         "placze", "znudzony", "klaszcze", "zadowolony", "prosi"]


def bands(values, min_gap):
    """[(start, end)] of runs where values are True, merging gaps shorter than min_gap."""
    runs, start, gap = [], None, 0
    for i, v in enumerate(values + [False] * (min_gap + 1)):
        if v:
            if start is None:
                start = i
            gap = 0
        elif start is not None:
            gap += 1
            if gap > min_gap:
                runs.append((start, i - gap + 1))
                start, gap = None, 0
    return runs


def main(src, out):
    im = Image.open(src).convert("RGB")
    w, h = im.size
    px = im.load()
    ink = lambda x, y: min(px[x, y]) < 225
    rows = bands([any(ink(x, y) for x in range(0, w, 2)) for y in range(h)], 12)
    out = pathlib.Path(out)
    n = 0
    for top, bottom in rows:
        cols = bands([any(ink(x, y) for y in range(top, bottom, 2)) for x in range(w)], 40)
        for left, right in cols:
            if (right - left) * (bottom - top) < 4000:
                continue
            pad = 12
            box = (max(0, left - pad), max(0, top - pad), min(w, right + pad), min(h, bottom + pad))
            cell = im.crop(box)
            # Transparent outside: flood the near-white background from the corners.
            mask = Image.new("L", cell.size, 0)
            key = cell.copy()
            for corner in [(0, 0), (cell.width - 1, 0), (0, cell.height - 1), (cell.width - 1, cell.height - 1)]:
                ImageDraw.floodfill(key, corner, (255, 0, 255), thresh=40)
            kp = key.load()
            mp = mask.load()
            for y in range(cell.height):
                for x in range(cell.width):
                    mp[x, y] = 0 if kp[x, y] == (255, 0, 255) else 255
            # Soften the cut a little so it sits well on any background.
            mask = mask.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
            rgba = cell.convert("RGBA")
            rgba.putalpha(mask)
            # Upscale for sharp phones (flat cartoon art survives it well).
            rgba = rgba.resize((rgba.width * 2, rgba.height * 2), Image.LANCZOS)
            name = NAMES[n] if n < len(NAMES) else f"poza-{n + 1}"
            rgba.save(out / f"{name}.png", optimize=True)
            print(name, box, rgba.size)
            n += 1


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
