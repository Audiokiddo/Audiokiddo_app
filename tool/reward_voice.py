#!/usr/bin/env python3
"""Szop'en's secrets: short recordings a child unlocks in the chests of the Adventure Map
(app/lib/features/rewards/adventure_map.dart), in Dawid's ElevenLabs voice ("Szop Dawid").

    python3 tool/reward_voice.py --dry-run
    python3 tool/reward_voice.py

Uses ui_voice.py's helpers: key from the macOS keychain, cache in dev_content/tts-cache, -19 LUFS.
"""
import argparse
import hashlib
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import ui_voice  # noqa: E402

OUT = ui_voice.ROOT / "app/assets/audio/rewards"
VOICE = "Szop Dawid"

# The order is the order of the chests: keep it, add new ones at the end.
SECRETS = [
    "Sekret numer jeden. Mój ogon ma dokładnie siedem pasków. Policzyłem je dziś rano. Dwa razy.",
    "Zagadka! Ma zęby, ale nie gryzie. Czesze włosy. Co to? Grzebień!",
    "Sekret: kiedy nikt nie patrzy, tańczę z mopem. Mop prowadzi.",
    "Zadanie od Szop’ena. Znajdź w domu coś miękkiego i powiedz temu dzień dobry.",
    "Zagadka! Im więcej z niej zabierasz, tym większa się robi. Co to? Dziura!",
    "Sekret: najbardziej lubię chrupki. Ale nie mów nikomu, bo zjedzą mi zapasy.",
    "Zadanie od Szop’ena. Przybij piątkę trzem osobom w domu. Albo jednej osobie trzy razy.",
    "Zagadka! Chodzi bez nóg, a stoi tylko w nocy. Co to? Zegar! No dobrze, zegar czasem też stoi.",
    "Sekret: raz próbowałem złapać własny ogon. Wygrał ogon.",
    "Zadanie od Szop’ena. Powiedz trzy słowa, które zaczynają się na literę S, jak Szop’en.",
    "Zagadka! Biały puch spada z nieba zimą. Co to? Śnieg! Ja w nim robię aniołki. Szopie aniołki.",
    "Sekret: umiem gwizdać. Tylko jeszcze nie wiem jak.",
    "Zadanie od Szop’ena. Pokaż rodzicowi najśmieszniejszą minę, jaką potrafisz.",
    "Zagadka! Ma cztery nogi i oparcie, ale nigdzie nie chodzi. Co to? Krzesło!",
    "Sekret: moja maska na oczach jest prawdziwa. Jestem tajnym agentem od zabaw.",
    "Zadanie od Szop’ena. Zrób pięć żabich skoków i powiedz kum kum!",
    "Zagadka! Świeci w nocy na niebie i czasem jest jak rogalik. Co to? Księżyc!",
    "Sekret ostatni na dziś: jesteś moim ulubionym słuchaczem. Tylko nie mów innym szopom.",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=2500)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    cache = ui_voice.CACHE / VOICE
    cost = sum(len(t) for t in SECRETS
               if not (cache / (hashlib.sha1(f"{ui_voice.ELEVEN_MODEL}|{t}".encode()).hexdigest() + ".mp3")).exists())
    print(f"{len(SECRETS)} sekretów, do kupienia {cost} znaków (limit {args.limit}).")
    if args.dry_run:
        return
    if cost > args.limit:
        raise SystemExit("Limit znaków byłby przekroczony; przerwano bez kosztów.")
    OUT.mkdir(parents=True, exist_ok=True)
    for i, text in enumerate(SECRETS, 1):
        ui_voice.encode(ui_voice.eleven_speech(text, VOICE), OUT / f"sekret-{i}.m4a", normalize=True)
    print(f"{len(SECRETS)} plików w {OUT}")


if __name__ == "__main__":
    main()
