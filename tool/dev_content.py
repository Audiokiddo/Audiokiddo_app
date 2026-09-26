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


def ascii_text(text: str) -> str:
    table = str.maketrans("ąćęłńóśźżĄĆĘŁŃÓŚŹŻ", "acelnoszzACELNOSZZ")
    return text.translate(table).replace("(", "[").replace(")", "]")


def render_pdf(title: str, target: pathlib.Path) -> None:
    """Minimal one-page PDF (Helvetica, ASCII only) standing in for the case files."""
    target.parent.mkdir(parents=True, exist_ok=True)
    lines = ["AKTA SPRAWY - plik testowy", ascii_text(title), "",
             "Tu bedzie prawdziwa karta pracy AudioKiddo.", "Detektywie, zapisz tutaj swoje poszlaki:"]
    content = "BT /F1 20 Tf 60 780 Td 28 TL " + " ".join(f"({l}) Tj T*" for l in lines) + " ET"
    content += " 60 400 m 535 400 l S 60 360 m 535 360 l S 60 320 m 535 320 l S"
    objects = [
        "<< /Type /Catalog /Pages 2 0 R >>",
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R "
        "/Resources << /Font << /F1 5 0 R >> >> >>",
        f"<< /Length {len(content)} >>\nstream\n{content}\nendstream",
        "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    out = b"%PDF-1.4\n"
    offsets = []
    for i, obj in enumerate(objects, 1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n{obj}\nendobj\n".encode("latin-1")
    xref = len(out)
    out += f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode()
    out += "".join(f"{o:010d} 00000 n \n" for o in offsets).encode()
    out += f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode()
    target.write_bytes(out)


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
        for asset in item.get("pdf", []):
            target = OUT / asset["path"]
            if not target.exists():
                render_pdf(item["title"], target)
            data = target.read_bytes()
            asset["bytes"] = len(data)
            asset["sha256"] = hashlib.sha256(data).hexdigest()
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + "\n")
    total = sum(p.stat().st_size for p in OUT.rglob("*.m4a"))
    print(f"{len(list(OUT.rglob('*.m4a')))} files, {total / 1e6:.1f} MB in {OUT}")


if __name__ == "__main__":
    main()
