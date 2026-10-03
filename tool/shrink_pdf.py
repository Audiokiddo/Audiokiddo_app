#!/usr/bin/env python3
"""Shrinks a PDF by downsizing its oversized embedded images (print stays sharp).

Pictures wider than MAX_SIDE px are scaled down (A4 at ~190 dpi) and re-encoded; text and
vector parts are untouched. Case files from the designer weigh 13 MB, which is too much to
fetch over mobile data; this brings them to a few MB.
    python3 tool/shrink_pdf.py in.pdf out.pdf
"""
import pathlib
import shutil
import sys

from PIL import Image
from pypdf import PdfReader, PdfWriter

MAX_SIDE = 1800
QUALITY = 82


def shrink(source, target, max_side: int = MAX_SIDE, quality: int = QUALITY) -> None:
    writer = PdfWriter(clone_from=PdfReader(str(source)))
    for page in writer.pages:
        for image in page.images:
            picture = image.image
            if max(picture.size) <= max_side:
                continue
            scale = max_side / max(picture.size)
            size = (round(picture.width * scale), round(picture.height * scale))
            image.replace(picture.resize(size, Image.LANCZOS), quality=quality)
    writer.compress_identical_objects(remove_duplicates=True, remove_unreferenced=True)
    with open(target, "wb") as f:
        writer.write(f)
    # Never make a file bigger: when nothing was oversized the original is kept as it is.
    if pathlib.Path(target).stat().st_size >= pathlib.Path(source).stat().st_size:
        shutil.copyfile(source, target)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    shrink(sys.argv[1], sys.argv[2])
