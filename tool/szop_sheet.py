#!/usr/bin/env python3
"""Cuts Szop'en's poses for "Dzień z Audiokiddo" out of the sheet (4 x 4 on black).

  python3 tool/szop_sheet.py

Reads app/assets/szop/"Warm brown outlined raccoon sheet.png" and writes
strona/audiokiddo-strona/assets/img/szop/dzien-<moment>.webp with the black around each pose
made transparent (the black is removed from the cell's edges inwards, so dark outlines stay).
"""
from collections import deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SHEET = ROOT / "app/assets/szop/Warm brown outlined raccoon sheet.png"
OUT = ROOT / "strona/audiokiddo-strona/assets/img/szop"
# moment -> (row, column) on the sheet, counted from 0
POSES = {
    "auto": (1, 0),        # sure of himself: "mam zabawy na całą trasę"
    "przedszkole": (1, 3),  # out of battery
    "obiad": (3, 3),       # a wink and a shrug: "nikt nie płacze"
    "zero-mocy": (3, 2),   # no strength left
    "sen": (2, 0),         # happy, eyes closed
    "nuda": (1, 1),        # thinking it over
}
DARK = 26  # a pixel this dark on every channel counts as the black background


def cut(sheet: Image.Image, row: int, col: int) -> Image.Image:
    w, h = sheet.size[0] / 4, sheet.size[1] / 4
    cell = sheet.crop((round(col * w), round(row * h), round((col + 1) * w), round((row + 1) * h))).convert("RGBA")
    px = cell.load()
    cw, ch = cell.size
    seen = [[False] * cw for _ in range(ch)]
    queue = deque([(x, y) for x in range(cw) for y in (0, ch - 1)] + [(x, y) for y in range(ch) for x in (0, cw - 1)])
    while queue:
        x, y = queue.popleft()
        if not (0 <= x < cw and 0 <= y < ch) or seen[y][x]:
            continue
        seen[y][x] = True
        r, g, b, _ = px[x, y]
        if max(r, g, b) > DARK:
            continue
        px[x, y] = (0, 0, 0, 0)
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    # Bits of the neighbouring poses reach into the cell: keep only the biggest island.
    label = [[0] * cw for _ in range(ch)]
    sizes = {}
    for sy in range(ch):
        for sx in range(cw):
            if label[sy][sx] or px[sx, sy][3] == 0:
                continue
            n = len(sizes) + 1
            count = 0
            queue = deque([(sx, sy)])
            label[sy][sx] = n
            while queue:
                x, y = queue.popleft()
                count += 1
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < cw and 0 <= ny < ch and not label[ny][nx] and px[nx, ny][3]:
                        label[ny][nx] = n
                        queue.append((nx, ny))
            sizes[n] = count
    keep = max(sizes, key=sizes.get)
    for y in range(ch):
        for x in range(cw):
            if label[y][x] != keep:
                px[x, y] = (0, 0, 0, 0)
    box = cell.getbbox()
    return cell.crop(box) if box else cell


if __name__ == "__main__":
    sheet = Image.open(SHEET).convert("RGB")
    for name, (row, col) in POSES.items():
        pose = cut(sheet, row, col)
        path = OUT / f"dzien-{name}.webp"
        pose.save(path, "WEBP", quality=90, method=6)
        print(f"{path.relative_to(ROOT)} {pose.size} ({path.stat().st_size // 1024} KB)")
