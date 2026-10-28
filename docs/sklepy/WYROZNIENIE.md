# AudioKiddo na stronie głównej App Store i Google Play

Stan: 8 października 2026. Pakiet do wyróżnienia w sklepach: co zrobić i w jakiej kolejności, gotowe zrzuty, teksty do zgłoszeń i wydarzeń. Formularze, prywatność i notatki dla recenzentów są w `docs/SKLEPY.md`, kroki do kont w `docs/WYDANIE.md` i `docs/marketing/SKLEPY-SZYBKA-SCIEZKA.md`.

Miejsca na stronie głównej nie da się kupić. Wybierają redakcje: Apple (zakładka „Dzisiaj”, „Aplikacje dla dzieci”) i Google Play („Wybór redakcji”, polecane w kategorii Dzieci). Możemy natomiast spełnić to, na co patrzą, zgłosić się we właściwym momencie i mieć gotowe materiały.

## 1. Najważniejsze punkty (kolejność)

| # | Co | Kto | Kiedy |
|---|---|---|---|
| 1 | Konta Apple Developer i Google Play Console, aplikacja w obu sklepach | Dawid | teraz (blokuje resztę) |
| 2 | Google Play: **przedrejestracja** od razu po założeniu konta | Dawid | w dniu założenia konta |
| 3 | Zrzuty z tego pakietu (sekcja 2), nazwa, podtytuł i słowa kluczowe (sekcja 3) | gotowe, Dawid wkleja | przy zakładaniu aplikacji |
| 4 | Film podglądu 30 s (sekcja 7) | Dawid nagrywa na symulatorze | przed premierą |
| 5 | **Zgłoszenie do redakcji Apple** (sekcja 4), 6–8 tygodni przed datą | Dawid wysyła | zaraz po pierwszej zatwierdzonej wersji |
| 6 | Google Play: kryteria **„Teacher Approved”** (sekcja 5) | spełnione w aplikacji | przed publikacją |
| 7 | **Wydarzenia w aplikacji** (Apple) i **promocje** (Google), sekcja 6 | gotowe teksty | od premiery, co 4–6 tygodni |
| 8 | Oceny 4,5+: prośba o ocenę po ukończonej zabawie już jest w aplikacji | — | stale |
| 9 | Jakość: zero awarii, szybki start, dostępność; testy aplikacji przechodzą | — | każde wydanie |

**Daty, pod które celujemy:** premiera (najlepiej ferie zimowe, styczeń–luty), Dzień Dziecka 1 czerwca (najmocniejsza data w kategorii Dzieci), wakacje (podróże), Święta (prezenty).

## 2. Zrzuty ekranu (gotowe)

Folder `docs/sklepy/zrzuty/`, po 8 zrzutów w każdym rozmiarze:

| Folder | Rozmiar | Gdzie wgrać |
|---|---|---|
| `app-store-iphone-6.9` | 1320 × 2868 | App Store Connect › iPhone 6,9″ |
| `app-store-iphone-6.5` | 1284 × 2778 | App Store Connect › iPhone 6,5″ |
| `app-store-ipad-13` | 2064 × 2752 | App Store Connect › iPad 13″ (aplikacja wspiera iPada) |
| `google-play-telefon` | 1080 × 1920 | Play Console › Zrzuty z telefonu |
| `google-play-tablet` | 1600 × 2560 | Play Console › Tablet 7″ i 10″ |

Kolejność (pierwsze dwa decydują, bo widać je w wynikach wyszukiwania):
1. „Włącz, połóż telefon, odpocznij”: Start.
2. „Dziecko jest bohaterem przygody”: odtwarzacz z aktami sprawy.
3. „Wszystkie zabawy pod ręką”: Biblioteka z półkami pakietów.
4. „Masz 20 minut? Dobierzemy zabawę”: dobór zabawy.
5. „Cała podróż bez ekranu”: tryb podróży.
6. „Naklejka za każdą przygodę”: album naklejek.
7. „Zagadki Maxa i Mili”: pakiet Detektyw.
8. „Działa bez internetu”: Pobrane.

Zrzuty pochodzą z prawdziwej aplikacji (przykładowa rodzina: Zosia, 5 lat, pakiet Detektyw). Po zmianach w wyglądzie generujesz je ponownie:

```bash
cd app && flutter test tool/store_screens_test.dart && cd .. && python3 tool/store_frames.py
```

Napisy i kolory zmieniasz w `tool/store_frames.py` (lista `CAPTIONS`).

## 3. Nazwa, podtytuł, słowa kluczowe (ASO)

Apple liczy razem nazwę, podtytuł i słowa kluczowe, więc słowa się nie powtarzają.

| Pole | Limit | Tekst |
|---|---|---|
| Nazwa (App Store i Google Play) | 30 | **AudioKiddo: zabawy dla dzieci** (29) |
| Podtytuł (App Store) | 30 | **Audiozabawy bez ekranu 3–9 lat** (30) |
| Słowa kluczowe (App Store) | 100 | `bajki,zagadki,przedszkolak,słuchowisko,dobranoc,logopedia,maluch,podróż,auto,rodzina,mowa,nauka` (95) |
| Krótki opis (Google Play) | 80 | Audiozabawy bez ekranu: dziecko słucha, szuka i odpowiada na głos. 3–9 lat. |
| Tekst promocyjny (App Store, zmieniasz bez aktualizacji) | 170 | Nowość: akta sprawy Detektywa do rozwiązania w telefonie i album naklejek z Szop’enem. Włącz zabawę, połóż telefon, a dziecko słucha, szuka i odpowiada. |

Pełny opis zostaje z `docs/SKLEPY.md`. Na początku dopisz jedno zdanie z najważniejszą obietnicą: „Włączasz zabawę, kładziesz telefon, a dziecko słucha, szuka i odpowiada na głos. Ty masz chwilę dla siebie.”

**Testy A/B strony w sklepie** (po 2–4 tygodniach od premiery):
- Google Play: Play Console › Eksperymenty z informacjami o aplikacji: pierwszy zrzut „Włącz, połóż telefon” kontra „Dziecko jest bohaterem przygody”.
- Apple: App Store Connect › Optymalizacja strony produktu: to samo dla ikon i zrzutów.

## 4. Zgłoszenie do redakcji Apple

App Store Connect › aplikacja › **Featuring Nominations** › nowe zgłoszenie. Formularz jest po angielsku. Wysyłamy 6–8 tygodni przed datą (premiera, nowy pakiet, Dzień Dziecka).

**Typ:** New App Launch (premiera), potem New Content (nowy pakiet).

**Description (do wklejenia):**

> AudioKiddo is a Polish audio-first app of interactive play for children aged 3–9, made by a family team: voice actress Nela and developer Dawid write, record and voice every play themselves.
>
> The parent starts a play and puts the phone face down. The child listens, searches the room, moves, and answers out loud: on-device speech recognition hears short answers like "tak" or a clap, and nothing is ever recorded or sent. Detective cases come with case files the child solves on the phone or on paper.
>
> Built for the Kids category from day one: no ads, no third-party analytics, a parental gate in front of every purchase and link, a kids mode with only big covers, plays that work offline in the car or on a plane, a sleep timer and a bedtime ritual with Szop'en, our raccoon mascot.
>
> Why now: [the launch / the new pack / Children's Day on 1 June]. We would love Polish families to discover screen-free play that still feels like an adventure.

**Additional details:** link do filmu podglądu, 3 najlepsze zrzuty, data wydania, kraj: Polska.

## 5. Google Play: Teacher Approved i Wybór redakcji

**Teacher Approved** (oznaczenie i osobna sekcja „Zatwierdzone przez nauczycieli” w Google Play Dzieci). Aplikacje skierowane do dzieci (program Families, ustawiany w Play Console › Treści aplikacji › Grupa docelowa i treści) oceniają nauczyciele współpracujący z Google. Osobnego formularza nie ma, więc liczy się to, co ocenią w aplikacji. Lista kryteriów:

| Kryterium Google | U nas |
|---|---|
| Odpowiednie dla wieku, bez reklam lub z reklamami zgodnymi z Families | Bez reklam ✅ |
| Wartość edukacyjna lub rozwojowa | Słuchanie, mowa, logiczne myślenie, wyobraźnia; plan rozwoju i postępy ✅ |
| Radość i zaangażowanie | Interakcja głosem, naklejki, Szop’en ✅ |
| Łatwość użycia dla dziecka | Tryb dziecka z dużymi okładkami ✅ |
| Bezpieczeństwo, zakupy za bramką rodzica | Bramka rodzica przed zakupami, linkami, mikrofonem i wyjściem z trybu dziecka ✅ |
| Brak zewnętrznych SDK zbierających dane dzieci | Tylko własny serwer ✅ |
| Opis zgodny z aplikacją, polityka prywatności | `docs/SKLEPY.md`, `docs/strona/sklepy/` ✅ |

**Wybór redakcji i polecane:** redakcja patrzy na ocenę (4,5+), stabilność (Android Vitals: mało awarii i zawieszeń), jakość na tabletach (mamy zrzuty i układ na tablet) i świeżość treści (aktualizacje co kilka tygodni).

**Przedrejestracja** (Play Console › Testy i wersje › Przedrejestracja), opis:
> Audiozabawy bez ekranu dla dzieci 3–9 lat. Zarejestruj się, a w dniu premiery dostaniesz powiadomienie i 3 zabawy na start za darmo.

Nagrody za przedrejestrację Google daje tylko grom, więc obiecaną w opisie niespodziankę realizujemy sami: 3 darmowe zabawy na start są w aplikacji od razu.

## 6. Wydarzenia w aplikacji (Apple) i promocje (Google)

Apple: App Store Connect › In-App Events. Limity: nazwa 30, krótki opis 50, długi opis 120 znaków, obrazek 1920 × 1080 (lub film). Wydarzenie widać na stronie aplikacji, w wynikach wyszukiwania i czasem w zakładce „Dzisiaj”. Google: Play Console › Treści promocyjne (te same teksty, obrazek 1920 × 1080).

| Kiedy | Typ (Apple) | Nazwa (≤30) | Krótki opis (≤50) | Długi opis (≤120) |
|---|---|---|---|---|
| Premiera | Major Update | Dzieci odpowiadają na głos | Audiozabawy, w których dziecko jest bohaterem | Włącz zabawę i połóż telefon. Dziecko słucha, szuka i odpowiada na głos. 3 zabawy na start za darmo. |
| Nowy pakiet | New Season | Nowy pakiet: Detektyw | Zagadki i akta sprawy Maxa i Mili | Pięć spraw do rozwiązania: zagadki, szyfry i akta sprawy, które dziecko rozwiązuje w telefonie albo na papierze. |
| Ferie / wakacje | Special Event | Zabawy na ferie i podróż | Cała droga bez ekranu, także offline | Ułożymy zabawy na całą trasę, z przerwami na wyglądanie przez okno. Pobierz przed wyjazdem, działa bez internetu. |
| Święta | Special Event | Świąteczne zagadki Szop’ena | Prezent bez ekranu z kodem do kartki | Zimowe zagadki dla dzieci 3–9 lat i prezent dla wnuków: kod przychodzi mailem, kartkę drukujecie w domu. |
| Dzień Dziecka | Special Event | Dzień Dziecka z AudioKiddo | Tydzień przygód i naklejki Szop’ena | Tydzień zabaw bez ekranu: zagadki, ruch i przygody, a za każdą ukończoną zabawę naklejka Szop’ena. |

Obrazki do wydarzeń: Szop’en z okładką pakietu na tle w kolorze marki. Mogę je przygotować tym samym narzędziem co zrzuty.

## 7. Film podglądu (30 s)

Apple wymaga, żeby film pokazywał aplikację, a nie animację marketingową. Nagrywasz ekran symulatora (Xcode › iPhone 16 Pro Max › nagrywanie ekranu), z dźwiękiem zabawy.

| Sekundy | Obraz | Napis na filmie |
|---|---|---|
| 0–3 | Start, palec dotyka „Co dziś robimy?” | Włącz zabawę |
| 3–8 | Odtwarzacz „Złodziej naszyjnika”, słychać głos Neli | Dziecko słucha… |
| 8–14 | Gra z odpowiedzią: „Powiedz tak albo nie”, pojawia się „Brawo!” | …i odpowiada na głos |
| 14–19 | Akta sprawy: zaznaczenie odpowiedzi, „Dobry wybór!” | Rozwiązuje zagadki |
| 19–24 | „Nowa naklejka!” po zabawie, potem album | Zbiera naklejki |
| 24–28 | Tryb podróży i Pobrane | Także w aucie, bez internetu |
| 28–30 | Start z logo | AudioKiddo |

## 8. Co jeszcze podnosi szanse (do zrobienia w kodzie, gdy zechcecie)

- **Widżet na ekranie głównym telefonu** z „Co dziś robimy?” (redakcje lubią nowości systemu). W aplikacji jest już synchronizacja widżetu (`home_widget_sync.dart`); trzeba sprawdzić wygląd na iPhonie.
- **Skróty Siri / App Shortcuts** („Hej Siri, zabawa AudioKiddo na dobranoc”): kod natywny iOS, do zrobienia na Macu.
- **Limit głośności w nocy**: częsty argument w recenzjach aplikacji audio dla dzieci.
- **Wersja angielska**: otwiera inne kraje i redakcje poza Polską. Dopiero po polskim sukcesie.
