#!/usr/bin/env python3
"""Renders a Care episode (docs/care/odcinki/<id>.json) to one m4a with ElevenLabs voices.

Each speech segment is bought once (cached by voice and text, like tool/ui_voice.py), the pauses
are silence, and the sounds marked "sfx" are left as a second of quiet for now. The result goes to
app/assets/audio/care/<id>.m4a, with <id>.timeline.json next to it (where every segment starts and
how long every pause is) and a readable script in docs/care/odcinki/<id>.md.

  python3 tool/care_episode.py tacka-czy-taczka --dry-run     # characters to buy, nothing is sent
  python3 tool/care_episode.py tacka-czy-taczka               # records the episode
  python3 tool/care_episode.py tacka-czy-taczka --silent       # no ElevenLabs: speech as silence, to test the assembly

The ElevenLabs key is read from the macOS keychain (elevenlabs-api-key); it is never printed.
There is no automatic retry: a failed call may already have used credits.
"""
import argparse
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import ui_voice  # noqa: E402  (eleven_speech, ELEVEN_MODEL, CACHE are reused)

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "docs/care/odcinki"
OUT = ROOT / "app/assets/audio/care"
SFX_SECONDS = 1.0


def load(episode):
    path = SCRIPTS / f"{episode}.json"
    if not path.exists():
        raise SystemExit(f"Brak scenariusza: {path}")
    return json.loads(path.read_text())


def cached(voice, text):
    key = hashlib.sha1(f"{ui_voice.ELEVEN_MODEL}|{text}".encode()).hexdigest()
    return (ui_voice.CACHE / voice / (key + ".mp3")).exists()


def to_wav(source, target):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(source), "-ac", "1", "-ar", "44100",
                    "-c:a", "pcm_s16le", str(target)], check=True)


def silence(seconds, target):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
                    "-t", f"{seconds:.3f}", "-c:a", "pcm_s16le", str(target)], check=True)


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True).stdout.strip()
    return float(out)


def markdown(script):
    lines = [f"# {script['title']} ({script['pack']})", "", f"Wiek: {script['age']}", "", f"> {script['status']}", ""]
    lines += [f"- {n}" for n in script["notes"]]
    names = {"szop": "Szop'en", "szuszu": "Szuszu"}
    for seg in script["segments"]:
        if "sec" in seg:
            lines += ["", f"## {seg['sec']}", ""]
        if "t" in seg:
            lines.append(f"**{names[seg['v']]}:** {seg['t']}")
            lines.append("")
        elif "pause" in seg:
            lines += [f"[PAUZA {seg['pause']:g} s]", ""]
        elif "sfx" in seg:
            lines += [f"[DŹWIĘK: {seg['sfx']}]", ""]
    return "\n".join(lines).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("episode")
    parser.add_argument("--dry-run", action="store_true", help="only count the characters to buy")
    parser.add_argument("--silent", action="store_true", help="no ElevenLabs: speech is silence of a plausible length")
    parser.add_argument("--limit", type=int, default=3000, help="most characters to buy in one run (default 3000)")
    args = parser.parse_args()

    script = load(args.episode)
    voices = script["voices"]
    speech = [(voices[s["v"]], s["t"]) for s in script["segments"] if "t" in s]
    cost = sum(len(t) for v, t in speech if not cached(v, t))
    total = sum(len(t) for _, t in speech)
    print(f"{len(speech)} wypowiedzi, {total} znaków, do kupienia {cost} (limit {args.limit}).")
    (SCRIPTS / f"{args.episode}.md").write_text(markdown(script))
    if args.dry_run:
        return
    if not args.silent and cost > args.limit:
        raise SystemExit(f"Limit znaków ({args.limit}) byłby przekroczony. Użyj większego --limit.")

    OUT.mkdir(parents=True, exist_ok=True)
    timeline, clock = [], 0.0
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        parts = []
        for i, seg in enumerate(script["segments"]):
            part = tmp / f"{i:03d}.wav"
            if "t" in seg:
                if args.silent:
                    silence(max(1.0, len(seg["t"]) / 14), part)
                else:
                    to_wav(ui_voice.eleven_speech(seg["t"], voices[seg["v"]]), part)
                entry = {"kind": "speech", "voice": seg["v"], "text": seg["t"]}
            elif "pause" in seg:
                silence(seg["pause"], part)
                entry = {"kind": "pause", "seconds": seg["pause"]}
            else:
                silence(SFX_SECONDS, part)
                entry = {"kind": "sfx", "note": seg["sfx"]}
            length = duration(part)
            if "sec" in seg:
                entry["section"] = seg["sec"]
            timeline.append({"start": round(clock, 2), "length": round(length, 2), **entry})
            clock += length
            parts.append(part)
        listing = tmp / "list.txt"
        listing.write_text("".join(f"file '{p}'\n" for p in parts))
        joined = tmp / "all.wav"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(listing),
                        "-c", "copy", str(joined)], check=True)
        ui_voice.encode(joined, OUT / f"{args.episode}.m4a")
    (OUT / f"{args.episode}.timeline.json").write_text(json.dumps(
        {"id": args.episode, "seconds": round(clock, 1), "segments": timeline}, ensure_ascii=False, indent=1))
    print(f"Gotowe: {OUT / (args.episode + '.m4a')} ({clock / 60:.1f} min)")


if __name__ == "__main__":
    main()
