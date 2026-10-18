#!/usr/bin/env python3
"""Kiddo's voice lines and interface sounds bundled with the app (app/assets/audio/kiddo/).

Placeholder speech: macOS `say` (voice Zosia). With --voice NAME the lines are spoken by that
ElevenLabs voice instead (Dawid's own voice is the one named "szop" in his ElevenLabs library); the files keep the same names, so
the app needs no change. The key is read from the macOS keychain (item "elevenlabs-api-key"),
never from the repository. Every line is cached by its text, there is no automatic retry and a
character limit stops the run before it can cost more than planned. Sounds are synthesised here.
Short files, bundled so the welcome works offline on the first launch.

    python3 tool/ui_voice.py --voice szop --dry-run          # what it would cost, nothing sent
    python3 tool/ui_voice.py --voice szop --only hello       # one line to listen to first
    python3 tool/ui_voice.py --voice szop                    # all the lines
"""
import argparse
import hashlib
import json
import urllib.request
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
ELEVEN_VOICES = {"nela": "PCOFCZ4Ict9D0opt85il", "fantazjusz": "ijH86K9sA5IEvCDBMgFn"}
ELEVEN_MODEL = "eleven_v4"
CACHE = ROOT / "dev_content/tts-cache"

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
    # More of Szop'en in the car: the trip picks one start, rotates the window breaks, picks one end.
    "trip_start_2": "Wsiadamy! Pasy zapięte? Mój ogon też. Jedziemy na przygodę!",
    "trip_start_3": "Brum, brum! Dziś jestem nawigatorem od zabaw. Kierowca pilnuje drogi, a my słuchamy!",
    "trip_start_4": "Plecak spakowany, przekąski policzone. No dobra, jedną już zjadłem. Ruszamy!",
    "trip_start_5": "Hej, podróżniku! Zanim dojedziemy, przeżyjemy kilka przygód. Uszy gotowe?",
    "trip_start_6": "Startujemy! Siedzę z tyłu i wcale nie pytam, czy jeszcze daleko. No, może tylko trochę.",
    "window_4": "Przerwa na okno! Znajdź najśmieszniejszą chmurę i wymyśl dla niej imię.",
    "window_5": "Przerwa na okno! Kto pierwszy zobaczy krowę albo konia, ten wygrywa!",
    "window_6": "Przerwa na okno! Wypatruj znaków. Znajdź literę A, a potem literę S, jak Szop'en.",
    "trip_end_2": "Jesteśmy na miejscu! Rozprostuj nogi, a ja rozprostuję ogon. Dzięki za wspólną jazdę!",
    "trip_end_3": "Koniec trasy! Wspaniale się z tobą jechało. Idę poszukać przekąski. Do następnej podróży!",
    "bedtime_start": "Czas na wyciszenie. Zróbmy razem trzy spokojne oddechy. Wdech. I wydech. Wdech. I wydech. Wdech. I wydech.",
    "goodnight": "Dobranoc. Nos pod koc, uszy na poduszkę. Resztę przygód zostawimy na jutro.",
    # Diploma after a whole pack (app/lib/features/diploma): congratulations and a secret reward.
    # The first play of the day, after "Hej, Zosia!" (parent review, 2026-10-18).
    "good_day": "Jak dobrze cię słyszeć! Zaczynamy dzisiejszą przygodę.",
    # The child's birthday (day and month, with the parent's consent).
    "birthday": "Sto lat, sto lat, niech żyje, żyje nam! Wszystkiego najlepszego z okazji urodzin! Mój ogon aż tańczy z radości.",
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


def encode(source, target, normalize=False):
    """AAC mono file; with [normalize] brought to -19 LUFS / -1.5 dBTP in two passes (the
    ElevenLabs lines come out at different levels, the app's voice must not jump)."""
    level = []
    if normalize:
        spec = "I=-19:TP=-1.5:LRA=11"
        report = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(source), "-af", f"loudnorm={spec}:print_format=json",
                                 "-f", "null", "-"], capture_output=True, text=True).stderr
        m = json.loads(report[report.rindex("{"):report.rindex("}") + 1])
        level = ["-af", f"loudnorm={spec}:measured_I={m['input_i']}:measured_TP={m['input_tp']}:measured_LRA={m['input_lra']}"
                        f":measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true,alimiter=limit=0.8:level=false"]
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", str(source), *level, "-ac", "1", "-ar", "44100",
         "-c:a", "aac", "-b:a", "64k", "-movflags", "+faststart", str(target)],
        check=True,
    )


def eleven_key():
    key = subprocess.run(["security", "find-generic-password", "-a", "audiokiddo", "-s", "elevenlabs-api-key", "-w"],
                         capture_output=True, text=True).stdout.strip()
    if not key:
        raise SystemExit("Brak klucza ElevenLabs w pęku kluczy (elevenlabs-api-key).")
    return key


def voice_id(name):
    """The id of a voice: the known ones, else the voice of that name in the account's library."""
    if name in ELEVEN_VOICES:
        return ELEVEN_VOICES[name]
    known = CACHE / "voice-ids.json"
    ids = json.loads(known.read_text()) if known.exists() else {}
    if name not in ids:
        request = urllib.request.Request("https://api.elevenlabs.io/v1/voices", headers={"xi-api-key": eleven_key()})
        with urllib.request.urlopen(request, timeout=60) as response:
            voices = json.load(response).get("voices", [])
        match = [v for v in voices if v.get("name", "").strip().lower() == name.lower()]
        if not match:
            raise SystemExit(f'Nie ma głosu o nazwie "{name}" w ElevenLabs. Są: ' + ", ".join(sorted(v.get("name", "?") for v in voices)))
        ids[name] = match[0]["voice_id"]
        CACHE.mkdir(parents=True, exist_ok=True)
        known.write_text(json.dumps(ids))
    return ids[name]


def eleven_speech(text, voice_name):
    """The mp3 of [text] in the named voice: from the cache, or bought once and kept."""
    cache = CACHE / voice_name / (hashlib.sha1(f"{ELEVEN_MODEL}|{text}".encode()).hexdigest() + ".mp3")
    if cache.exists():
        return cache
    request = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id(voice_name)}?output_format=mp3_44100_128",
        data=json.dumps({"text": text, "model_id": ELEVEN_MODEL, "language_code": "pl",
                         "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}}).encode(),
        headers={"xi-api-key": eleven_key(), "Content-Type": "application/json"}, method="POST")
    # No automatic retry: a failed call may already have used credits.
    with urllib.request.urlopen(request, timeout=120) as response:
        data = response.read()
    if not data:
        raise SystemExit("ElevenLabs zwrócił pusty plik.")
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_bytes(data)
    return cache


def speak_with_voice(args):
    """Replaces the spoken lines with [args.voice]; the sounds are left as they are."""
    names = [n for n in LINES if not args.only or n in args.only.split(",")]
    unknown = set(args.only.split(",")) - set(LINES) if args.only else set()
    if unknown:
        raise SystemExit(f"Nieznane pliki: {', '.join(sorted(unknown))}. Dostępne: {', '.join(LINES)}")
    cost = sum(len(LINES[n]) for n in names
               if not (CACHE / args.voice / (hashlib.sha1(f"{ELEVEN_MODEL}|{LINES[n]}".encode()).hexdigest() + ".mp3")).exists())
    print(f"{len(names)} nagrań, do kupienia {cost} znaków (limit {args.limit}), reszta z pamięci podręcznej.")
    if args.dry_run:
        return
    if cost > args.limit:
        raise SystemExit(f"Limit znaków ({args.limit}) byłby przekroczony. Użyj --only albo większego --limit.")
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names:
        encode(eleven_speech(LINES[name], args.voice), OUT / f"{name}.m4a", normalize=True)
        print(f"  {name}.m4a")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--voice", help="name of the ElevenLabs voice for the lines, e.g. szop (default: the placeholder speech)")
    parser.add_argument("--only", help="comma-separated file names, e.g. hello,goodnight")
    parser.add_argument("--limit", type=int, default=2500, help="character limit for one run (default 2500)")
    parser.add_argument("--dry-run", action="store_true", help="only count the characters to buy")
    args = parser.parse_args()
    if args.voice:
        speak_with_voice(args)
        return
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
    section = [marker, "", "Krótkie kwestie Szop'ena do dziecka (ciepły, łagodny ton), wbudowane w aplikację (`app/assets/audio/kiddo/`). "
               "Radośnie, z uśmiechem, bez muzyki pod spodem. Tymczasowy głos (macOS Zosia) zastępuje głos Dawida z ElevenLabs: "
               "`python3 tool/ui_voice.py --voice szop` (najpierw `--only hello`, koszt w `--dry-run`).", "", "| Plik | Tekst |", "|---|---|"]
    section += [f"| `{name}.m4a` | {line} |" for name, line in LINES.items()]
    if marker in text:
        text = text[: text.index(marker)].rstrip() + "\n"
    doc.write_text(text.rstrip() + "\n\n" + "\n".join(section) + "\n")


if __name__ == "__main__":
    main()
