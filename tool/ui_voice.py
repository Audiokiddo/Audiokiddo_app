#!/usr/bin/env python3
"""Kiddo's voice lines and interface sounds bundled with the app (app/assets/audio/kiddo/).

Placeholder speech: macOS `say` (voice Zosia). Nela records the real lines listed in
docs/NAGRANIA-DO-GIER.md ("Głos Lorda"); the files keep the same names. Sounds are
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
    "hello": "Cześć! Jestem Szop'en. Mam pasiasty ogon i jeszcze większą ochotę na przygody. Gramy bez patrzenia w ekran!",
    "password_voice": "Żeby wejść do świata AudioKiddo, powiedz głośno magiczne hasło: Abrakadabra!",
    "password_tap": "Żeby wejść do świata AudioKiddo, powiedz głośno: Abrakadabra! I dotknij magicznej kuli!",
    "granted": "Hurra! Dostęp przyznany! Wchodzimy!",
    "kids_1": "Uszy gotowe? Moje są małe, ale słyszą wszystko. Nawet szelest cukierka.",
    "kids_2": "Potrzebuję kogoś z wyobraźnią. Ja mam głównie futro i paski. Wchodzisz w to?",
    "kids_3": "Jeśli usłyszysz burczenie, to mój brzuch. Tego nie liczymy. Wybierz zabawę!",
    "trip_start": "Ruszamy w drogę! Zapnijcie pasy. Ja pilnuję zagadek, a ty wypatruj czerwonego auta.",
    "window_1": "Przerwa na okno! Policz, ile czerwonych samochodów zobaczysz, zanim wrócimy do zabawy.",
    "window_2": "Przerwa na okno! Czy widzisz jakieś zwierzę? Opowiedz o nim rodzicom.",
    "window_3": "Przerwa na okno! Znajdź coś zielonego, coś okrągłego i coś bardzo dużego.",
    "trip_end": "Dojechaliśmy! Mój pasiasty ogon mówi, że to była świetna podróż. Do usłyszenia!",
    "bedtime_start": "Czas na wyciszenie. Zróbmy razem trzy spokojne oddechy. Wdech. I wydech. Wdech. I wydech. Wdech. I wydech.",
    "goodnight": "Dobranoc. Nos pod koc, uszy na poduszkę. Resztę przygód zostawimy na jutro.",
    # Diploma after a whole pack (app/lib/features/diploma): congratulations and a secret reward.
    "diploma": "Brawo! Cały pakiet ukończony. Oto twój dyplom. Jestem z ciebie bardzo dumny!",
    "bonus_wyobraznia": "Sekretna wiadomość od Szop'ena. Dziś w nocy twoje łóżko zamieni się w statek. Dokąd popłyniesz? Opowiedz o tym rodzicom przy śniadaniu!",
    "bonus_slowa-i-wiedza": "Sekretna zagadka od Szop'ena. Ma cztery nogi, ale nie chodzi. Stoi w kuchni i czeka na obiad. Co to? To stół!",
    "bonus_detektyw": "Tajne zadanie dla detektywa. Znajdź w domu trzy rzeczy, które zaczynają się na literę K. Szepnij je rodzicowi do ucha. Sprawa zamknięta!",
    "bonus_inne": "Sekretna wiadomość od Szop'ena. Jesteś prawdziwym mistrzem słuchania. Przybij piątkę rodzicowi!",
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


def fanfare():
    """Diploma fanfare: two short calls, then a held major chord with a sparkle on top."""
    out = []
    for f in [523, 523, 659]:
        out += mix(tone(f, 0.13, 0.28, 7), tone(f * 1.5, 0.13, 0.08, 9))
    out += [0.0] * int(RATE * 0.05)
    chord = mix(tone(523, 1.4, 0.22, 2.2), tone(659, 1.4, 0.18, 2.2), tone(784, 1.4, 0.18, 2.2),
                tone(1047, 1.4, 0.12, 2.6), tone(2093, 0.6, 0.05, 6))
    return out + chord


def note(freq):
    """A soft glockenspiel-ish tone: fundamental plus a bright partial, quick attack."""
    n = int(RATE * 0.9)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.008)
        out.append(attack * (0.32 * math.sin(2 * math.pi * freq * t) * math.exp(-4.5 * t)
                             + 0.12 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-9 * t)
                             + 0.05 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-14 * t)))
    return out


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
        # Melody notes for the weekly plan (C4..E5), soft bell-like tones.
        scale = [261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25, 587.33, 659.25]
        notes = {f"note_{i}": note(f) for i, f in enumerate(scale)}
        for name, samples in {"chime": chime(), "pop": pop(), "whoosh": whoosh(), "fanfare": fanfare(), **notes}.items():
            wav = pathlib.Path(tmp) / f"{name}.wav"
            write_wav(samples, wav)
            encode(wav, OUT / f"{name}.m4a")
    total = sum(p.stat().st_size for p in OUT.glob("*.m4a"))
    print(f"{len(list(OUT.glob('*.m4a')))} files, {total / 1024:.0f} KB in {OUT}")

    doc = ROOT / "docs/NAGRANIA-DO-GIER.md"
    text = doc.read_text()
    marker = "## Głos Szop’ena (aplikacja)"
    section = [marker, "", "Krótkie kwestie Szop'ena von Ekrana do dziecka (ciepły, łagodny ton), wbudowane w aplikację (`app/assets/audio/kiddo/`). "
               "Radośnie, z uśmiechem, bez muzyki pod spodem.", "", "| Plik | Tekst |", "|---|---|"]
    section += [f"| `{name}.m4a` | {line} |" for name, line in LINES.items()]
    if marker in text:
        text = text[: text.index(marker)].rstrip() + "\n"
    doc.write_text(text.rstrip() + "\n\n" + "\n".join(section) + "\n")


if __name__ == "__main__":
    main()
