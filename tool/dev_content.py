#!/usr/bin/env python3
"""Generates placeholder recordings for development and updates the mock catalog.

For every audio asset in app/assets/mock/catalog.json it creates a short spoken
Polish placeholder (macOS `say`, voice Zosia) followed by a quiet tone, writes it
to dev_content/<asset path> and stores the real size and SHA-256 in the catalog.

Serve the files for the app with:  python3 -m http.server 8787 -d dev_content
Real recordings replace this in Etap 3 (Supabase Storage).
"""
import hashlib
import json
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "app/assets/mock/catalog.json"
OUT = ROOT / "dev_content"
TONE_SECONDS = 40


def render(text: str, target: pathlib.Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        speech = pathlib.Path(tmp) / "speech.aiff"
        subprocess.run(["say", "-v", "Zosia", "-o", str(speech), text], check=True)
        subprocess.run(
            [
                "ffmpeg", "-v", "error", "-y",
                "-i", str(speech),
                "-f", "lavfi", "-i", f"sine=frequency=392:duration={TONE_SECONDS}",
                "-filter_complex",
                "[0]aresample=44100,aformat=channel_layouts=mono[s];"
                "[1]volume=0.08,afade=t=in:d=2,afade=t=out:st=38:d=2,aformat=channel_layouts=mono[t];"
                "[s][t]concat=n=2:v=0:a=1",
                "-c:a", "aac", "-b:a", "48k", "-movflags", "+faststart",
                str(target),
            ],
            check=True,
        )


def main() -> None:
    catalog = json.loads(CATALOG.read_text())
    for item in catalog["items"]:
        for asset in item.get("audio", []):
            target = OUT / asset["path"]
            if not target.exists():
                render(
                    f"Nagranie testowe. {item['title']}. "
                    "Tutaj będzie prawdziwa audiozabawa AudioKiddo. Teraz posłuchaj dźwięku próbnego.",
                    target,
                )
            data = target.read_bytes()
            asset["bytes"] = len(data)
            asset["sha256"] = hashlib.sha256(data).hexdigest()
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + "\n")
    total = sum(p.stat().st_size for p in OUT.rglob("*.m4a"))
    print(f"{len(list(OUT.rglob('*.m4a')))} files, {total / 1e6:.1f} MB in {OUT}")


if __name__ == "__main__":
    main()
