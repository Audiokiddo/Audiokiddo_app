# Zakładka Care: przebudowa i połączenie ze Startem

Stan: 28 października 2026. Na podstawie zrzutu ekranu z iPhone’a Dawida (tryb ciemny, 22:30) oraz raportów i scenariuszy w `docs/care/`. Kod Care jest w lokalnym repo Dawida (`audiokiddo-glos`, `app/lib/features/care/`, `packages/ak_core/lib/src/care.dart`), nie w tym repozytorium. Ten dokument jest specyfikacją dla sesji, która ma ten kod.

## 1. Co widać na zrzucie i co jest do poprawy

| # | Problem | Dlaczego | Poprawka |
|---|---|---|---|
| 1 | Karta „Gwiazdki: Adaś / Ten tydzień: 4 dni, wychodzi 93%” jest prawie niewidoczna (jasny tekst na jasnożółtym tle) | Za mały kontrast; w trybie ciemnym karta zachowuje jasne tło | Kolory z tokenów motywu, kontrast tekstu co najmniej 4,5:1 w obu trybach, test kontrastu |
| 2 | „wychodzi 93%” | To ocena wyniku. Care nie ocenia dziecka ani wymowy | Zamiast procentów: pasek Pon–Nie z gwiazdkami za udział, gwiazdki nigdy nie znikają |
| 3 | Dwa odtwarzacze naraz: karta „Wróćmy do zabawy” i pasek „Pauza” | Duplikat, pasek zachodzi na dolną nawigację | Jedno miejsce: gdy coś jest załadowane, pokazuje się tylko pasek nad nawigacją; karta „Wróćmy do zabawy” tylko gdy nic nie gra i jest co dokończyć |
| 4 | Kafelki z samymi literami „SZ”, „Ż”, „S” i podtytuł „zabawy na wyraźne mówienie” | Wygląda jak ćwiczenie i obietnica poprawy wymowy; „od 3 lat” przy sz sugeruje normę wiekową | Okładki światów (Szafa, Koszyk, Kot), podtytuł „6–8 minut słuchania z Szop’em”, wiek jako poziom zabawy („5–6 lat”) |
| 5 | Szop’en w pozie „klaszcze” wygląda na zirytowanego | Zły nastrój dla rodzica | Pozy `zadowolony`, `prosi`, `nasluchuje` bez `klaszcze` i `zdziwiony` |
| 6 | Pomarańczowy gradient bez związku z marką Care | Dwie palety w jednej aplikacji | Paleta marki (tokens.dart): `tealDeep`/`teal`, `lavender`, `sun` jako akcent |
| 7 | Brak pomocy dla rodzica | Rodzic nie widzi, po co to jest | Sekcja „Dla rodzica” (pkt 3) |

## 2. Układ zakładki Care (od góry)

1. **Nagłówek „Uszy w górę”.** Gradient `tealDeep` → `teal`, tekst kremowy, Szop’en `zadowolony`. Zdanie: „6 minut słuchania z Szop’em. Razem, bez ekranu.” Przycisk „Zagrajmy na dziś” (kolor `sun`, tekst `ink`) otwiera Mieszankę na dziś.
2. **Pasek tygodnia.** Pon–Nie, gwiazdka w dniu, w którym była zabawa. Linia „Najbliższa zabawa: środa 18:00” albo przycisk „Ustaw porę”. Bez procentów i bez porównań.
3. **Zestawy (karuzela okładek).**
   - Szop’en i Szumiąca Szafa (5–6 lat): odcinek próbny „Tacka czy taczka?” do odsłuchu.
   - Koszyk Rymusia (4–6 lat): „wkrótce”.
   - Kot Bąbel szuka koloru (4–6 lat): „wkrótce”.
   - Dotychczasowe gry głosem (sz, ż, s) przeniesione niżej do sekcji „Gry głosem” z dopiskiem, że mikrofon jest tylko po zgodzie rodzica i nic nie jest wysyłane.
4. **Dla rodzica** (karty z ikonami Material, bez ✨):
   - „Jak słuchać razem”: słuchajcie razem, zachęcajcie, nie poprawiajcie; jeśli dziecko powie słowo inaczej, powiedz je poprawnie sam i nie proś o powtórzenie.
   - „Plan tygodnia”: dni i godzina, przypomnienie.
   - „Karta tygodnia (PDF)”: z lokalnych zapisów, do pokazania logopedowi; dane zostają w telefonie.
   - „Kiedy warto iść do logopedy”: lista sygnałów (treść po akceptacji konsultanta).
   - „Obok terapii, nie zamiast”: jedno zdanie, widoczne.
5. **Pierwsze otwarcie:** trzy kroki (Słuchajcie razem, Odpowiadajcie jak chcecie, Gwiazdka za udział) i przycisk „Zaczynamy”. Można pominąć.

Po każdej zabawie ekran „Jak poszło?” z trzema przyciskami (łatwo / w sam raz / trudno), 2–3 pytaniami do rozmowy i wskazówką dla rodzica. Rodzic ocenia wygodę zadania, a nie dziecko.

## 3. Połączenie z ekranem Start (zachęta dla rodzica)

| Miejsce | Zmiana |
|---|---|
| Start, pod „Zabawą dnia” | Wąska karta „Po zabawie: 6 minut Uszy w górę” z Szop’em i przyciskiem. Tylko dla rodzin z dzieckiem 4–6 lat (jest `EventContext.ageGroup`), do zamknięcia, wraca po tygodniu |
| „Co teraz?” (`quick_pick.dart`) | Nowa opcja „Uszy w górę (6 min)” oraz „Mieszanka na dziś”: jedna zwykła zabawa i jeden odcinek Care |
| Ekran „Brawo! Co dalej?” po zwykłej zabawie | Propozycja „A teraz uszy w górę”, gdy w tym tygodniu były co najmniej dwie zabawy |
| Biblioteka | Filtr „Uszy w górę” |
| Przypomnienia | Własna godzina z planu tygodnia |

Zasady: nie zmuszać i nie wykrzykiwać, Care jest zaproszeniem. Zero ikon ✨ i emoji-ikon. Nie obiecywać skuteczności.

## 4. Treści dla dziecka

- Pakiet Szumiąca Szafa wg `komplet-promptow-0-5.md` (do przepisania na strukturę z `KONCEPCJA-CARE.md` po rozmowie z konsultantem).
- Odcinek próbny: `docs/care/odcinki/tacka-czy-taczka.json` (czytelna wersja: `.md`). Nagranie generuje `python3 tool/care_episode.py tacka-czy-taczka` na Macu (klucz z pęku kluczy; głosy „szop” i „nela”).
- Okładki: prompt do ilustracji w komplecie, prompt 3. Paleta: turkus, lawenda, żółty; bez twarzy dzieci i bez tekstu na obrazku.

## 5. Kryteria odbioru

1. Zrzut ekranu w jasnym i ciemnym trybie: cały tekst czytelny (kontrast ≥ 4,5:1).
2. Na Care i na Starcie nie ma dwóch odtwarzaczy; pasek nie zachodzi na nawigację.
3. Nigdzie nie ma procentów wyniku ani słów „leczy”, „diagnozuje”, „terapia”.
4. `flutter analyze` i `flutter test` przechodzą, w tym test kontrastu i test, że Care działa bez mikrofonu.
5. Odcinek próbny odtwarza się offline po pobraniu.
