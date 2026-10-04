#!/usr/bin/env python3
"""Prepare an isolated Fantazjusz preview. Default mode makes NO network requests.

No key belongs in the mobile app. Explicit --generate consumes ElevenLabs credits.
Original catalog and audio remain untouched; output is in ignored dev_content/.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.error
import urllib.request

import game_content as content

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'dev_content/voice-previews/fantazjusz'


def collect():
    """Capture the source script without invoking say, encoding or rewriting assets."""
    entries = {}
    original = content.segment

    def capture(game, name, speech=None, sound=None, after=None):
        entries[name] = {'speech': speech, 'sound': sound, 'after': after}
        return {'path': f'games/{game}/{name}.m4a', 'bytes': 0, 'sha256': '0' * 64}

    try:
        content.segment = capture
        content.zgubiona_gwiazdka()
    finally:
        content.segment = original
    return entries


def plan(entries, names):
    return [{'segment': name, 'before_effect': entries[name]['speech'],
             'has_effect': entries[name]['sound'] is not None,
             'after_effect': entries[name]['after']} for name in names]


def speak(text, voice, key, model, target):
    request = urllib.request.Request(
        f'https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128',
        data=json.dumps({'text': text, 'model_id': model, 'language_code': 'pl',
                         'voice_settings': {'stability': 0.5, 'similarity_boost': 0.75}}).encode(),
        headers={'xi-api-key': key, 'Content-Type': 'application/json', 'Accept': 'audio/mpeg'},
        method='POST',
    )
    # No automatic retries: an ambiguous network failure may already have consumed credits.
    with urllib.request.urlopen(request, timeout=90) as response:
        if not response.headers.get('Content-Type', '').startswith('audio/'):
            raise ValueError('The service did not return audio.')
        data = response.read()
    if not data:
        raise ValueError('Empty audio response.')
    target.write_bytes(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--segments', nargs='+', default=['intro'])
    parser.add_argument('--generate', action='store_true')
    parser.add_argument('--max-characters', type=int, default=2000)
    parser.add_argument('--model', default='eleven_multilingual_v2')
    args = parser.parse_args()
    entries = collect()
    names = list(dict.fromkeys(args.segments))
    if any(name not in entries for name in names):
        parser.error('Unknown segment. Available: ' + ', '.join(entries))
    lines = plan(entries, names)
    characters = sum(len(text or '') for row in lines for text in (row['before_effect'], row['after_effect']))
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'plan.json').write_text(json.dumps({'characters': characters, 'segments': lines}, ensure_ascii=False, indent=2))
    print(f'Prepared {len(names)} segment(s), {characters} characters. Plan: {OUT / "plan.json"}')
    if not args.generate:
        print('Preparation only. No audio generated, no API call, no credits consumed.')
        return
    if characters > args.max_characters:
        parser.error('Character limit exceeded; review the plan before increasing it.')
    key = os.environ.get('ELEVENLABS_API_KEY', '')
    voice = os.environ.get('ELEVENLABS_VOICE_ID', '')
    if not key or not re.fullmatch(r'[A-Za-z0-9_-]+', voice):
        parser.error('Set ELEVENLABS_API_KEY and the uploaded Fantazjusz ELEVENLABS_VOICE_ID locally.')
    targets = {name: OUT / f'{name}.m4a' for name in names}
    if any(path.exists() for path in targets.values()):
        parser.error('A preview already exists. Archive/review it before regenerating; no files overwritten.')
    updates = {}
    try:
        for name in names:
            row = entries[name]
            with tempfile.TemporaryDirectory() as tmp:
                parts = []
                for number, text in enumerate([row['speech'], None, row['after']]):
                    path = Path(tmp) / f'{number}.mp3'
                    if number == 1 and row['sound'] is not None:
                        path = path.with_suffix('.wav')
                        content.write_wav(row['sound'], path)
                    elif text:
                        speak(text, voice, key, args.model, path)
                    else:
                        continue
                    parts.append(path)
                if not parts:
                    raise ValueError('Segment has no audio parts.')
                content.encode(parts, targets[name])
            data = targets[name].read_bytes()
            updates[name] = {'path': f'voice-previews/fantazjusz/{name}.m4a', 'bytes': len(data),
                             'sha256': hashlib.sha256(data).hexdigest()}
    except urllib.error.HTTPError as error:
        raise SystemExit(f'ElevenLabs returned HTTP {error.code}; no automatic retry. Check account and voice permissions.') from None
    except (urllib.error.URLError, TimeoutError, ValueError, subprocess.CalledProcessError):
        raise SystemExit('Preview stopped. Check connectivity, account and encoder. Some calls may have consumed credits; inspect output before retrying.') from None
    catalog = json.loads(content.CATALOG.read_text())
    item = next(i for i in catalog['items'] if i['id'] == 'zgubiona-gwiazdka')
    item['script']['assets'].update(updates)
    # Invalidate game snapshots and caches only in this separate review catalog.
    item['script']['version'] += 1
    (OUT / 'catalog-preview.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2))
    print('Preview ready in the isolated directory. Production catalog and mobile app unchanged.')


if __name__ == '__main__':
    main()
