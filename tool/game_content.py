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

# Narrator voice: macOS "Zosia" by default (free placeholder). With --voice NAME the games in
# --games are spoken by that ElevenLabs voice instead (key from the macOS keychain, item
# "elevenlabs-api-key"; never in the repository). Every line is cached by its text, so a
# rerun costs nothing for lines already bought.
ELEVEN = {"voice": None, "games": set(), "model": "eleven_v4", "spent": 0, "limit": 6000}
ELEVEN_VOICES = {"nela": "PCOFCZ4Ict9D0opt85il", "fantazjusz": "ijH86K9sA5IEvCDBMgFn"}
TTS_CACHE = OUT / "tts-cache"


def _eleven_key():
    key = subprocess.run(["security", "find-generic-password", "-a", "audiokiddo", "-s", "elevenlabs-api-key", "-w"],
                         capture_output=True, text=True).stdout.strip()
    if not key:
        raise SystemExit("Brak klucza ElevenLabs w pęku kluczy (elevenlabs-api-key).")
    return key


def speak(text, target, game):
    """Writes [text] spoken by the narrator to [target] (aiff for say, mp3 for ElevenLabs)."""
    if ELEVEN["voice"] and game in ELEVEN["games"]:
        import urllib.request
        voice = ELEVEN_VOICES[ELEVEN["voice"]]
        cache = TTS_CACHE / ELEVEN["voice"] / (hashlib.sha1(f'{ELEVEN["model"]}|{text}'.encode()).hexdigest() + ".mp3")
        if not cache.exists():
            if ELEVEN["spent"] + len(text) > ELEVEN["limit"]:
                raise SystemExit(f'Limit znaków ({ELEVEN["limit"]}) osiągnięty; przerwano bez dalszych kosztów.')
            cache.parent.mkdir(parents=True, exist_ok=True)
            request = urllib.request.Request(
                f"https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128",
                data=json.dumps({"text": text, "model_id": ELEVEN["model"], "language_code": "pl",
                                 "voice_settings": {"stability": 0.5, "similarity_boost": 0.8}}).encode(),
                headers={"xi-api-key": _eleven_key(), "Content-Type": "application/json"}, method="POST")
            # No automatic retry: a failed call may already have used credits.
            with urllib.request.urlopen(request, timeout=120) as response:
                data = response.read()
            if not data:
                raise SystemExit("ElevenLabs zwrócił pusty plik.")
            cache.write_bytes(data)
            ELEVEN["spent"] += len(text)
        target.write_bytes(cache.read_bytes())
        return target
    subprocess.run(["say", "-v", "Zosia", "-o", str(target), text], check=True)
    return target


def segment(game, name, speech=None, sound=None, after=None):
    """speech → sound → speech (after). Returns the asset entry."""
    target = OUT / "games" / game / f"{name}.m4a"
    if speech or after:
        SCRIPT_LINES.setdefault(game, []).append((name, " … ".join(t for t in [speech, "[dźwięk]" if sound else None, after] if t)))
    fresh_voice = ELEVEN["voice"] and game in ELEVEN["games"]
    if not target.exists() or fresh_voice:
        with tempfile.TemporaryDirectory() as tmp:
            parts = []
            for i, text in enumerate([speech, None, after]):
                if i == 1 and sound is not None:
                    p = pathlib.Path(tmp) / "sound.wav"
                    # Effects sit under a real narrator, never above her.
                    write_wav([v * 0.45 for v in sound] if fresh_voice else sound, p)
                    parts.append(p)
                elif text:
                    parts.append(speak(text, pathlib.Path(tmp) / f"s{i}.{'mp3' if fresh_voice else 'aiff'}", game))
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


def wind(seconds):
    rnd = random.Random(11)
    out, last = [], 0.0
    for i in range(int(RATE * seconds)):
        last = 0.995 * last + 0.005 * rnd.uniform(-1, 1)
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * 0.35 * i / RATE)
        out.append(9.0 * last * swell)
    return out


def plum():
    n = int(RATE * 0.25)
    out, phase = [], 0.0
    for i in range(n):
        phase += 2 * math.pi * (700 - 2000 * i / RATE) / RATE
        out.append(0.5 * math.sin(phase) * math.exp(-14 * i / RATE))
    return out + silence(0.25)


def quack():
    n = int(RATE * 0.18)
    return [0.3 * (1 if math.sin(2 * math.pi * 480 * i / RATE) > 0 else -1) * math.exp(-8 * i / RATE)
            for i in range(n)] + silence(0.3)


def chime(seconds=2.5):
    out = silence(int(seconds * RATE) / RATE)
    for k, f in enumerate([1047, 1319, 1568, 2093, 1568, 2093]):
        start = int(k * 0.22 * RATE)
        for i, v in enumerate(tone(f, 0.9, 0.18, decay=4)):
            if start + i < len(out):
                out[start + i] += v
    return out


WORDS = "words"  # marks engine-3 steps for the narrator list


def word_decision(g, steps, assets, key, question, words, again, auto, auto_target, clap_question, clap_targets,
                  sound=None, after=None):
    """A question answered with a word. Without word recognition the same question is asked
    with a clap (first option) or a spoken word (second); without a microphone the narrator
    picks [auto_target] herself. Not heard twice: the narrator picks too."""
    assets[key] = segment(g, key, question, sound, after)
    assets[f"{key}_again"] = segment(g, f"{key}_again", again)
    assets[f"{key}_auto"] = segment(g, f"{key}_auto", auto)
    assets[f"{key}_claps"] = segment(g, f"{key}_claps", clap_question)
    steps[key] = {"type": "play", "asset": key, "next": f"{key}_answer"}
    steps[f"{key}_answer"] = {
        "type": "choice", "window_ms": 8000, "words": words, "on_timeout": f"{key}_retry",
        "fallback": {
            "no_microphone": {"type": "goto", "target": f"{key}_auto"},
            "screen_locked": "same_as_no_microphone",
            "input_error": "same_as_no_microphone",
            "no_speech": {"type": "goto", "target": f"{key}_claps"},
        },
    }
    steps[f"{key}_retry"] = {"type": "branch", "if": {"var": "score", "gt": -1}, "max_visits": 1,
                             "then": f"{key}_again", "else": f"{key}_auto"}
    steps[f"{key}_again"] = {"type": "play", "asset": f"{key}_again", "next": f"{key}_answer"}
    steps[f"{key}_auto"] = {"type": "play", "asset": f"{key}_auto", "next": auto_target}
    steps[f"{key}_claps"] = {"type": "play", "asset": f"{key}_claps", "next": f"{key}_clap_answer"}
    steps[f"{key}_clap_answer"] = {
        "type": "choice", "window_ms": 8000,
        "options": {"clap": clap_targets[0], "voice_activity": clap_targets[1]},
        "on_timeout": f"{key}_auto",
        "fallback": {"no_microphone": {"type": "goto", "target": f"{key}_auto"},
                     "screen_locked": "same_as_no_microphone", "input_error": "same_as_no_microphone"},
    }


def zgubiona_gwiazdka():
    """Engine 3: a story with five endings; the child chooses the way with words."""
    g = "zgubiona-gwiazdka"
    assets, steps = {}, {}

    def say(name, text=None, sound=None, after=None, next_step=None):
        assets[name] = segment(g, name, text, sound, after)
        steps[name] = {"type": "play", "asset": name, "next": next_step}

    def listen(name, kind, ok, missed, self_text, self_next, window=8000, count=None):
        """Claps or voice; without a microphone the narrator does it herself."""
        assets[f"{name}_self"] = segment(g, f"{name}_self", self_text)
        steps[name] = {"type": "input", "input": kind, "window_ms": window, "on_detected": ok, "on_timeout": missed,
                       "fallback": {"no_microphone": {"type": "play", "asset": f"{name}_self", "next": self_next},
                                    "screen_locked": "same_as_no_microphone", "input_error": "same_as_no_microphone"}}
        if count:
            steps[name]["min_count"] = count

    def ending(name, text):
        assets[name] = segment(g, name, text, chime(), "Chcesz sprawdzić, co by się stało na innej drodze? "
                               "Zagraj jeszcze raz i wybierz inaczej. Koniec bajki.")
        steps[name] = {"type": "end", "asset": name}

    say("intro", "Cześć! Dziś opowiemy bajkę razem, a ty zdecydujesz, co się w niej wydarzy. Tej nocy z nieba spadła "
        "malutka Gwiazdka. Zgubiła się i bardzo chce wrócić do domu. Pomożesz ją odnaleźć? Kiedy o coś zapytam, "
        "odpowiedz głośno jednym słowem. Gotowi? Powiedz głośno: tak!", next_step="ready")
    listen("ready", "voice_activity", "go", "go", "Na pewno jesteście gotowi. Ruszamy!", "cross", window=7000)
    say("go", "Super! Ruszamy w drogę.", next_step="cross")

    word_decision(
        g, steps, assets, "cross",
        "Na trawie świecą dwa ślady Gwiazdki. Jeden prowadzi do Szumiącego Lasu, a drugi nad Srebrną Rzekę. "
        "Dokąd idziemy? Powiedz: las albo rzeka.",
        {"forest": ["las", "do lasu", "lasek", "lasu"], "river": ["rzeka", "nad rzekę", "rzekę", "rzeczka", "rzeki"]},
        "Nie usłyszałam. Powiedz głośno: las! Albo: rzeka!",
        "Dobrze, to ja wybiorę. Ślad przy lesie świeci mocniej. Idziemy do lasu!", "forest",
        "Jeśli chcesz iść do lasu, klaśnij raz. Jeśli nad rzekę, powiedz głośno: rzeka!", ["forest", "river"])

    # --- the forest: an owl's riddle, then the mountain or the hollow ---------------------
    say("forest", "Wchodzimy do Szumiącego Lasu.", wind(3),
        "Na gałęzi siedzi Sowa Mądralka. Hu, hu! Pomogę wam, mówi sowa, jeśli zgadniecie zagadkę. "
        "Kto robi: hau, hau?", next_step="riddle")
    steps["riddle"] = {
        "type": "choice", "window_ms": 8000,
        "words": {"riddle_right": ["pies", "piesek", "psiak", "pieska", "psa"],
                  "riddle_wrong": ["kot", "kotek", "krowa", "kaczka", "kura", "żaba", "koń", "owca"]},
        "on_timeout": "riddle_hint",
        "fallback": {"no_microphone": {"type": "wait", "duration_ms": 4000, "next": "riddle_tell"},
                     "screen_locked": "same_as_no_microphone", "input_error": "same_as_no_microphone"},
    }
    steps["riddle_right"] = {"type": "set", "var": "score", "op": "inc", "next": "riddle_praise"}
    say("riddle_praise", "Brawo! To piesek! Sowa Mądralka aż zahukała z radości.", next_step="owl")
    say("riddle_wrong", "Hmm, to zwierzątko robi inaczej. Hau, hau robi piesek!", next_step="owl")
    steps["riddle_hint"] = {"type": "branch", "if": {"var": "score", "gt": -1}, "max_visits": 1,
                            "then": "riddle_hint_say", "else": "riddle_tell"}
    say("riddle_hint_say", "Podpowiem: to zwierzątko pilnuje domu i merda ogonem. Kto robi hau, hau?",
        next_step="riddle")
    say("riddle_tell", "To piesek! Hau, hau!", next_step="owl")

    word_decision(
        g, steps, assets, "owl",
        "Hu, hu! Widziałam Gwiazdkę, mówi sowa. Poleciała na Wysoką Górę albo schowała się w Starej Dziupli. "
        "Gdzie jej szukamy? Powiedz: góra albo dziupla.",
        {"mountain": ["góra", "na górę", "górę", "góry", "górka"],
         "hollow": ["dziupla", "dziuplę", "do dziupli", "dziupli"]},
        "Nie usłyszałam. Powiedz głośno: góra! Albo: dziupla!",
        "To ja wybiorę: zajrzymy do dziupli!", "hollow",
        "Jeśli na górę, klaśnij raz. Jeśli do dziupli, powiedz głośno: dziupla!", ["mountain", "hollow"])

    say("mountain", "Wspinamy się na Wysoką Górę. Hop, hop, coraz wyżej! Na szczycie wieje zimny wiatr, a Gwiazdka "
        "siedzi na kamieniu i drży z zimna. Żeby wróciła na niebo, trzeba obudzić Wiatr Wędrowca. "
        "Klaśnij trzy razy, mocno!", next_step="wind_claps")
    listen("wind_claps", "clap", "wind_ok", "wind_help", "Posłuchaj… Wiatr Wędrowiec budzi się sam!", "ending_wind",
           count=3)
    say("wind_ok", "Udało się! Wiatr Wędrowiec się obudził!", wind(3), next_step="ending_wind")
    say("wind_help", "Wiatr śpi mocno. Pomogę: klaszczemy razem!", pattern([0.5, 0.5, 0.6]),
        "Obudził się!", next_step="ending_wind")
    ending("ending_wind", "Wiatr Wędrowiec delikatnie podnosi Gwiazdkę i niesie ją wysoko, wysoko, aż na samo niebo. "
           "Spójrz dziś wieczorem w okno. Ta gwiazdka, która mruga najmocniej, mówi ci: dziękuję!")

    word_decision(
        g, steps, assets, "hollow",
        "Zaglądamy do Starej Dziupli. Ciii… W środku śpi Wiewiórka Ruda, a obok niej, zwinięta w kłębek, świeci "
        "Gwiazdka. Też zasnęła! Co robimy? Budzimy ją czy śpiewamy kołysankę? Powiedz: budzimy albo kołysanka.",
        {"wake": ["budzimy", "obudź", "obudzić", "budzić", "pobudka", "budzimy ją"],
         "lullaby": ["kołysanka", "kołysankę", "śpiewamy", "śpiewać", "lulu"]},
        "Nie usłyszałam. Powiedz cichutko: kołysanka. Albo głośno: budzimy!",
        "To ja wybiorę: zaśpiewamy kołysankę.", "lullaby",
        "Jeśli budzimy Gwiazdkę, klaśnij raz. Jeśli śpiewamy kołysankę, powiedz: kołysanka.", ["wake", "lullaby"])
    say("wake", "Pobudka! Gwiazdka otwiera oczka i ziewa. Ale się wyspałam, mówi. Wiewiórka Ruda też się budzi "
        "i woła: znam skrót do nieba!", next_step="ending_squirrel")
    ending("ending_squirrel", "Wiewiórka skacze z gałęzi na gałąź, aż na czubek najwyższej sosny, a Gwiazdka razem "
           "z nią. Stamtąd jednym skokiem wraca na niebo. A Wiewiórka Ruda ma teraz najjaśniejszą lampkę w całym "
           "lesie: co noc Gwiazdka świeci prosto do jej dziupli.")
    say("lullaby", "Śpiewamy cichutko.", melody(6, seed=21), "Gwiazdka uśmiecha się przez sen.",
        next_step="ending_lullaby")
    ending("ending_lullaby", "Gwiazdka śpi w dziupli aż do rana. Kiedy zapada kolejna noc, wypoczęta wraca na niebo, "
           "a Wiewiórka Ruda macha jej łapką na do widzenia. Dobranoc, Gwiazdko!")

    # --- the river: a frog, the stones or the boat ---------------------------------------
    say("river", "Idziemy nad Srebrną Rzekę.", plum() + plum() + rain(2),
        "Na liściu siedzi Żabka Kumka. Kum, kum! Widziałam Gwiazdkę na Wyspie Trzcin, na środku rzeki.",
        next_step="frog")
    word_decision(
        g, steps, assets, "frog",
        "Jak się tam dostaniemy? Skaczemy po kamieniach czy płyniemy łódką? Powiedz: kamienie albo łódka.",
        {"stones": ["kamienie", "po kamieniach", "kamień", "skaczemy", "skakać"],
         "boat": ["łódka", "łódką", "łódź", "łódkę", "płyniemy"]},
        "Nie usłyszałam. Powiedz głośno: kamienie! Albo: łódka!",
        "To ja wybiorę: płyniemy łódką!", "boat",
        "Jeśli skaczemy po kamieniach, klaśnij raz. Jeśli płyniemy łódką, powiedz głośno: łódka!",
        ["stones", "boat"])

    say("stones", "Skaczemy z kamienia na kamień. Przy każdym skoku klaśnij! Trzy skoki. Hop!",
        next_step="stones_claps")
    listen("stones_claps", "clap", "stones_ok", "stones_help", "Hop, hop, hop! Żabka skacze razem z nami.", "island",
           window=9000, count=3)
    say("stones_ok", "Hop, hop, hop! Brawo, ani razu nie wpadliśmy do wody.", next_step="island")
    say("stones_help", "Skaczemy razem!", pattern([0.6, 0.6, 0.6]), "Hop, hop, hop! Jesteśmy na drugim brzegu.",
        next_step="island")
    say("island", "Jesteśmy na Wyspie Trzcin. Ciii… Coś świeci w trzcinach. To Gwiazdka! Ale jej światełko prawie "
        "zgasło. Dodajmy jej sił. Powiedz głośno: świeć!", next_step="shine")
    listen("shine", "voice_activity", "ending_fireflies", "shine_help", "Gwiazdka słyszy, że wszyscy jej kibicują.",
           "ending_fireflies")
    say("shine_help", "Zawołajmy razem: świeć!", next_step="ending_fireflies")
    ending("ending_fireflies", "Na twój głos z trzcin wylatują świetliki. Setki małych światełek otaczają Gwiazdkę, "
           "aż znowu świeci pełnym blaskiem. Świetliki odprowadzają ją na niebo jak mały, świecący pociąg.")

    say("boat", "Wsiadamy do łódki. Żeby płynąć, trzeba wiosłować i mówić: plum! Powiedz głośno: plum!",
        next_step="row")
    listen("row", "voice_activity", "row_ok", "row_help", "Wiosłuję za was: plum, plum!", "ducks")
    say("row_ok", "Plum, plum! Płyniemy!", plum() + plum() + plum(), next_step="ducks")
    say("row_help", "Wiosłuję za was:", plum() + plum() + plum(), next_step="ducks")
    say("ducks", "Obok łódki płynie Mama Kaczka z kaczuszkami. Posłuchaj, ile kaczuszek zakwacze.",
        quack() + quack() + quack(), "Ile ich było? Powiedz liczbę.", next_step="count")
    steps["count"] = {
        "type": "choice", "window_ms": 8000,
        "words": {"count_right": ["trzy", "3", "trzech", "trzej"],
                  "count_wrong": ["jeden", "jedna", "dwa", "dwie", "cztery", "pięć", "sześć"]},
        "on_timeout": "count_tell",
        "fallback": {"no_microphone": {"type": "wait", "duration_ms": 4000, "next": "count_tell"},
                     "screen_locked": "same_as_no_microphone", "input_error": "same_as_no_microphone"},
    }
    steps["count_right"] = {"type": "set", "var": "score", "op": "inc", "next": "count_praise"}
    say("count_praise", "Tak! Trzy kaczuszki! Mama Kaczka jest z was dumna.", next_step="ending_moon")
    say("count_wrong", "Policzmy razem.", quack() + quack() + quack(), "Raz, dwa, trzy. Trzy kaczuszki!",
        next_step="ending_moon")
    say("count_tell", "Były trzy kaczuszki! Raz, dwa, trzy.", next_step="ending_moon")
    ending("ending_moon", "Kaczki prowadzą łódkę tam, gdzie na wodzie leży srebrna ścieżka księżyca. Gwiazdka wskakuje "
           "na nią i biegnie jak po moście, aż na samo niebo. Księżyc mruga do ciebie: dziękuję za pomoc!")

    return game(g, steps, assets, variables={"score": 0}, engine=3)


def item(id_, title, description, script, situations, requirements, minutes, access="paid"):
    return {
        "id": id_, "kind": "interactive_game", "title": title, "parent_description": description,
        "age_min": 3, "duration_sec": minutes * 60, "situations": situations, "requirements": requirements,
        "skills": ["słuchanie"], "access": access, "audio": [], "script": script,
        "timing_sensitive": script["timing_sensitive"],
    }


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", choices=sorted(ELEVEN_VOICES), help="ElevenLabs narrator for --games")
    parser.add_argument("--games", nargs="*", default=[], help="game ids spoken by --voice")
    parser.add_argument("--limit", type=int, default=6000, help="max characters bought in this run")
    args = parser.parse_args()
    ELEVEN.update(voice=args.voice, games=set(args.games), limit=args.limit)
    games = [
        item("zgadnij-dzwiek", "Zgadnij dźwięk",
             "Dziecko słucha odgłosów i mówi, co to. Aplikacja nie ocenia odpowiedzi: po chwili podaje rozwiązanie. "
             "Z mikrofonem (opcjonalnie) zauważa, że dziecko coś powiedziało, i szybciej przechodzi dalej.",
             zgadnij_dzwiek(), ["podroz", "w_domu"], ["mikrofon"], 3, access="free"),
        item("zamrozony-taniec", "Zamrożony taniec",
             "Gdy gra muzyka, dziecko tańczy; na „stop” zamienia się w posąg. Telefon leży, aplikacja niczego nie mierzy.",
             taniec("zamrozony-taniec", "Kiedy gra muzyka, tańczymy w miejscu. Kiedy usłyszysz stop, zamieniamy się w posągi! Uwaga, zaczynamy."),
             ["w_domu"], ["miejsce_do_ruchu"], 2),
        item("zamrozone-raczki", "Zamrożone rączki (w podróży)",
             "Wersja do samochodu: tańczą tylko rączki i minki, bez wstawania z fotelika.",
             taniec("zamrozone-raczki", "W podróży tańczą tylko rączki i minki. Kiedy usłyszysz stop, rączki zamarzają! Uwaga, zaczynamy."),
             ["podroz"], [], 2),
        item("echo-rytmu", "Echo rytmu",
             "Aplikacja klaszcze rytm, dziecko go powtarza. Z mikrofonem (opcjonalnie) aplikacja słyszy klaskanie, ale nie ocenia, "
             "czy rytm był dokładny. Bez mikrofonu daje czas i przypomina rytm.",
             echo_rytmu(), ["w_domu"], ["mikrofon"], 2),
        item("prawda-czy-nie", "Prawda czy nie?",
             "Dziecko słucha zdań i odpowiada bez dotykania telefonu: klaśnięcie to „prawda”, głośne „nie” to nieprawda. "
             "Z mikrofonem (opcjonalnie) aplikacja reaguje na odpowiedź i liczy punkty; bez mikrofonu daje czas do namysłu "
             "i podaje rozwiązanie.",
             prawda_czy_nie(), ["podroz", "w_domu", "czekanie"], ["mikrofon"], 4, access="free"),
        item("zgubiona-gwiazdka", "Zgubiona Gwiazdka",
             "Bajka, w której dziecko wybiera drogę: mówi „las” albo „rzeka”, „góra” albo „dziupla”, rozwiązuje "
             "zagadki i klaszcze. Pięć różnych zakończeń, więc warto wracać. Słowa rozpoznaje sam telefon, bez "
             "internetu i bez nagrywania. Gdy telefon nie rozpoznaje słów, pyta o klaśnięcie; bez mikrofonu "
             "narratorka wybiera drogę sama.",
             zgubiona_gwiazdka(), ["w_domu", "przed_snem", "podroz"], ["mikrofon"], 8, access="free")
        | {"released": "2026-10-03"},
    ]
    catalog = json.loads(CATALOG.read_text())
    ids = {g["id"] for g in games}
    # Fields set elsewhere (release date, preview…) survive regenerating.
    old = {i["id"]: i for i in catalog["items"]}
    games = [{**old.get(g["id"], {}), **g} for g in games]
    catalog["items"] = [i for i in catalog["items"] if i["id"] not in ids] + games
    # "Nowości" come from release dates now; the games row keeps its place.
    games_row = {"id": "gry", "title": "Gry bez ekranu", "kind": "row", "item_ids": [g["id"] for g in games]}
    shelves = [s for s in catalog["shelves"] if s["id"] != "nowosci"]
    at = next((n for n, s in enumerate(shelves) if s["id"] == "gry"), len(shelves))
    catalog["shelves"] = shelves[:at] + [games_row] + shelves[at + 1:]
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
    if ELEVEN["voice"]:
        print(f"ElevenLabs ({ELEVEN['voice']}): kupiono {ELEVEN['spent']} znaków w tym przebiegu")


if __name__ == "__main__":
    main()
