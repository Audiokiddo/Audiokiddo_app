#!/usr/bin/env python3
"""Imports cover images into the app and keeps docs/OKLADKI.md up to date.

Source folder (default ../AudioKiddo-materialy/okladki): one image per play or per pack,
JPG/PNG/WebP, any size (square 1080x1080 is ideal). A file belongs to the play whose title or
id appears in its file name, ignoring case, Polish letters, spaces and punctuation:
    "Znikające dzwonki rowerowe.jpg", "znikajace-dzwonki.png", "Max i Mila - Gadający śmietnik.jpg"
A file with "pakiet" in its name is the cover of the pack whose title or id it names:
    "Pakiet Detektyw.jpg", "Pakiet Słowa i wiedza.png"
Each image is centre-cropped to a square and saved as app/assets/covers/<id>.jpg (plays) or
pakiet-<id>.jpg (packs), 900 px, JPEG q80, about 100-150 KB; the app shows it instead of the
drawn placeholder.
    python3 tool/import_covers.py [folder]
Run it again after adding images; it overwrites the same covers and lists what is still missing.
"""
import json
import pathlib
import re
import sys
import unicodedata

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "app/assets/mock/catalog.json"
OUT = ROOT / "app/assets/covers"
DOC = ROOT / "docs/OKLADKI.md"
DEFAULT_SOURCE = ROOT.parent / "AudioKiddo-materialy" / "okladki"
SIZE = 900
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def norm(text: str) -> str:
    """Lower case, no Polish diacritics, letters and digits only."""
    text = text.replace("ł", "l").replace("Ł", "L")
    text = unicodedata.normalize("NFKD", text)
    return re.sub(r"[^a-z0-9]", "", "".join(c for c in text if not unicodedata.combining(c)).lower())


def square(image: Image.Image) -> Image.Image:
    w, h = image.size
    side = min(w, h)
    left, top = (w - side) // 2, (h - side) // 2
    return image.crop((left, top, left + side, top + side))


def main() -> int:
    source = pathlib.Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else DEFAULT_SOURCE
    if not source.is_dir():
        print(f"Brak folderu z okładkami: {source}")
        return 1
    catalog = json.loads(CATALOG.read_text())
    items = catalog["items"]
    keys = {i["id"]: {norm(i["title"]), norm(i["id"])} for i in items}
    pack_keys = {p["id"]: {norm(p["title"]), norm(p["id"])} for p in catalog["packs"]}

    OUT.mkdir(parents=True, exist_ok=True)
    matched: dict[str, pathlib.Path] = {}
    unmatched: list[str] = []
    for path in sorted(source.iterdir()):
        if path.suffix.lower() not in EXTENSIONS:
            continue
        stem = norm(path.stem)
        if "pakiet" in stem:
            packs = sorted(((len(k), i) for i, ks in pack_keys.items() for k in ks if k and k in stem), reverse=True)
            if packs:
                matched[f"pakiet-{packs[0][1]}"] = path
                continue
        # The longest key found in the name wins, so "co to za dzwiek" never steals "co to".
        hits = sorted(
            ((len(k), item_id) for item_id, ks in keys.items() for k in ks if k and k in stem), reverse=True
        )
        if not hits:
            unmatched.append(path.name)
            continue
        item_id = hits[0][1]
        if item_id in matched:
            print(f"UWAGA: dwa pliki dla {item_id}: {matched[item_id].name} i {path.name} (zostaje drugi)")
        matched[item_id] = path

    for item_id, path in matched.items():
        with Image.open(path) as image:
            image = square(image.convert("RGB")).resize((SIZE, SIZE), Image.LANCZOS)
            image.save(OUT / f"{item_id}.jpg", "JPEG", quality=80, optimize=True, progressive=True)

    # Covers of plays that no longer exist are dropped.
    for stale in OUT.glob("*.jpg"):
        if stale.stem not in keys and not (stale.stem.startswith("pakiet-") and stale.stem[7:] in pack_keys):
            stale.unlink()

    have = {p.stem for p in OUT.glob("*.jpg")}
    total_kb = sum(p.stat().st_size for p in OUT.glob("*.jpg")) / 1024
    lines = [
        "# Okładki zabaw",
        "",
        "Generowane przez `tool/import_covers.py` (nie edytuj ręcznie). Obrazy wrzucasz do "
        "`AudioKiddo-materialy/okladki/` pod dowolną nazwą zawierającą tytuł zabawy, np. "
        "`Gadający śmietnik.jpg`, i uruchamiasz skrypt (albo piszesz do mnie).",
        "",
        "Wymagania: kwadrat, najlepiej 1080×1080 px, JPG lub PNG. W aplikacji okładka ma 900×900 px "
        f"(razem {total_kb:.0f} KB), bez okładki widać rysunek zastępczy.",
        "",
        f"Mamy {len([h for h in have if not h.startswith('pakiet-')])} z {len(items)} okładek zabaw i {len([h for h in have if h.startswith('pakiet-')])} z {len(catalog['packs'])} okładek pakietów.",
        "",
        "| Zabawa | Pakiet | Okładka |",
        "|---|---|---|",
    ]
    for pack in catalog["packs"]:
        status = "jest" if f"pakiet-{pack['id']}" in have else "brak"
        lines.append(f"| **Pakiet {pack['title']}** (`pakiet-{pack['id']}`) | okładka pakietu | {status} |")
    for item in items:
        status = "jest" if item["id"] in have else "brak"
        lines.append(f"| {item['title']} (`{item['id']}`) | {item.get('pack_id') or item['kind']} | {status} |")
    DOC.write_text("\n".join(lines) + "\n")

    print(f"{len(matched)} okładek z {source}, razem {len(have)} plików ({total_kb:.0f} KB)")
    if unmatched:
        print("Nie pasują do żadnej zabawy (nazwa pliku powinna zawierać tytuł):")
        for name in unmatched:
            print(f"  {name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
