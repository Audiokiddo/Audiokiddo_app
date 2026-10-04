#!/usr/bin/env python3
"""Shrinks a PDF by downsizing its oversized embedded images (print stays sharp).

Uses PyMuPDF (pip3 install --user pymupdf): pictures above ~200 dpi are resampled to 170 dpi
and re-encoded as JPEG; text and vector parts are untouched. An earlier pypdf version
corrupted some images (case-file puzzles vanished), so every page is now compared with
the original after shrinking and the original is kept if anything looks different.
    python3 tool/shrink_pdf.py in.pdf out.pdf
"""
import pathlib
import shutil
import sys

import fitz
from PIL import Image, ImageChops

DPI_TARGET = 170
QUALITY = 82


def _render(page):
    pix = page.get_pixmap(matrix=fitz.Matrix(.5, .5))
    return Image.frombytes("RGB", (pix.width, pix.height), pix.samples)


def shrink(source, target, quality: int = QUALITY) -> None:
    doc = fitz.open(str(source))
    doc.rewrite_images(dpi_threshold=DPI_TARGET + 30, dpi_target=DPI_TARGET, quality=quality)
    doc.save(str(target), garbage=3, deflate=True)
    original, shrunk = fitz.open(str(source)), fitz.open(str(target))
    changed = []
    for number, (a, b) in enumerate(zip(original, shrunk)):
        diff = ImageChops.difference(_render(a), _render(b)).convert("L").histogram()
        if sum(diff[40:]) > 0.002 * sum(diff):
            changed.append(number)
    if changed:
        # A page that looks different (e.g. a transparent picture) is taken whole from the original.
        for number in changed:
            shrunk.delete_page(number)
            shrunk.insert_pdf(original, from_page=number, to_page=number, start_at=number)
        repaired = str(target) + ".tmp"
        shrunk.save(repaired, garbage=3, deflate=True)
        shrunk.close()
        pathlib.Path(repaired).replace(target)
    # Never make a file bigger: when nothing was oversized the original is kept as it is.
    if pathlib.Path(target).stat().st_size >= pathlib.Path(source).stat().st_size:
        shutil.copyfile(source, target)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    shrink(sys.argv[1], sys.argv[2])
