#!/usr/bin/env python3
"""ElevenLabs for the films: list voices, speak a line, make a sound effect.

The API key is never in this file or in the environment of a cloud session: the agent proxy
attaches it to requests for api.elevenlabs.io (a Network secret, header xi-api-key). On a
local machine, ELEVENLABS_API_KEY is used instead when set.

  python3 elevenlabs.py voices
  python3 elevenlabs.py say VOICE_ID "Tekst kwestii" out.mp3 [--model eleven_v3]
  python3 elevenlabs.py sfx "door creak, cartoon" out.mp3 [--seconds 2]
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

API = 'https://api.elevenlabs.io'


def call(path: str, body: dict | None = None) -> bytes:
    headers = {'Accept': '*/*'}
    if os.environ.get('ELEVENLABS_API_KEY'):
        headers['xi-api-key'] = os.environ['ELEVENLABS_API_KEY']
    data = None
    if body is not None:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(body).encode()
    req = urllib.request.Request(API + path, data=data, headers=headers, method='POST' if body is not None else 'GET')
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        sys.exit(f'ElevenLabs {e.code}: {e.read().decode(errors="replace")[:500]}')


def main() -> None:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('voices')
    say = sub.add_parser('say')
    say.add_argument('voice')
    say.add_argument('text')
    say.add_argument('out')
    say.add_argument('--model', default='eleven_v3')
    sfx = sub.add_parser('sfx')
    sfx.add_argument('text')
    sfx.add_argument('out')
    sfx.add_argument('--seconds', type=float)
    a = ap.parse_args()

    if a.cmd == 'voices':
        for v in json.loads(call('/v2/voices?page_size=100'))['voices']:
            print(f"{v['voice_id']}  {v['name']}  ({v.get('category', '')})")
    elif a.cmd == 'say':
        audio = call(f'/v1/text-to-speech/{a.voice}?output_format=mp3_44100_128',
                     {'text': a.text, 'model_id': a.model, 'language_code': 'pl'})
        open(a.out, 'wb').write(audio)
        print(a.out, len(audio), 'bytes')
    elif a.cmd == 'sfx':
        body = {'text': a.text}
        if a.seconds:
            body['duration_seconds'] = a.seconds
        audio = call('/v1/sound-generation', body)
        open(a.out, 'wb').write(audio)
        print(a.out, len(audio), 'bytes')


if __name__ == '__main__':
    main()
