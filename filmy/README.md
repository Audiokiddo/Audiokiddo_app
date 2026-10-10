# Filmy AudioKiddo

Każdy film ma własny folder `NN-krotka-nazwa/` (np. `01-piec-minut-ciszy/`), założony przez skopiowanie `_szablon/`.

## Układ folderu filmu

| Ścieżka | Co tam jest |
|---|---|
| `BRIEF.md` | Cel, platforma (Reels/TikTok/YouTube), format (9:16), długość, postacie, ton, CTA |
| `SCENARIUSZ.md` | Tabela scen: numer, czas, co widać, kto mówi, tekst, efekty, przejście |
| `materialy/` | To, co przysyłasz: referencje, grafiki Szop’ena, szkice, nagrania |
| `sceny/scena-NN/PROMPT.md` | Prompt do Higgsfielda (obraz startowy, ruch, kamera), ustawienia i wybrana wersja |
| `sceny/scena-NN/wersje/` | Wygenerowane wideo danej sceny (v1, v2, …) |
| `audio/lektor/` | Kwestie z ElevenLabs (jeden plik na kwestię, nazwa = numer sceny) |
| `audio/efekty/`, `audio/muzyka/` | Efekty dźwiękowe i muzyka |
| `montaz/` | Zmontowany film, napisy, okładka |
| `LOG.md` | Co wygenerowano, jakim modelem, ile kosztowało, co odrzucono i dlaczego |

## Zasady

- Ciężkie pliki (wideo, audio, obrazy w `wersje/`, `audio/`, `montaz/`) nie trafiają do Gita (patrz `.gitignore`).
  Gotowe filmy lądują na Dysku Google; w repozytorium zostają scenariusze, prompty i log.
- Szop’en ma wyglądać tak samo w każdej scenie: każda scena startuje z tej samej referencji
  (`materialy/` albo `docs/szop/`), a prompt opisuje postać tymi samymi słowami.
- Wideo i obraz: Higgsfield. Głos: Higgsfield, jeśli da radę; inaczej ElevenLabs. Montaż: ffmpeg.
- Klucze API nie są w kodzie ani w czacie: dokleja je serwer jako Network secrets środowiska
  (patrz `narzedzia/README.md`).
