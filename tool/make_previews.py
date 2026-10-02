#!/usr/bin/env python3
"""Cuts a short free preview from every paid recording, so a parent can hear it before buying.

For each paid item with audio: the first PREVIEW_SEC seconds (songs: SONG_PREVIEW_SEC) with a
soft fade-in and fade-out, mono AAC 64 kb/s, written to dev_content/previews/<group>/<id>.m4a
(the same folder goes to the server with the recordings). The catalog item gets "preview"
with the real size and SHA-256. Run again after new recordings; existing previews are redone.
    python3 tool/make_previews.py
Then: python3 tool/content_files_sql.py (previews are free files) and a new files ZIP.
"""
import hashlib
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "app/assets/mock/catalog.json"
CONTENT = ROOT / "dev_content"
PREVIEW_SEC = 45
SONG_PREVIEW_SEC = 30
FADE_SEC = 3


def duration(path: pathlib.Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    )
    return float(out.stdout.strip())


def cut(source: pathlib.Path, target: pathlib.Path, seconds: int) -> None:
    length = min(seconds, duration(source))
    fade_out_at = max(length - FADE_SEC, 0)
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(source), "-t", f"{length:.2f}",
         "-af", f"afade=t=in:d=0.4,afade=t=out:st={fade_out_at:.2f}:d={FADE_SEC}",
         "-ac", "1", "-ar", "44100", "-c:a", "aac", "-b:a", "64k", "-movflags", "+faststart", str(target)],
        check=True,
    )


def main() -> None:
    catalog = json.loads(CATALOG.read_text())
    made = 0
    for item in catalog["items"]:
        audio = item.get("audio") or []
        if item.get("access") != "paid" or not audio:
            item.pop("preview", None)
            continue
        source = CONTENT / audio[0]["path"]
        if not source.exists():
            print(f"brak nagrania: {source}")
            continue
        group = item.get("pack_id") or ("piosenki" if item["kind"] == "song" else "inne")
        rel = f"previews/{group}/{item['id']}.m4a"
        target = CONTENT / rel
        cut(source, target, SONG_PREVIEW_SEC if item["kind"] == "song" else PREVIEW_SEC)
        data = target.read_bytes()
        item["preview"] = {"path": rel, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        made += 1
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + "\n")
    total = sum(p.stat().st_size for p in (CONTENT / "previews").rglob("*.m4a"))
    print(f"{made} próbek, {total / 1024:.0f} KB w {CONTENT / 'previews'}")


if __name__ == "__main__":
    main()
