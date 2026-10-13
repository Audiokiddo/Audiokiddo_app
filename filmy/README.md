# Filmy AudioKiddo

Każdy film ma swój folder: `NN-krotka-nazwa/`. W środku zawsze ten sam układ:

| Folder / plik | Co tam jest |
|---|---|
| `SCENARIUSZ.md` | cel filmu, format, lista scen (obraz, ruch, tekst lektora, dźwięk, czas) |
| `sceny/` | prompty i ustawienia każdej sceny (`01.md`, `02.md`…), żeby dało się ją wygenerować ponownie |
| `grafiki/` | klatki startowe i obrazy referencyjne (Szop’en, okładki, zrzuty aplikacji) |
| `audio/` | lektor, muzyka, efekty |
| `wideo/` | wygenerowane ujęcia, po jednym pliku na scenę i wersję (`01-v1.mp4`) |
| `eksport/` | zmontowany film w gotowych formatach (9:16, 1:1, 16:9) |

Duże pliki (wideo, audio, obrazy) nie trafiają do repozytorium: zostają na dysku. W repozytorium są
scenariusze i prompty.

Narzędzia: Higgsfield (`higgsfield`, obraz i wideo), ElevenLabs (lektor i muzyka), DaVinci Resolve (montaż).

## Filmy

| Nr | Folder | Temat | Stan |
|---|---|---|---|
| 01 | `01-pierwszy-film/` | do ustalenia | czeka na materiały |
