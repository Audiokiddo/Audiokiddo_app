# Do zrobienia, SEO i prompty do grafik

Stan na 17.10.2026.

## A. Po stronie Dawida (Claude tego nie zrobi)

1. Usunąć konto `claude-tymczasowy` w WordPressie oraz zmienne `WP_USER` / `WP_PASS` z „Edit cloud environment”
   (po zakończeniu wdrożeń). Hasła nie wklejać do rozmowy.
2. Sprawdzić wynik strony głównej na **pagespeed.web.dev** (telefon i komputer). Lokalnie wyszło 96–98 na obu,
   ale środowisko Claude blokuje skrypty śledzące; jeśli u Ciebie < 95, zgłosić (plan: opóźnienie skryptów śledzących).
3. W panelu kliknąć „Update Database” przy WC Price History; sprawdzić komunikat Duplicatora („Encrypted Settings
   Reset”: zmieniony klucz szyfrowania, mogą zniknąć dane dostępowe magazynów kopii).
4. Wgrać do repo **nowy arkusz póz szopa** (16 póz z 17.10) jako pliki (np. `app/assets/szop/nowe/`). Wtedy Claude
   wytnie pozy, zrobi webp i podmieni szopa w hero i w sekcjach wychylania.
5. Wyjaśnić wiadomość „okładki z nimi wracają” (zob. plik 04).
6. Wgrać poprawione PDF-y akt Detektywa na serwer plików (8 plików, zob. `docs/PRZEKAZANIE-PROJEKTU.md`, pkt 4.1).
7. Search Console: zgłosić **obie** mapy strony (indeks Yoast i `ak-poradniki-sitemap.xml`) i poprosić o
   indeksowanie hubów (`/pomysly-na-zabawy/`, `/zagadki-dla-dzieci/`…).

## B. Strona: zadania dla Claude

Z audytu `docs/strona/AUDYT-STRONY-2026-10-10.md` (stan po 3.8.0):

| Punkt audytu | Stan |
|---|---|
| Koszyk otwierał się sam | **Naprawione** (3.7.0) |
| Brak cache stron, 2,5–4,7 s odpowiedzi | **Naprawione** (WP Fastest Cache, ok. 0,9 s) |
| Pliki wtyczki bez cache przeglądarki (hero.webp, logo, czcionki) | Wtyczka ma `assets/.htaccess` z rocznym cache; **po wdrożeniu nie sprawdzono** nagłówków każdego pliku |
| Czcionka dwa razy, ciężki TTF | **Zrobione** (lokalny WOFF2, Google Fonts wycięte na naszych widokach) |
| Duży wspólny CSS | **Zrobione** (386 → 142 KB), dalsze odchudzanie możliwe |
| jQuery/wp-hooks bez `defer` | Skrypty mają `defer`; dalsze porządki opcjonalne |
| `role="dialog"` na `<aside>` szuflady koszyka | Szuflada jest już `<div>`; `role="dialog"` zostaje, dostępność 100 |
| Wiek Detektywa niespójny (7 lat na produkcie, 6 w aplikacji i katalogu) | **Do ujednolicenia** (decyzja Dawida) |
| `robots.txt` z dwiema grupami `User-agent: *` | Do uporządkowania |
| `/zapis-pakiet-darmowy/`: zły tytuł, brak H1/opisu/canonical | Do poprawienia |
| Menu „Pakiety” → `#pakiety` | Na stronie głównej jest już pełna sekcja `#pakiety` |
| `/kontakt/`, regulaminy, polityki bez opisu i H1 | Do uzupełnienia |

Plan SEO (z audytu): (1) Search Console, (2) linkowanie wewnętrzne: sekcja poradników na stronie głównej jest,
trzeba jeszcze w każdym poradniku blok 6–8 linków tematycznych + link do pasującego pakietu, z produktów
2–3 linki do poradników, huby linkują wszystkie swoje strony, (3) rozbudowa filarów (zagadki: 200+ z
odpowiedziami; podróż: samochód, pociąg, samolot, święta; Detektyw do druku: szyfry, podchody, gra detektywistyczna
PDF), poradniki mają dziś 340–830 słów, (4) notka „sprawdzone przez logopedkę” z danymi Person w schemacie na
pakietach i w poradnikach o mowie.

Pomysły na kolejne ulepszenia strony głównej: dźwięk w hero (próbka 15 s przy scenie), ilustrowana „fabryka
zabaw” w sekcji pakietów, mini-quiz „ile masz czasu / ile lat ma dziecko → zabawa na teraz”, licznik „ile
minut bez ekranu uzbierały dzieci” (tylko prawdziwe dane).

## C. Aplikacja (z `docs/PRZEKAZANIE-PROJEKTU.md`)

Interaktywne akta sprawy Detektywa, przebudowa Biblioteki (karty pakietów), „Czas na zakupy” do aplikacji,
poprawa 2 testów, decyzja o kodach dostępu na iOS. Szczegóły tam.

## D. Prompty do grafik (ChatGPT / generator obrazów)

Wspólny dopisek do każdego promptu: *„Ten sam szop pręgowany co na załączonym arkuszu póz: ciepłe taupe-szare
futro, duże ciemnobrązowe plamy wokół oczu z kremową obwódką, pręgowany ogon, delikatna ciemna kontura, styl
miękkiej kreskówki 2.5D. Przezroczyste tło (PNG z alfą), bez tekstu, bez podłogi i cienia, cała postać.
Załączam arkusz póz jako wzorzec tożsamości.”*

1. **Hero, prowadzący grę:** „Szop z cwaniacką miną (jedna brew w górze, półuśmiech), trzyma mikrofon jak
   prowadzący teleturniej, druga łapa wskazuje w bok, wyraźnie bawi się sytuacją.”
2. **Wychylanie zza krawędzi (3 wersje: z prawej, z lewej, z dołu):** „Szop wychyla się zza pionowej krawędzi,
   widać tylko głowę, jedną łapę i fragment ogona, figlarne spojrzenie w stronę środka kadru. Krawędź bez
   rysowania, ciało ucięte prosto przy brzegu obrazu.”
3. **Sekcja „Kupujesz raz”:** „Szop trzyma paczkę z kokardą i telefon, na ekranie telefonu okładka z kolorowych
   zabaw, mina z siebie dumna.”
4. **Sekcja „Jak to działa”:** „Szop zakłada dziecku słuchawki (dziecko widoczne częściowo, od tyłu), ciepłe
   światło, tło przezroczyste.”
5. **Sekcja po przewinięciu / FAQ:** „Szop z lupą i notesem, podejrzliwie zerka z boku.”
6. **Do kafelków poradników (opcjonalnie, kwadrat 1:1, tło w kolorze kremowym):** „Szop w sytuacji: w aucie
   z pasem bezpieczeństwa i kierownicą-zabawką; w piżamie z kubkiem kakao; z książką do góry nogami (nuda).”
7. **Nowe okładki** (jeśli potrzebne): przypomnienie, że okładki zabaw mają format 1:1 (520 px na stronie,
   miniatury 240 px) i w kolorze pakietu (lawenda / turkus / żółty).

Gotowe pozy z repo i prompty bazowe: `docs/szop/PROMPTY.md`, `docs/branding/warianty-prompty.md`.
