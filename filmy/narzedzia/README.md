# Narzędzia do filmów

## Podłączenie Higgsfield i ElevenLabs (raz, w ustawieniach środowiska)

Klucze dodajesz jako **Network secrets**: serwer dokleja je do zapytań poza sesją, więc Claude
ich nie widzi, a nie ma ich w kodzie, w zmiennych ani w czacie.

Strzałka przy tytule sesji → **Edit cloud environment** → **Network secrets** → **Add secret**:

| Pole | Higgsfield | ElevenLabs |
|---|---|---|
| Name | `Higgsfield` | `ElevenLabs` |
| Allowed websites | `api.higgsfield.ai` | `api.elevenlabs.io` |
| Custom header: Name | `Authorization` | `xi-api-key` |
| Custom header: Prefix | `Key` | (puste) |
| Custom header: Value | `KEY_ID:KEY_SECRET` (oba z Higgsfield Console, z dwukropkiem) | klucz API z ElevenLabs |

Potem **Connect** przy każdym sekrecie. W **Network access → Allowed domains** dopisz jeszcze
`docs.higgsfield.ai`, `*.higgsfield.ai` i `elevenlabs.io` (dokumentacja i pobieranie
wygenerowanych plików) i kliknij **Save changes**.

## Skrypty

- `elevenlabs.py` – lista głosów, kwestia lektora (`say`), efekt dźwiękowy (`sfx`).
- Higgsfield: klient powstanie po podłączeniu klucza, na podstawie aktualnej dokumentacji API
  (obraz → wideo, tekst → wideo; dźwięk, jeśli model go oferuje).
- Montaż: `ffmpeg` (jest w środowisku).
