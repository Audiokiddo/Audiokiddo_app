#!/usr/bin/env python3
"""Imports real AudioKiddo recordings into the local dev content and the mock catalog.

Source: ../AudioKiddo-materialy/<pack>/ with files numbered like on audiokiddo.pl
("1.-Co-to-za-przedmiot_....mp3"). Each file is converted to AAC 96 kb/s (about half
the size of the shop MP3s, fine for speech and music) at the path the catalog already
uses, and the catalog gets the real duration, size and SHA-256. Printables listed in
PRINTABLES are attached to every item of the pack, one copy per item, because
downloads are tracked per asset path.

Recordings are paid content: they live in dev_content/ (not in git) until Supabase/LH.pl.
"""
import hashlib
import json
import pathlib
import re
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
MATERIALS = ROOT.parent / "AudioKiddo-materialy"
CATALOG = ROOT / "app/assets/mock/catalog.json"
OUT = ROOT / "dev_content"

# Pack folder -> catalog item ids in the shop's numbering order.
PACKS = {
    "slowa-i-wiedza": [
        "co-to-za-przedmiot", "co-to-za-dzwiek", "szybkie-skojarzenia", "co-tu-nie-pasuje",
        "wymien-trzy", "znajdz-przeciwienstwo", "znajdz-synonimy", "uloz-zdanie",
        "dokoncz-zgodnie-z-prawda", "kto-to-powiedzial",
    ],
}
PRINTABLES = {"slowa-i-wiedza": MATERIALS / "do-druku/Dyplom-Slowa-i-wiedza.pdf"}


def number(path: pathlib.Path) -> int:
    match = re.match(r"(\d+)\.", path.name)
    if not match:
        raise SystemExit(f"Brak numeru na początku nazwy: {path.name}")
    return int(match.group(1))


def duration(path: pathlib.Path) -> int:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    ).stdout
    return round(float(out))


def fingerprint(asset: dict) -> None:
    data = (OUT / asset["path"]).read_bytes()
    asset["bytes"] = len(data)
    asset["sha256"] = hashlib.sha256(data).hexdigest()


def main() -> None:
    catalog = json.loads(CATALOG.read_text())
    items = {i["id"]: i for i in catalog["items"]}
    for pack, ids in PACKS.items():
        sources = sorted((MATERIALS / pack).glob("*.mp3"), key=number)
        if [number(s) for s in sources] != list(range(1, len(ids) + 1)):
            raise SystemExit(f"{pack}: oczekiwano plików 1..{len(ids)}, jest {[s.name for s in sources]}")
        for source, item_id in zip(sources, ids):
            item = items[item_id]
            asset = item["audio"][0]
            target = OUT / asset["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                ["ffmpeg", "-v", "error", "-y", "-i", str(source), "-map_metadata", "-1",
                 "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", str(target)],
                check=True,
            )
            fingerprint(asset)
            item["duration_sec"] = duration(target)
            printable = PRINTABLES.get(pack)
            if printable:
                pdf = {"path": f"pdf/{pack}/dyplom-{item_id}.pdf"}
                (OUT / pdf["path"]).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(printable, OUT / pdf["path"])
                fingerprint(pdf)
                item["pdf"] = [pdf]
            print(f"{item_id}: {item['duration_sec'] // 60} min {item['duration_sec'] % 60} s, "
                  f"{asset['bytes'] / 1e6:.1f} MB  ← {source.name}")
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + "\n")


if __name__ == "__main__":
    main()
