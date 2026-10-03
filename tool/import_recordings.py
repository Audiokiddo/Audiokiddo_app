#!/usr/bin/env python3
"""Imports real AudioKiddo recordings into the local dev content and the catalog.

Source: ../AudioKiddo-materialy/<folder>/ with one audio file per play (mp3, m4a, wav, flac).
A file belongs to the play whose title or id appears in its file name, ignoring case, Polish
letters, spaces, digits' dots and punctuation:
    "Znikające dzwonki rowerowe.mp3", "3. Mikstura.wav", "Max i Mila - Gadający śmietnik.m4a"
Folders named like a pack (wyobraznia, detektyw, slowa-i-wiedza) only match plays of that
pack; any other folder (e.g. piosenki) matches every play. Słowa i Wiedza is also read the
old way: files numbered 1..10 like on audiokiddo.pl.

Each file is converted to AAC 96 kb/s (about half the size of shop MP3s, fine for speech and
music) at the path the catalog already uses; the catalog gets the real duration, size and
SHA-256, and the free 45 s previews are cut again (tool/make_previews.py). PDFs in the same
folder: a file with "Akta sprawy" (or "do wydruku") in its name goes to the play named in it
as that play's printable, a file starting with "Przewodnik" becomes the pack's free guide for
parents; both are shrunk (tool/shrink_pdf.py). PRINTABLES are attached to every play of a pack.

Recordings are paid content: they live in dev_content/ (not in git); tool/set_files_secrets.sh
or tool/files_update.sh puts them on the server.
    python3 tool/import_recordings.py [--materials DIR] [--dry-run]
"""
import argparse
import hashlib
import json
import pathlib
import re
import shutil
import subprocess
import sys
import unicodedata

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from shrink_pdf import shrink  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_MATERIALS = ROOT.parent / "AudioKiddo-materialy"
CATALOG = ROOT / "app/assets/mock/catalog.json"
OUT = ROOT / "dev_content"
SKIP_FOLDERS = {"do-druku", "grafiki", "logo", "okladki"}
AUDIO = {".mp3", ".m4a", ".wav", ".flac", ".aac", ".ogg"}

# Slowa i Wiedza in the shop's numbering order (files "1.-Co-to-za-przedmiot_....mp3").
NUMBERED = {
    "slowa-i-wiedza": [
        "co-to-za-przedmiot", "co-to-za-dzwiek", "szybkie-skojarzenia", "co-tu-nie-pasuje",
        "wymien-trzy", "znajdz-przeciwienstwo", "znajdz-synonimy", "uloz-zdanie",
        "dokoncz-zgodnie-z-prawda", "kto-to-powiedzial",
    ],
}
PRINTABLES = {"slowa-i-wiedza": "do-druku/Dyplom-Slowa-i-wiedza.pdf"}


def norm(text: str) -> str:
    """Lower case, no Polish diacritics, letters and digits only."""
    text = text.replace("ł", "l").replace("Ł", "L")
    text = unicodedata.normalize("NFKD", text)
    return re.sub(r"[^a-z0-9]", "", "".join(c for c in text if not unicodedata.combining(c)).lower())


def number(path: pathlib.Path):
    match = re.match(r"(\d+)\.", path.name)
    return int(match.group(1)) if match else None


def duration(path: pathlib.Path) -> int:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    ).stdout
    return round(float(out))


def fingerprint(asset: dict, out: pathlib.Path) -> None:
    data = (out / asset["path"]).read_bytes()
    asset["bytes"] = len(data)
    asset["sha256"] = hashlib.sha256(data).hexdigest()


def plan(folder: pathlib.Path, items: list) -> tuple[dict, list]:
    """Which file goes to which play: {item_id: file}, and the files that match nothing."""
    files = sorted(p for p in folder.iterdir() if p.suffix.lower() in AUDIO)
    ids = NUMBERED.get(folder.name)
    if ids and files and [number(f) for f in sorted(files, key=lambda f: number(f) or 0)] == list(
        range(1, len(ids) + 1)
    ):
        return dict(zip(ids, sorted(files, key=number))), []
    pool = [i for i in items if i.get("audio") and (folder.name not in {x.get("pack_id") for x in items} or i.get("pack_id") == folder.name)]
    keys = {i["id"]: {norm(i["title"]), norm(i["id"])} for i in pool}
    matched: dict = {}
    unmatched = []
    for f in files:
        stem = norm(f.stem)
        hits = sorted(((len(k), i) for i, ks in keys.items() for k in ks if k and k in stem), reverse=True)
        if not hits:
            unmatched.append(f.name)
            continue
        if hits[0][1] in matched:
            print(f"UWAGA: dwa pliki dla {hits[0][1]}: {matched[hits[0][1]].name} i {f.name} (zostaje drugi)")
        matched[hits[0][1]] = f
    return matched, unmatched


def printable_pdfs(folder: pathlib.Path, items: list) -> tuple:
    """{item_id: pdf} for case files named after a play, and the pack guide (Przewodnik*.pdf)."""
    pdfs = sorted(p for p in folder.iterdir() if p.suffix.lower() == ".pdf")
    guide = next((p for p in pdfs if norm(p.stem).startswith("przewodnik")), None)
    pool = [i for i in items if i.get("pack_id") == folder.name]
    keys = {i["id"]: {norm(i["title"]), norm(i["id"])} for i in pool}
    per_item = {}
    for pdf in pdfs:
        stem = norm(pdf.stem)
        if pdf == guide or not any(w in stem for w in ("akta", "dowydruku", "wydruk")):
            continue
        hits = sorted(((len(k), i) for i, ks in keys.items() for k in ks if k and k in stem), reverse=True)
        if hits:
            per_item[hits[0][1]] = pdf
        else:
            print(f"  NIE PASUJE (PDF bez tytułu zabawy w nazwie): {pdf.name}")
    return per_item, guide


def import_pdf(source: pathlib.Path, rel: str, out: pathlib.Path) -> dict:
    target = out / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    shrink(source, target)
    asset = {"path": rel}
    fingerprint(asset, out)
    return asset


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--materials", default=str(DEFAULT_MATERIALS))
    ap.add_argument("--catalog", default=str(CATALOG))
    ap.add_argument("--out", default=str(OUT))
    ap.add_argument("--dry-run", action="store_true", help="only show what would be imported")
    args = ap.parse_args()
    materials, catalog_path, out = pathlib.Path(args.materials), pathlib.Path(args.catalog), pathlib.Path(args.out)

    catalog = json.loads(catalog_path.read_text())
    items = {i["id"]: i for i in catalog["items"]}
    done = 0
    for folder in sorted(p for p in materials.iterdir() if p.is_dir() and p.name not in SKIP_FOLDERS):
        matched, unmatched = plan(folder, catalog["items"])
        if not matched and not unmatched and not any(p.suffix.lower() == ".pdf" for p in folder.iterdir()):
            continue
        print(f"== {folder.name}")
        for item_id, source in matched.items():
            item = items[item_id]
            asset = item["audio"][0]
            if args.dry_run:
                print(f"  {item_id}  ←  {source.name}")
                continue
            target = out / asset["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                ["ffmpeg", "-v", "error", "-y", "-i", str(source), "-map_metadata", "-1",
                 "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", str(target)],
                check=True,
            )
            fingerprint(asset, out)
            item["duration_sec"] = duration(target)
            printable = PRINTABLES.get(folder.name)
            if printable and (materials / printable).exists():
                pdf = {"path": f"pdf/{folder.name}/dyplom-{item_id}.pdf"}
                (out / pdf["path"]).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(materials / printable, out / pdf["path"])
                fingerprint(pdf, out)
                item["pdf"] = [pdf]
            print(f"  {item_id}: {item['duration_sec'] // 60} min {item['duration_sec'] % 60} s, "
                  f"{asset['bytes'] / 1e6:.1f} MB  ←  {source.name}")
            done += 1
        for name in unmatched:
            print(f"  NIE PASUJE do żadnej zabawy (nazwa pliku powinna zawierać tytuł): {name}")
        per_item, guide = printable_pdfs(folder, catalog["items"])
        for item_id, pdf in per_item.items():
            if args.dry_run:
                print(f"  wydruk {item_id}  ←  {pdf.name}")
                continue
            asset = import_pdf(pdf, f"pdf/{folder.name}/{item_id}.pdf", out)
            items[item_id]["pdf"] = [asset]
            print(f"  wydruk {item_id}: {asset['bytes'] / 1e6:.1f} MB  ←  {pdf.name}")
        pack = next((p for p in catalog["packs"] if p["id"] == folder.name), None)
        if guide and pack:
            if args.dry_run:
                print(f"  przewodnik {pack['id']}  ←  {guide.name}")
            else:
                pack["guide"] = import_pdf(guide, f"pdf/{folder.name}/przewodnik.pdf", out)
                print(f"  przewodnik {pack['id']}: {pack['guide']['bytes'] / 1e6:.1f} MB  ←  {guide.name}")
    if args.dry_run:
        return 0
    catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + "\n")
    print(f"{done} nagrań zaimportowanych.")
    if done and catalog_path == CATALOG and out == OUT:
        subprocess.run([sys.executable, str(ROOT / "tool/make_previews.py")], check=True)
        print("Gotowe. Na serwer: tool/files_update.sh")
    return 0


if __name__ == "__main__":
    sys.exit(main())
