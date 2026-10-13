#!/usr/bin/env python3
"""Szop'en greets the child by name: "Hej, Zosia!" for the most common Polish children's names
and their usual short forms, in Dawid's ElevenLabs voice ("Szop Dawid"), bundled with the app
(app/assets/audio/names/). A name not on the list is simply not said: the app falls back to the
line without a name.

    python3 tool/name_voice.py --dry-run     # how many characters it would buy
    python3 tool/name_voice.py               # record what is missing (cached, no retries)

Uses ui_voice.py's ElevenLabs helpers: key from the macOS keychain, cache in dev_content/tts-cache,
loudness -19 LUFS. index.json maps the typed name (lower case, trimmed) to the file.
"""
import argparse
import hashlib
import json
import pathlib
import sys
import unicodedata

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import ui_voice  # noqa: E402

OUT = ui_voice.ROOT / "app/assets/audio/names"
VOICE = "Szop Dawid"

GIRLS = """Zuzanna Zuzia Zofia Zosia Hanna Hania Julia Julka Maja Laura Oliwia Oliwka Alicja Ala Lena Lenka
Pola Amelia Amelka Nadia Antonina Tosia Aleksandra Ola Natalia Natalka Gabriela Gabrysia Wiktoria Wiktoria
Emilia Emilka Liliana Lilka Helena Helenka Jagoda Milena Maria Marysia Michalina Misia Iga Kornelia Anna
Ania Martyna Nikola Weronika Barbara Basia Klara Blanka Marcelina Kalina Stefania Stefcia Matylda Rozalia
Ida Nina Ewa Kinga Emma Gaja Agata Karolina Magdalena Madzia Katarzyna Kasia Paulina Dominika Joanna Asia
Marta Łucja Mila Lilianna Malwina Jaśmina Aurelia Melania Wiktoria Ksenia Adrianna Daria Elena Lea""".split()
BOYS = """Antoni Antek Jan Janek Jaś Aleksander Olek Franciszek Franek Nikodem Jakub Kuba Stanisław Staś
Szymon Filip Mikołaj Wojciech Wojtek Ignacy Ignaś Leon Kacper Michał Adam Tymon Mateusz Marcel Wiktor
Tymoteusz Tymek Igor Maksymilian Maks Piotr Piotruś Bartosz Bartek Oskar Kazimierz Kazio Henryk Henio
Krzysztof Krzyś Tomasz Tomek Dawid Gabriel Hubert Dominik Miłosz Natan Bruno Borys Ksawery Julian Józef
Józek Witold Witek Paweł Łukasz Patryk Kamil Maciej Maciek Karol Sebastian Daniel Jeremi Teodor Teoś
Fabian Alan Kajetan Cyprian Iwo Ludwik Feliks Milan Aleks Eryk Olaf Leonard Tadeusz Tadzio Konrad""".split()


def slug(name):
    """'Łucja' -> 'lucja': a safe file name."""
    plain = unicodedata.normalize("NFKD", name.replace("ł", "l").replace("Ł", "L"))
    return "".join(c for c in plain if c.isascii() and c.isalnum()).lower()


def names():
    seen, out = set(), []
    for n in GIRLS + BOYS:
        if n not in seen:
            seen.add(n)
            out.append(n)
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=2500, help="character limit for one run")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    lines = {n: f"Hej, {n}!" for n in names()}
    cache = ui_voice.CACHE / VOICE
    cost = sum(len(t) for t in lines.values()
               if not (cache / (hashlib.sha1(f"{ui_voice.ELEVEN_MODEL}|{t}".encode()).hexdigest() + ".mp3")).exists())
    print(f"{len(lines)} imion, do kupienia {cost} znaków (limit {args.limit}).")
    if args.dry_run:
        return
    if cost > args.limit:
        raise SystemExit("Limit znaków byłby przekroczony; przerwano bez kosztów.")
    OUT.mkdir(parents=True, exist_ok=True)
    index = {}
    for name, text in lines.items():
        target = OUT / f"{slug(name)}.m4a"
        ui_voice.encode(ui_voice.eleven_speech(text, VOICE), target, normalize=True)
        index[name.lower()] = slug(name)
    (OUT / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=0, sort_keys=True) + "\n")
    total = sum(p.stat().st_size for p in OUT.glob("*.m4a"))
    print(f"{len(index)} plików, {total / 1024:.0f} KB w {OUT}")


if __name__ == "__main__":
    main()
