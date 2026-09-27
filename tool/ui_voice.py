#!/usr/bin/env python3
"""Kiddo's voice lines and interface sounds bundled with the app (app/assets/audio/kiddo/).

Placeholder speech: macOS `say` (voice Zosia). Nela records the real lines listed in
docs/NAGRANIA-DO-GIER.md ("Głos Kiddo"); the files keep the same names. Sounds are
synthesised here. Short files, bundled so the welcome works offline on the first launch.
"""
import math
import pathlib
import random
import struct
import subprocess
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "app/assets/audio/kiddo"
RATE = 44100

LINES = {
    "volume": "Hej! Podgłośnij telefon, żeby dobrze mnie słyszeć!",
    "hello": "Cześć! Jestem Kiddo. Razem wymyślimy mnóstwo przygód. I to bez patrzenia w ekran!",
    "password_voice": "Żeby wejść do świata AudioKiddo, powiedz głośno magiczne hasło: Abrakadabra!",
    "password_tap": "Żeby wejść do świata AudioKiddo, powiedz głośno: Abrakadabra! I dotknij magicznej kuli!",
    "granted": "Hurra! Dostęp przyznany! Wchodzimy!",
    "kids_1": "Hej! W co dziś zagramy?",
    "kids_2": "Witaj z powrotem! Wybierz przygodę!",
    "kids_3": "Gotowi na zabawę? Ja jestem gotowy!",
}


def tone(freq, seconds, volume=0.35, decay=6.0):
    n = int(RATE * seconds)
    return [volume * math.sin(2 * math.pi * freq * i / RATE) * math.exp(-decay * i / RATE) for i in range(n)]


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def chime():
    """Rising sparkle: C–E–G–C arpeggio with a shimmer."""
    out = []
    for f in [523, 659, 784, 1047]:
        out += mix(tone(f, 0.16, 0.3, 8), tone(f * 2, 0.16, 0.08, 12))
    return out + mix(tone(1047, 0.8, 0.25, 3), tone(1568, 0.8, 0.1, 4))


def pop():
    return [0.5 * math.sin(2 * math.pi * (600 + 900 * i / 2000) * i / RATE) * math.exp(-40 * i / RATE) for i in range(2600)]


def whoosh():
    rnd = random.Random(5)
    n = int(RATE * 0.5)
    out, last = [], 0.0
    for i in range(n):
        last = 0.9 * last + 0.1 * rnd.uniform(-1, 1)
        env = math.sin(math.pi * i / n)
        out.append(1.6 * last * env)
    return out


def write_wav(samples, path):
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def encode(source, target):
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(source), "-ac", "1", "-ar", "44100",
         "-c:a", "aac", "-b:a", "64k", "-movflags", "+faststart", str(target)],
        check=True,
    )


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, text in LINES.items():
            target = OUT / f"{name}.m4a"
            if target.exists():
                continue
            aiff = pathlib.Path(tmp) / f"{name}.aiff"
            subprocess.run(["say", "-v", "Zosia", "-r", "185", "-o", str(aiff), text], check=True)
            encode(aiff, target)
        for name, samples in {"chime": chime(), "pop": pop(), "whoosh": whoosh()}.items():
            wav = pathlib.Path(tmp) / f"{name}.wav"
            write_wav(samples, wav)
            encode(wav, OUT / f"{name}.m4a")
    total = sum(p.stat().st_size for p in OUT.glob("*.m4a"))
    print(f"{len(list(OUT.glob('*.m4a')))} files, {total / 1024:.0f} KB in {OUT}")

    doc = ROOT / "docs/NAGRANIA-DO-GIER.md"
    text = doc.read_text()
    marker = "## Głos Kiddo (aplikacja)"
    section = [marker, "", "Krótkie kwestie maskotki Kiddo, wbudowane w aplikację (`app/assets/audio/kiddo/`). "
               "Radośnie, z uśmiechem, bez muzyki pod spodem.", "", "| Plik | Tekst |", "|---|---|"]
    section += [f"| `{name}.m4a` | {line} |" for name, line in LINES.items()]
    if marker in text:
        text = text[: text.index(marker)].rstrip() + "\n"
    doc.write_text(text.rstrip() + "\n\n" + "\n".join(section) + "\n")


if __name__ == "__main__":
    main()
