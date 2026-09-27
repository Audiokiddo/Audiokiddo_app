#!/usr/bin/env python3
"""Prototype interactive games (Etap 4) with placeholder recordings.

Speech: macOS `say` (voice Zosia). Sounds and music: synthesised here with the standard
library. Writes segments to dev_content/games/<game>/, adds or replaces the games in
app/assets/mock/catalog.json and lists the lines for the real narrator in
docs/NAGRANIA-DO-GIER.md. Real recordings replace the files without changing the scripts.
"""
import hashlib
import json
import math
import pathlib
import random
import struct
import subprocess
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "app/assets/mock/catalog.json"
OUT = ROOT / "dev_content"
RATE = 44100

# --- synthesis -------------------------------------------------------------------------


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def tone(freq, seconds, volume=0.4, decay=0.0):
    n = int(RATE * seconds)
    return [
        volume * math.sin(2 * math.pi * freq * i / RATE) * (math.exp(-decay * i / RATE) if decay else 1.0)
        for i in range(n)
    ]


def clap(volume=0.8):
    rnd = random.Random(7)
    n = int(RATE * 0.09)
    return [volume * rnd.uniform(-1, 1) * math.exp(-60 * i / RATE) for i in range(n)]


def rain(seconds):
    rnd = random.Random(3)
    out, last = [], 0.0
    for _ in range(int(RATE * seconds)):
        last = 0.97 * last + 0.03 * rnd.uniform(-1, 1)  # brownish noise
        out.append(3.0 * last)
    return out


def ding_dong():
    return tone(659, 0.6, 0.5, decay=4) + tone(523, 0.9, 0.5, decay=3)


def clock(seconds):
    out = []
    for i in range(int(seconds * 2)):
        out += tone(2000 if i % 2 else 1600, 0.03, 0.5, decay=80) + silence(0.47)
    return out


def melody(seconds, seed):
    rnd = random.Random(seed)
    notes = [262, 294, 330, 349, 392, 440, 494, 523]
    out = []
    while len(out) < RATE * seconds:
        f = rnd.choice(notes)
        out += [a + b for a, b in zip(tone(f, 0.25, 0.25, decay=3), tone(f / 2, 0.25, 0.15, decay=2))]
    return out[: int(RATE * seconds)]


def pattern(beats):
    """beats: list of gaps in seconds after each clap."""
    out = []
    for gap in beats:
        out += clap() + silence(gap)
    return out


def write_wav(samples, path):
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))


def encode(inputs, target):
    """Concatenate wav/aiff inputs into one AAC file."""
    target.parent.mkdir(parents=True, exist_ok=True)
    args = ["ffmpeg", "-v", "error", "-y"]
    for i in inputs:
        args += ["-i", str(i)]
    chain = "".join(f"[{i}]aresample={RATE},aformat=channel_layouts=mono[a{i}];" for i in range(len(inputs)))
    chain += "".join(f"[a{i}]" for i in range(len(inputs))) + f"concat=n={len(inputs)}:v=0:a=1"
    args += ["-filter_complex", chain, "-c:a", "aac", "-b:a", "64k", "-movflags", "+faststart", str(target)]
    subprocess.run(args, check=True)


# --- segments --------------------------------------------------------------------------

SCRIPT_LINES = {}  # game -> [(segment, text)] for the narrator list


def segment(game, name, speech=None, sound=None, after=None):
    """speech → sound → speech (after). Returns the asset entry."""
    target = OUT / "games" / game / f"{name}.m4a"
    if speech or after:
        SCRIPT_LINES.setdefault(game, []).append((name, " … ".join(t for t in [speech, "[dźwięk]" if sound else None, after] if t)))
    if not target.exists():
        with tempfile.TemporaryDirectory() as tmp:
            parts = []
            for i, text in enumerate([speech, None, after]):
                if i == 1 and sound is not None:
                    p = pathlib.Path(tmp) / "sound.wav"
                    write_wav(sound, p)
                    parts.append(p)
                elif text:
                    p = pathlib.Path(tmp) / f"s{i}.aiff"
                    subprocess.run(["say", "-v", "Zosia", "-o", str(p), text], check=True)
                    parts.append(p)
            encode(parts, target)
    data = target.read_bytes()
    return {"path": f"games/{game}/{name}.m4a", "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def fallback(ms, next_step, loop=None):
    step = {"type": "wait", "duration_ms": ms, "next": next_step}
    if loop:
        step["loop_asset"] = loop
    return {"no_microphone": step, "screen_locked": "same_as_no_microphone", "input_error": "same_as_no_microphone"}


def game(id_, steps, assets, start="intro", timing=False, variables=None, engine=1):
    return {
        "schema_version": 1,
        "id": id_,
        "version": 1,
        "min_engine_version": engine,
        "timing_sensitive": timing,
        "assets": assets,
        "variables": variables or {},
        "start": start,
        "steps": steps,
    }


def zgadnij_dzwiek():
    g = "zgadnij-dzwiek"
    sounds = [
        ("dzwonek", ding_dong(), "To był dzwonek do drzwi! Ktoś przyszedł w odwiedziny."),
        ("deszcz", rain(4), "To był deszcz! Kap, kap, kap."),
        ("zegar", clock(4), "To był zegar! Tik, tak, tik, tak."),
    ]
    assets = {
        "intro": segment(g, "intro", "Cześć! Zagramy w zgadywanie dźwięków. Posłuchaj uważnie i powiedz na głos, co słyszysz."),
        "heard_you": segment(g, "heard_you", "Słyszę, że masz pomysł! Sprawdźmy."),
        "thinking": segment(g, "thinking", sound=tone(220, 1.0, 0.03)),
        "outro": segment(g, "outro", "Brawo za uważne słuchanie! To już koniec zabawy."),
    }
    steps = {"intro": {"type": "play", "asset": "intro", "next": "q_dzwonek"}}
    for i, (name, sound, answer) in enumerate(sounds):
        nxt = f"q_{sounds[i + 1][0]}" if i + 1 < len(sounds) else "end"
        assets[f"q_{name}"] = segment(g, f"q_{name}", "Posłuchaj.", sound, "Co to za dźwięk?")
        assets[f"a_{name}"] = segment(g, f"a_{name}", answer)
        steps[f"q_{name}"] = {"type": "play", "asset": f"q_{name}", "next": f"listen_{name}"}
        steps[f"listen_{name}"] = {
            "type": "input", "input": "voice_activity", "window_ms": 6000,
            "on_detected": f"ack_{name}", "on_timeout": f"a_{name}",
            "fallback": fallback(6000, f"a_{name}", loop="thinking"),
        }
        steps[f"ack_{name}"] = {"type": "play", "asset": "heard_you", "next": f"a_{name}"}
        steps[f"a_{name}"] = {"type": "play", "asset": f"a_{name}", "next": nxt}
    steps["end"] = {"type": "end", "asset": "outro"}
    return game(g, steps, assets)


def taniec(g, intro_text):
    assets = {
        "intro": segment(g, "intro", intro_text),
        "stop": segment(g, "stop", "Stop! Zamieniamy się w posągi!"),
        "go": segment(g, "go", "Tańczymy dalej!"),
        "outro": segment(g, "outro", "Ale z Was świetne posągi! Koniec tańca."),
    }
    lengths = [12, 8, 15]
    steps = {"intro": {"type": "play", "asset": "intro", "next": "music_1"}}
    for i, seconds in enumerate(lengths, 1):
        assets[f"music_{i}"] = segment(g, f"music_{i}", sound=melody(seconds, seed=i))
        last = i == len(lengths)
        steps[f"music_{i}"] = {"type": "play", "asset": f"music_{i}", "next": f"stop_{i}"}
        steps[f"stop_{i}"] = {"type": "play", "asset": "stop", "next": f"freeze_{i}"}
        steps[f"freeze_{i}"] = {"type": "wait", "duration_ms": 4000 + 1000 * (i % 2), "next": "end" if last else f"go_{i}"}
        if not last:
            steps[f"go_{i}"] = {"type": "play", "asset": "go", "next": f"music_{i + 1}"}
    steps["end"] = {"type": "end", "asset": "outro"}
    return game(g, steps, assets)


def echo_rytmu():
    g = "echo-rytmu"
    rhythms = [[0.4, 0.4, 0.8], [0.25, 0.6, 0.25, 0.8], [0.2, 0.2, 0.2, 0.8]]
    assets = {
        "intro": segment(g, "intro", "Zagramy w echo! Ja zaklaszczę rytm, a potem ty klaśniesz tak samo."),
        "your_turn": segment(g, "your_turn", "Teraz ty!"),
        "heard_claps": segment(g, "heard_claps", "Słyszę klaskanie!"),
        "again": segment(g, "again", "Posłuchaj jeszcze raz, jak to brzmiało."),
        "outro": segment(g, "outro", "Super rytm! To już koniec zabawy."),
    }
    steps = {"intro": {"type": "play", "asset": "intro", "next": "rhythm_1"}}
    for i, beats in enumerate(rhythms, 1):
        nxt = f"rhythm_{i + 1}" if i < len(rhythms) else "end"
        assets[f"rhythm_{i}"] = segment(g, f"rhythm_{i}", sound=pattern(beats))
        steps[f"rhythm_{i}"] = {"type": "play", "asset": f"rhythm_{i}", "next": f"turn_{i}"}
        steps[f"turn_{i}"] = {"type": "play", "asset": "your_turn", "next": f"listen_{i}"}
        steps[f"listen_{i}"] = {
            "type": "input", "input": "clap", "window_ms": 5000, "min_count": len(beats),
            "on_detected": f"heard_{i}", "on_timeout": f"again_{i}",
            "fallback": fallback(5000, f"again_{i}"),
        }
        steps[f"heard_{i}"] = {"type": "play", "asset": "heard_claps", "next": f"again_{i}"}
        steps[f"again_{i}"] = {"type": "play", "asset": "again", "next": f"replay_{i}"}
        steps[f"replay_{i}"] = {"type": "play", "asset": f"rhythm_{i}", "next": nxt}
    steps["end"] = {"type": "end", "asset": "outro"}
    return game(g, steps, assets, timing=True)


def prawda_czy_nie():
    """Engine 2: the child answers each statement: clap = true, say "nie" = false."""
    g = "prawda-czy-nie"
    statements = [
        ("krowa", True, "Krowa mówi muuu.", "To prawda! Krowa mówi muuu."),
        ("ryby", False, "Ryby mieszkają na drzewach.", "Nie! Ryby mieszkają w wodzie."),
        ("snieg", True, "Śnieg jest zimny.", "To prawda! Śnieg jest zimniutki."),
        ("slon", False, "Słoń jest mniejszy od myszki.", "Nie! Słoń jest ogromny, a myszka malutka."),
        ("lato", True, "Latem jest cieplej niż zimą.", "To prawda! Latem świeci ciepłe słońce."),
        ("auta", False, "Samochody jeżdżą po chmurach.", "Nie! Samochody jeżdżą po drogach."),
    ]
    assets = {
        "intro": segment(g, "intro",
                         "Cześć! Zagramy w Prawda czy nie. Powiem ci jedno zdanie. Jeśli to prawda, klaśnij raz! "
                         "Jeśli to nieprawda, powiedz głośno: nie! Gotowi? Zaczynamy."),
        "correct": segment(g, "correct", "Tak jest, brawo!"),
        "oops": segment(g, "oops", "Hmm, posłuchaj."),
        "not_heard": segment(g, "not_heard", "Nie usłyszałam odpowiedzi, ale nic nie szkodzi."),
        "think": segment(g, "think", "Pomyśl chwilę. Prawda czy nie?"),
        "thinking": segment(g, "thinking", sound=tone(220, 1.0, 0.03)),
        "outro_great": segment(g, "outro_great", "Wow, prawie wszystko dobrze! Jesteś mistrzem prawdy. To koniec zabawy."),
        "outro_good": segment(g, "outro_good", "Świetnie się bawiliśmy! Następnym razem zagramy znowu. To koniec zabawy."),
    }
    steps = {"intro": {"type": "play", "asset": "intro", "next": f"q_{statements[0][0]}"}}
    for i, (name, true, text, answer) in enumerate(statements):
        nxt = f"q_{statements[i + 1][0]}" if i + 1 < len(statements) else "score"
        assets[f"q_{name}"] = segment(g, f"q_{name}", f"Uwaga! {text}")
        assets[f"a_{name}"] = segment(g, f"a_{name}", answer)
        steps[f"q_{name}"] = {"type": "play", "asset": f"q_{name}", "next": f"answer_{name}"}
        right, wrong = f"right_{name}", f"wrong_{name}"
        steps[f"answer_{name}"] = {
            "type": "choice", "window_ms": 7000,
            "options": {"clap": right if true else wrong, "voice_activity": wrong if true else right},
            "on_timeout": f"missed_{name}",
            "fallback": {
                "no_microphone": {"type": "play", "asset": "think", "next": f"pause_{name}"},
                "screen_locked": "same_as_no_microphone",
                "input_error": "same_as_no_microphone",
            },
        }
        steps[f"pause_{name}"] = {"type": "wait", "duration_ms": 4000, "loop_asset": "thinking", "next": f"a_{name}"}
        steps[right] = {"type": "set", "var": "score", "op": "inc", "next": f"praise_{name}"}
        steps[f"praise_{name}"] = {"type": "play", "asset": "correct", "next": f"a_{name}"}
        steps[wrong] = {"type": "play", "asset": "oops", "next": f"a_{name}"}
        steps[f"missed_{name}"] = {"type": "play", "asset": "not_heard", "next": f"a_{name}"}
        steps[f"a_{name}"] = {"type": "play", "asset": f"a_{name}", "next": nxt}
    steps["score"] = {"type": "branch", "if": {"var": "score", "gt": 4}, "then": "end_great", "else": "end_good"}
    steps["end_great"] = {"type": "end", "asset": "outro_great"}
    steps["end_good"] = {"type": "end", "asset": "outro_good"}
    return game(g, steps, assets, variables={"score": 0}, engine=2)


def item(id_, title, description, script, situations, requirements, minutes, access="paid"):
    return {
        "id": id_, "kind": "interactive_game", "title": title, "parent_description": description,
        "age_min": 3, "duration_sec": minutes * 60, "situations": situations, "requirements": requirements,
        "skills": ["słuchanie"], "access": access, "audio": [], "script": script,
        "timing_sensitive": script["timing_sensitive"],
    }


def main():
    games = [
        item("zgadnij-dzwiek", "Zgadnij dźwięk (prototyp)",
             "Dziecko słucha odgłosów i mówi, co to. Aplikacja nie ocenia odpowiedzi: po chwili podaje rozwiązanie. "
             "Z mikrofonem (opcjonalnie) zauważa, że dziecko coś powiedziało, i szybciej przechodzi dalej.",
             zgadnij_dzwiek(), ["podroz", "w_domu"], ["mikrofon"], 3, access="free"),
        item("zamrozony-taniec", "Zamrożony taniec (prototyp)",
             "Gdy gra muzyka, dziecko tańczy; na „stop” zamienia się w posąg. Telefon leży, aplikacja niczego nie mierzy.",
             taniec("zamrozony-taniec", "Kiedy gra muzyka, tańczymy w miejscu. Kiedy usłyszysz stop, zamieniamy się w posągi! Uwaga, zaczynamy."),
             ["w_domu"], ["miejsce_do_ruchu"], 2),
        item("zamrozone-raczki", "Zamrożone rączki (prototyp, w podróży)",
             "Wersja do samochodu: tańczą tylko rączki i minki, bez wstawania z fotelika.",
             taniec("zamrozone-raczki", "W podróży tańczą tylko rączki i minki. Kiedy usłyszysz stop, rączki zamarzają! Uwaga, zaczynamy."),
             ["podroz"], [], 2),
        item("echo-rytmu", "Echo rytmu (prototyp)",
             "Aplikacja klaszcze rytm, dziecko go powtarza. Z mikrofonem (opcjonalnie) aplikacja słyszy klaskanie, ale nie ocenia, "
             "czy rytm był dokładny. Bez mikrofonu daje czas i przypomina rytm.",
             echo_rytmu(), ["w_domu"], ["mikrofon"], 2),
        item("prawda-czy-nie", "Prawda czy nie? (prototyp)",
             "Dziecko słucha zdań i odpowiada bez dotykania telefonu: klaśnięcie to „prawda”, głośne „nie” to nieprawda. "
             "Z mikrofonem (opcjonalnie) aplikacja reaguje na odpowiedź i liczy punkty; bez mikrofonu daje czas do namysłu "
             "i podaje rozwiązanie.",
             prawda_czy_nie(), ["podroz", "w_domu", "czekanie"], ["mikrofon"], 4, access="free"),
    ]
    catalog = json.loads(CATALOG.read_text())
    ids = {g["id"] for g in games}
    catalog["items"] = [i for i in catalog["items"] if i["id"] not in ids] + games
    catalog["shelves"] = [s for s in catalog["shelves"] if s["id"] != "gry"] + [
        {"id": "gry", "title": "Nowe gry bez ekranu (prototypy)", "kind": "row", "item_ids": [g["id"] for g in games]}
    ]
    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=1) + "\n")

    lines = ["# Teksty do nagrania: prototypy gier (Etap 4)", "",
             "Nagrania zastępcze czyta głos systemowy. Lektor nagrywa poniższe kwestie (mono, bez muzyki pod spodem); "
             "„[dźwięk]” to miejsce na efekt dźwiękowy. Nazwa pliku = nazwa segmentu.", ""]
    for game_id, entries in SCRIPT_LINES.items():
        lines += [f"## {game_id}", "", "| Segment | Tekst |", "|---|---|"]
        lines += [f"| `{name}` | {text} |" for name, text in entries]
        lines.append("")
    (ROOT / "docs/NAGRANIA-DO-GIER.md").write_text("\n".join(lines))
    print(f"{len(games)} games, {sum(len(g['script']['assets']) for g in games)} segments")


if __name__ == "__main__":
    main()
