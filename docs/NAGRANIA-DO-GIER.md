# Teksty do nagrania: prototypy gier (Etap 4)

Nagrania zastępcze czyta głos systemowy. Lektor nagrywa poniższe kwestie (mono, bez muzyki pod spodem); „[dźwięk]” to miejsce na efekt dźwiękowy. Nazwa pliku = nazwa segmentu.

## zgadnij-dzwiek

| Segment | Tekst |
|---|---|
| `intro` | Cześć! Zagramy w zgadywanie dźwięków. Posłuchaj uważnie i powiedz na głos, co słyszysz. |
| `heard_you` | Słyszę, że masz pomysł! Sprawdźmy. |
| `outro` | Brawo za uważne słuchanie! To już koniec zabawy. |
| `q_dzwonek` | Posłuchaj. … [dźwięk] … Co to za dźwięk? |
| `a_dzwonek` | To był dzwonek do drzwi! Ktoś przyszedł w odwiedziny. |
| `q_deszcz` | Posłuchaj. … [dźwięk] … Co to za dźwięk? |
| `a_deszcz` | To był deszcz! Kap, kap, kap. |
| `q_zegar` | Posłuchaj. … [dźwięk] … Co to za dźwięk? |
| `a_zegar` | To był zegar! Tik, tak, tik, tak. |

## zamrozony-taniec

| Segment | Tekst |
|---|---|
| `intro` | Kiedy gra muzyka, tańczymy w miejscu. Kiedy usłyszysz stop, zamieniamy się w posągi! Uwaga, zaczynamy. |
| `stop` | Stop! Zamieniamy się w posągi! |
| `go` | Tańczymy dalej! |
| `outro` | Ale z Was świetne posągi! Koniec tańca. |

## zamrozone-raczki

| Segment | Tekst |
|---|---|
| `intro` | W podróży tańczą tylko rączki i minki. Kiedy usłyszysz stop, rączki zamarzają! Uwaga, zaczynamy. |
| `stop` | Stop! Zamieniamy się w posągi! |
| `go` | Tańczymy dalej! |
| `outro` | Ale z Was świetne posągi! Koniec tańca. |

## echo-rytmu

| Segment | Tekst |
|---|---|
| `intro` | Zagramy w echo! Ja zaklaszczę rytm, a potem ty klaśniesz tak samo. |
| `your_turn` | Teraz ty! |
| `heard_claps` | Słyszę klaskanie! |
| `again` | Posłuchaj jeszcze raz, jak to brzmiało. |
| `outro` | Super rytm! To już koniec zabawy. |

## prawda-czy-nie

| Segment | Tekst |
|---|---|
| `intro` | Cześć! Zagramy w Prawda czy nie. Powiem ci jedno zdanie. Jeśli to prawda, klaśnij raz! Jeśli to nieprawda, powiedz głośno: nie! Gotowi? Zaczynamy. |
| `correct` | Tak jest, brawo! |
| `oops` | Hmm, posłuchaj. |
| `not_heard` | Nie usłyszałam odpowiedzi, ale nic nie szkodzi. |
| `think` | Pomyśl chwilę. Prawda czy nie? |
| `outro_great` | Wow, prawie wszystko dobrze! Jesteś mistrzem prawdy. To koniec zabawy. |
| `outro_good` | Świetnie się bawiliśmy! Następnym razem zagramy znowu. To koniec zabawy. |
| `q_krowa` | Uwaga! Krowa mówi muuu. |
| `a_krowa` | To prawda! Krowa mówi muuu. |
| `q_ryby` | Uwaga! Ryby mieszkają na drzewach. |
| `a_ryby` | Nie! Ryby mieszkają w wodzie. |
| `q_snieg` | Uwaga! Śnieg jest zimny. |
| `a_snieg` | To prawda! Śnieg jest zimniutki. |
| `q_slon` | Uwaga! Słoń jest mniejszy od myszki. |
| `a_slon` | Nie! Słoń jest ogromny, a myszka malutka. |
| `q_lato` | Uwaga! Latem jest cieplej niż zimą. |
| `a_lato` | To prawda! Latem świeci ciepłe słońce. |
| `q_auta` | Uwaga! Samochody jeżdżą po chmurach. |
| `a_auta` | Nie! Samochody jeżdżą po drogach. |

## Prawdziwe nagrania zabaw (wgrywanie do aplikacji)

Stan (3.10.2026): prawdziwe nagrania mają pakiety **Słowa i Wiedza**, **Wyobraźnia** i **Detektyw** (wgrane do katalogu, czekają na serwer). Piosenki grają jeszcze głosem zastępczym z syntezatora.

1. Wrzuć pliki (MP3, M4A, WAV) do `AudioKiddo-materialy/<folder>/`, po jednym na zabawę, z **tytułem zabawy w nazwie pliku**, np. `Znikające dzwonki rowerowe.mp3` albo `3. Mikstura.wav`. Foldery: `detektyw`, `wyobraznia`, `slowa-i-wiedza`, `piosenki`.
2. `python3 tool/import_recordings.py` (najpierw można sprawdzić na sucho: `--dry-run`). Skrypt wypisuje, co do czego dopasował i które pliki nie pasują do żadnej zabawy. Konwertuje na AAC 96 kb/s, wpisuje prawdziwy czas i sumy kontrolne do katalogu i od nowa wycina darmowe fragmenty.
   PDF-y w tym samym folderze: plik z „Akta sprawy” w nazwie i tytułem zabawy trafia do tej zabawy jako wydruk, plik zaczynający się od „Przewodnik” to bezpłatny przewodnik pakietu (strona pakietu w aplikacji). Duże PDF-y są zmniejszane (`tool/shrink_pdf.py`, np. akta 13 MB → 3 MB).
3. `tool/files_update.sh detektyw wyobraznia slowa-i-wiedza` robi osobny ZIP dla każdego pakietu (bez zmiany klucza). Wgraj je do `wp-content/plugins/audiokiddo-pliki/` przez Menedżer plików LH.pl i rozpakuj z nadpisaniem. Nowe pliki z przewodnikami wymagają jeszcze `supabase db push`.
4. `python3 tool/verify_server_files.py` sprawdza, czy pliki na serwerze zgadzają się z katalogiem (rozmiar i suma kontrolna); darmowe zabawy, fragmenty i przewodniki sprawdza w całości, płatne pomija.
5. `tool/phone_build.sh` (i później wersja sklepowa): katalog z nowymi sumami kontrolnymi jest w aplikacji. Instalować dopiero po kroku 3, bo inaczej telefon odrzuci pobranie (suma się nie zgodzi).

## Głos Szop’ena (aplikacja)

Krótkie kwestie Szop'ena von Ekrana do dziecka (ciepły, łagodny ton), wbudowane w aplikację (`app/assets/audio/kiddo/`). Radośnie, z uśmiechem, bez muzyki pod spodem.

| Plik | Tekst |
|---|---|
| `volume.m4a` | Hej! Podgłośnij telefon, żeby dobrze mnie słyszeć! |
| `hello.m4a` | Cześć! Jestem Szop'en. Mam pasiasty ogon i jeszcze większą ochotę na przygody. Gramy bez patrzenia w ekran! |
| `password_voice.m4a` | Żeby wejść do świata AudioKiddo, powiedz głośno magiczne hasło: Abrakadabra! |
| `password_tap.m4a` | Żeby wejść do świata AudioKiddo, powiedz głośno: Abrakadabra! I dotknij magicznej kuli! |
| `granted.m4a` | Hurra! Dostęp przyznany! Wchodzimy! |
| `kids_1.m4a` | Uszy gotowe? Moje są małe, ale słyszą wszystko. Nawet szelest cukierka. |
| `kids_2.m4a` | Potrzebuję kogoś z wyobraźnią. Ja mam głównie futro i paski. Wchodzisz w to? |
| `kids_3.m4a` | Jeśli usłyszysz burczenie, to mój brzuch. Tego nie liczymy. Wybierz zabawę! |
| `trip_start.m4a` | Ruszamy w drogę! Zapnijcie pasy. Ja pilnuję zagadek, a ty wypatruj czerwonego auta. |
| `window_1.m4a` | Przerwa na okno! Policz, ile czerwonych samochodów zobaczysz, zanim wrócimy do zabawy. |
| `window_2.m4a` | Przerwa na okno! Czy widzisz jakieś zwierzę? Opowiedz o nim rodzicom. |
| `window_3.m4a` | Przerwa na okno! Znajdź coś zielonego, coś okrągłego i coś bardzo dużego. |
| `trip_end.m4a` | Dojechaliśmy! Mój pasiasty ogon mówi, że to była świetna podróż. Do usłyszenia! |
| `bedtime_start.m4a` | Czas na wyciszenie. Zróbmy razem trzy spokojne oddechy. Wdech. I wydech. Wdech. I wydech. Wdech. I wydech. |
| `goodnight.m4a` | Dobranoc. Nos pod koc, uszy na poduszkę. Resztę przygód zostawimy na jutro. |
| `diploma.m4a` | Brawo! Cały pakiet ukończony. Oto twój dyplom. Jestem z ciebie bardzo dumny! |
| `bonus_wyobraznia.m4a` | Sekretna wiadomość od Szop'ena. Dziś w nocy twoje łóżko zamieni się w statek. Dokąd popłyniesz? Opowiedz o tym rodzicom przy śniadaniu! |
| `bonus_slowa-i-wiedza.m4a` | Sekretna zagadka od Szop'ena. Ma cztery nogi, ale nie chodzi. Stoi w kuchni i czeka na obiad. Co to? To stół! |
| `bonus_detektyw.m4a` | Tajne zadanie dla detektywa. Znajdź w domu trzy rzeczy, które zaczynają się na literę K. Szepnij je rodzicowi do ucha. Sprawa zamknięta! |
| `bonus_inne.m4a` | Sekretna wiadomość od Szop'ena. Jesteś prawdziwym mistrzem słuchania. Przybij piątkę rodzicowi! |
