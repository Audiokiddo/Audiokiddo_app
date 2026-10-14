# AudioKiddo: pomysły, decyzje i zmiany (jeden plik)

To jest **jedno miejsce** na wszystkie pomysły i wprowadzone zmiany w aplikacji, na stronie i w całym ekosystemie. Nowy czat zaczyna od przeczytania tego pliku. Każda zmiana i każdy nowy pomysł trafia tutaj, z datą.

Szczegółowe analizy (tło do decyzji):
- `docs/STRATEGIA-5000-DO-MILIONA.md`;
- `docs/PLAN-USPRAWNIEN.md`;
- `docs/ANEKS-ANALITYCZNY.md`;
- raport z 13.10.2026: `Desktop/claude folder/AudioKiddo-analiza/ANALIZA-ROZWOJU-2026-10-13.md`;
- dwa badania rodziców z 12.10.2026 (PDF-y od Dawida).

Statusy: **zrobione**, **w toku**, **pomysł**, **odrzucone**.

---

## 1. Decyzje właścicieli (obowiązują)

| Data | Decyzja |
|---|---|
| 2026-10-08 | Jeden abonament: cała biblioteka, bez limitu dzieci, drugi rodzic w cenie. Bez planów „od liczby dzieci”. |
| 2026-10-10 | Nie pozycjonujemy się „ekran jest zły”. Maskotka wszędzie: Szop'en. |
| 2026-10-13 | **Tylko abonament.** Koniec sprzedaży pakietów, zestawów i pojedynczych zabaw na własność, w aplikacji i na stronie. Kilka osób, które kupiły pakiety (Empik, sklep), zachowuje dostęp. |
| 2026-10-13 | **Treści: co tydzień 2 nowe zabawy z nowego pakietu** (zamiast „nowy pakiet co miesiąc”). Pakiet zostaje jako seria / świat zabaw, nie jako produkt do kupienia. |
| 2026-10-13 | **Bez 7 dni za darmo całej biblioteki.** Za darmo jest jedna zabawa z każdego pakietu (dziś 3, do premiery 4). Rodzic poznaje po jednej, a reszta czeka za abonamentem. |
| 2026-10-13 | Premiera aplikacji w okresie **Black Friday** z największą promocją na abonament roczny. |
| 2026-10-13 | Cena miesięczna zostaje jak teraz (29,99 zł). Roczny: cena dla wcześniej dołączających niższa, z czasem rośnie (szczegóły do ustalenia, patrz 3.1). |
| 2026-10-13 | Nie konkurujemy ilością treści. Jesteśmy czymś nowym (dziecko odpowiada, nie tylko słucha), więc rodzice będą chcieli spróbować. |
| 2026-10-13 | Nie piszemy, że korzystamy z AI. Nie piszemy też, że wszystkie zabawy nagrywamy sami (nie wszystkie). Oficjalny opis: „Razem piszemy zabawy i je montujemy. Nasze głosy usłyszysz w zabawach. Od pomysłu do realizacji robimy wszystko sami, i sami jesteśmy rodzicami.” |
| 2026-10-13 | Wprowadzić uwagi prawne z analizy: bez przekreślonych „starych” cen, uczciwe teksty o koncie i mikrofonie. |

---

## 2. Dziennik zmian

### 2026-10-15 (gałąź `claude/szop-glos-gry`)

- **Dobranoc i podróż:** głos Szop'ena nie nakłada się już na zabawę. just_audio po zakończeniu klipu dalej uznaje, że gra, więc następne `play()` wracało od razu; teraz odtwarzacz zatrzymuje się przed każdą kwestią (`_playToEnd`).
- **Imiona:**
  - 339 nagranych imion (+164 za 1977 znaków), w tym Wacek i Zygmunt;
  - wyszukiwanie po pierwszych literach, bez polskich znaków i z drugą formą imienia (Zofia i Zosia, Wacek i Wacław; `groups.json`);
  - Szop'en rozpozna też imię wpisane bez polskich liter.
- **Pierwsze pytania:** tylko imię i wiek. Pytania „co chcecie rozwijać” i „kiedy słuchacie” usunięte (nowe dziecko dostaje wszystkie cele).
- **Profil dziecka:** imię i wiek ciemne na miętowej karcie (czytelne w ciemnym trybie).
- **Odtwarzacz:** zaraz pod przyciskami żółta karta „Następna z pakietu …” (jedno dotknięcie) i „Wszystkie zabawy z pakietu (N)”, która przewija w dół.
- **Mapa przygód Szop'ena** zamiast planu rozwoju (`/plan`, `lib/features/rewards/adventure_map.dart`):
  - każda ukończona zabawa to krok, a co 3 kroki skrzynia;
  - w skrzyniach na zmianę 2 sekrety Szop'ena (18 nagrań: zagadki, sekrety i zadania; `tool/reward_voice.py`, 1350 znaków) i karta do druku (6 arkuszy „Kart ratunkowych”; `strona/druk/karty.py --app`);
  - po zabawie w odtwarzaczu karta „Skrzynia otwarta!” albo „Jeszcze 2 zabawy do skrzyni”;
  - naklejki zostają jak były.
- **Odtwarzacz nie piętrzy się:** „Następna z pakietu” podmienia bieżący odtwarzacz zamiast otwierać nowy.
- **Jeden odtwarzacz naprawdę (16.10):** przyczyną była poprzednia poprawka. Po `push` router w `currentConfiguration.uri` dalej podaje stronę pod spodem (np. `/`), więc „jesteśmy w odtwarzaczu?” zawsze wychodziło „nie” i każda „Następna z pakietu” otwierała kolejny. Teraz `lib/core/open_player.dart` czyta prawdziwy stos stron: ten sam odtwarzacz na wierzchu nic nie robi, gra zastępuje odtwarzacz, kolejka otwarta z odtwarzacza wraca do niego. Używają go wszystkie wejścia (detale, kolejka, pasek na dole, mini odtwarzacz, plakietka, powitanie, „Co teraz?”). Test: `test/open_player_test.dart`.
- **Powitanie Szop'ena bez wyskakiwania (16.10):** okienko „Dokończ / Posłuchaj / Losuj” nie pojawia się już po 1,5 s pod palcem rodzica. Zaraz po starcie zasłania Start krótka „kurtyna” (ok. 1,5 s): konfetti, Szop'en wskakuje, litery „AudioKiddo” spadają jedna po drugiej, podpis „Szop'en odkurza mikrofon…”. W tym czasie liczą się wiadomości, a arkusz wyjeżdża w chwili, gdy kurtyna opada. Dotknięcie pomija animację; przy „ograniczeniu ruchu” jest od razu gotowy obraz; gdy katalog się wlecze (4 s), powitania w tym starcie nie ma wcale. Kod: `LaunchCurtain` w `launch_greeting.dart`, test `test/launch_curtain_test.dart`.
- **Statystyki bez danych dziecka:** zdarzenia zabaw nie niosą już wieku dziecka (Data safety: „nie zbieramy danych dziecka”).
- **Google Play, Zawartość aplikacji:**
  - zapisane: polityka prywatności, reklamy (brak), identyfikator reklamowy (nie), instytucje państwowe, funkcje finansowe i zdrowie (nie);
  - ocena IARC: PEGI 3, ESRB „Dla wszystkich”, Google Play „od 3 lat” (kategoria „inne aplikacje”, treści online, zakupy cyfrowe, produkt edukacyjny);
  - Bezpieczeństwo danych: wersja robocza wg `SKLEPY.md`:
    - zbierane są e-mail (funkcje, listy od Szop'ena, konto), identyfikator użytkownika (funkcje, analityka, konto), historia zakupów (funkcje) i interakcje (funkcje, analityka);
    - nic nie jest udostępniane, dane są szyfrowane, konto usuwa się przez `https://audiokiddo.pl/usuwanie-konta/`;
    - wysłać można dopiero po grupie docelowej;
  - czeka na Dawida: dane logowania recenzenta, potem grupa docelowa (5 i mniej, 6–8, 9–12).

### Kolejne kroki zaproponowane 15.10 (do decyzji)

| # | Co | Po co |
|---|---|---|
| K1 | **Premiera Google:** dokończ weryfikację numeru telefonu w Play Console, potem aplikacja, test zamknięty 12 osób × 14 dni (tydzień testowy z dzienniczkiem) | Bez tego nie ma Androida na Black Friday |
| K2 | **Premiera iOS:** konto Apple Developer (99 USD/rok), podpis, TestFlight dla tych samych rodzin | Wersja na 7 dni z darmowego konta wystarcza tylko do testów |
| K3 | **Seria na premierę:** 4. pakiet + plan „2 nowe zabawy co tydzień” rozpisany na 8 tygodni | Obietnica abonamentu musi mieć pokrycie od pierwszego dnia |
| K4 | **Skrzynie z nowościami:** co miesiąc nowe sekrety i karty (tanie: głos w ElevenLabs, karty z `karty.py`) | Dziecko ma na co czekać także po przesłuchaniu biblioteki |
| K5 | **Tryb dla rodzeństwa** (kolejka imion, pytania na dwóch poziomach) | Częsta scena z badań, nikt tego nie rozwiązuje |
| K6 | **Imię dziecka w zabawach** (nie tylko powitania): Szop'en mówi imię w środku przygody | Najmocniejszy moment „wow” do opinii i poleceń |
| K7 | **Raport z trasy do udostępnienia** + polecenia (30 zł) | Organiczny wzrost i dowód działania |
| K8 | **Strona 3.26.0** po połączeniu z 3.25.3 + kod QR do sklepów w dniu premiery | Sprzedaż tylko abonamentu również na www |

### 2026-10-14 (gałąź `claude/szop-glos-gry`)

- **Odtwarzacz:** usunięty przełącznik „Słuchamy razem / Dziecko samo” i pytania do rozmowy po zabawie (komplikowały, decyzja Dawida).
- **Materiały:** usunięte „Filmy i materiały” (linki do YouTube i Google Drive) i pliki PDF spoza Detektywa. Do pobrania zostają tylko akta sprawy z pakietu Detektyw; filtr „Do druku” pokazuje tylko je.
- **Wygląd:** domyślnie „Auto” (ciemny od 20:00 do 6:00). Wszystkie telefony wracają jednorazowo na Auto (nowy klucz `theme_mode_2`), a przełącznik zostaje w „Więcej”.
- **Ikona:** Szop'en sam zmienia ikonę co 3 dni, domyślnie włączone. Ręczny wybór ikony wyłącza automat. iPhone pokazuje przy zmianie krótki komunikat systemowy.
- **Listy od Szop'ena:** naprawione. Zapis zgody robił „upsert”, który ustawiał też `user_id`, a rodzic może zmieniać tylko `weekly`, `missed` i `updated_at`, więc baza zawsze odmawiała. Teraz najpierw aktualizacja, a gdy brak wiersza, wstawienie. Test w `supabase/tests/schema_test.sql`.
- **Kto teraz słucha?:**
  - szybsze przełączanie: plan i postępy liczą się tylko dla dziecka, którego dotyczą, a ekran zmienia się przed zapisem;
  - czytelne imiona w ciemnym trybie: wybrane ciemne na żółtym, reszta w kolorze tekstu.
- **Pytanie o imię:**
  - wybór z listy 175 nagranych imion z wyszukiwaniem;
  - „Nie ma imienia na liście” pozwala wpisać imię, a Szop'en go nie mówi;
  - w edycji profilu podpowiedź, czy Szop'en zna imię.
- **Usunięte pytanie** „Ile czasu dziennie na zabawę?” (zostaje dotychczasowa wartość albo 10 min).
- **„Czy dziecko chce jeszcze?”:** przyciski „Nie dziś” i „Zapytam” widoczne w ciemnym trybie.
- **Abonenci nie widzą ofert abonamentu:** ani okna po darmowej zabawie, ani „z abonamentem więcej” w losowaniu, ani powitania „w abonamencie czeka…”, ani banerów promocji (`hasSubscriptionProvider`).
- **„Co teraz?” → „Jedziemy autem”:** zamiast filtra otwiera tryb „W drogę” z wybranym czasem (CarPlay i Android Auto włączają się same po podłączeniu telefonu do auta; aplikacja nie może ich uruchomić).
- **Baza (14.10, wgrane):** migracje `20261022000001_bedtime_grace` i `20261023000001_play_minutes` są na serwerze.

### 2026-10-13 (gałąź `claude/szop-glos-gry`)

**Głos Szop'ena wszędzie:**
- 20 kwestii Szop'ena w interfejsie głosem „Szop Dawid” (ElevenLabs), głośność −19 LUFS;
- 5 gier interaktywnych mówiło syntezatorem; teraz prowadzi je Szop'en: Zgadnij dźwięk, Zamrożony taniec, Zamrożone rączki, Echo rytmu, Prawda czy nie. Pliki wgrane na serwer, sprawdzenie plików: 0 błędów;
- poprawka: just_audio grał starą kopię dźwięku z folderu tymczasowego, która przetrwała aktualizację. Kopie są czyszczone przy każdym starcie (`clearBundledAudioCopies`);
- tryb podróży: 10 nowych powiedzonek, losowanych przy każdej podróży (6 powitań, 6 przerw na okno, 3 pożegnania);
- **imiona:** Szop'en mówi „Hej, Zosia!” dla 175 popularnych imion i zdrobnień (`tool/name_voice.py`, `app/assets/audio/names/`). Mówi je na starcie i końcu trasy, przy wyciszeniu, na dobranoc, w trybie dziecka i przy dyplomie. Imienia spoza listy po prostu nie mówi.

**Oferta: tylko abonament:**
- aplikacja nie pokazuje już pakietów, zestawów ani pojedynczych zabaw do kupienia (`shopProductIds`, `productIdsFor` = tylko subskrypcje);
- sklep w aplikacji: bez sekcji „Wolisz kupić pakiet na zawsze?”, w cenniku tylko miesięczny i roczny;
- wszędzie „co tydzień 2 nowe zabawy” zamiast „nowy pakiet co miesiąc”.

**Ekran główny:**
- zaraz pod dużymi kafelkami wiek **3–4 | 5–6 | 7–9** i rodzaje zabaw jako jeden rząd, z nową kategorią **Darmowe** na początku;
- usunięte „Wasze pakiety” i „Moje pakiety”;
- „Jeszcze nie słuchane” → **„Jeszcze niesłuchane”**;
- nowy przycisk 💡 „Co potrafi aplikacja”.

**Ekran „Co potrafi AudioKiddo”** (`/funkcje`): wszystkie funkcje na jednej liście, każda o jedno dotknięcie, plus „Szop'en, oprowadź mnie”. Wejście ze Startu i z „Więcej”.

**Profil dziecka:**
- duży wybór „Kto teraz słucha?” na górze i przycisk „Dodaj dziecko”;
- nowo dodane dziecko od razu staje się aktywne;
- test przełączania: `test/profile_switch_test.dart`.

**Tryb podróży:** „Własny czas” (godziny i minuty, do 8 h) obok gotowych 15–90 min.

**Biblioteka:** wyraźna karta „Do druku” na górze, zaraz pod szybkimi filtrami.

**Pomiar prawdziwych minut:**
- każda zabawa wysyła:
  - sekundy, w których dźwięk naprawdę grał (`active_seconds`);
  - wiek dziecka;
  - numer „posiedzenia” (zabawy z mniej niż 10 min przerwy);
- CRM → Analiza → „Prawdziwe minuty zabawy”: mediana i co czwarte posiedzenie według wieku (`crm_play_minutes`, migracja `20261023000001_play_minutes.sql`). **Te liczby wolno podawać na stronie i w reklamach.**

**Pauza zamiast rezygnacji:**
- w procesie rezygnacji, po podaniu powodu, propozycja przerwy;
- Android: „Wstrzymaj na 1–3 miesiące” (Google Play);
- iOS (App Store nie ma pauzy): informacja, że profile i postępy poczekają.

**Uwagi prawne:**
- bez przekreślonych cen: rok porównany jako „12 × 29,99 zł = …”;
- usunięte porównanie z „pakietami osobno”;
- tekst „Konto: opcjonalnie” poprawiony na prawdziwy (logowanie jest wymagane: Apple, Google albo kod na e-mail);
- mikrofon: „nic nie jest nagrywane” jest zgodne z kodem (rozpoznawanie tylko w telefonie).

**O nas / zaufanie:**
- w aplikacji i na stronie zamiast „zabawy nagrywamy sami” jest opis właścicieli (patrz decyzje);
- FAQ „Kto tworzy audiozabawy?”.

---

## 3. Pomysły (backlog)

Z analizy z 13.10 i obu badań. Wpływ: ★★★ duży, ★ mały.

### 3.1. Cena i oferta

| Pomysł | Status | Uwagi |
|---|---|---|
| Rosnąca cena roczna dla późniejszych (+5 zł co miesiąc), start na Black Friday | **pomysł, do decyzji** | Opinia (14.10): tak, pod trzema warunkami: (1) gwarancja ceny dla już płacących (w sklepach zmiana tylko dla nowych klientów), (2) prawdziwa data i kwota kolejnej podwyżki, bez przekreślonych cen, (3) górny limit, np. 199,99 zł. Przykład: Black Friday 149,99 → +5 zł co miesiąc → limit 199,99. Strona z podsumowaniem: https://claude.ai/artifact/QexpmdjinESyeWMTjXWCwv |
| Prezent: abonament 3 i 12 miesięcy bez odnawiania, kod plus karta PDF lub pocztówka | pomysł ★★★ | Wpisywanie kodu w aplikacji już działa |
| Kody twórców (np. `SZOP-TATA`) z licznikiem w CRM | pomysł ★★ | |
| Oferta dla przedszkoli i placówek | **do zrobienia (decyzja Dawida 16.10)** ★★ | Osobne warunki i osobny cennik, żeby jedna placówka (np. Fikołki) nie kupiła jednego abonamentu rodzinnego dla całego przedszkola. Do ustalenia: licencja na placówkę (liczba grup/dzieci), osobny produkt poza sklepami, regulamin zakazujący użycia komercyjnego w abonamencie rodzinnym, faktura z NIP |
| Abonament przez stronę (cykliczny BLIK) | pomysł, etap 2 | |

### 3.2. Aplikacja

| Pomysł | Status |
|---|---|
| Darmowe zabawy bez zakładania konta (Apple 5.1.1(v), oba badania) | pomysł ★★★, **ryzyko przy recenzji Apple** |
| Tryb dla rodzeństwa (kolejka „teraz Zosia, teraz Staś”, różne poziomy) | pomysł ★★★ |
| „Skrzynka pytań Szop'ena”: pytania dzieci od rodziców, Szop'en odpowiada co tydzień | pomysł ★★★ |
| Raport z trasy do udostępnienia (minuty, zabawy, odpowiedzi) | pomysł ★★ |
| Start głosem: Siri / skróty Androida („Szop'en w drogę”) | pomysł ★★ |
| Filtr „Po cichu” (poczekalnia, restauracja, słuchawki) | pomysł ★★ |
| Zabawy „przy kuchni” (dziecko obok rodzica) | pomysł ★★ (treść) |
| Automatyczne pobieranie zabaw na weekend przez Wi-Fi | pomysł ★★ |
| Seria „Przygody Szop'ena” z oczekiwaniem na odcinek | pomysł ★★★ (treść) |
| Przełącznik „Dziecko samo” → „Dziecko się bawi, ja obok” | pomysł ★ |
| Prośba o ocenę także po udanej trasie i trzecim „Dobranoc” | pomysł ★★ |
| Logowanie: pod przyciskiem „Zarejestruj się” krótki podpis dla osób, które jeszcze nie mają konta; „Zaloguj” zostaje tylko dla tych, które konto już mają | **do zrobienia (16.10)** ★★ |

### 3.3. Strona i sklepy

| Pomysł | Status |
|---|---|
| Strona: koniec pakietów do kupienia, „co tydzień 2 nowe”, przycisk „Poznaj funkcje” | **w toku**: 3.26.0 gotowa, ale na serwerze jest 3.25.3 z sesji w chmurze, której kodu nie ma w repo; najpierw połączyć |
| W dniu premiery prawdziwe przyciski App Store i Google Play, kod QR | pomysł ★★★ |
| Strony sytuacji pod reklamy: /w-droge/, /po-przedszkolu/, /chore-dziecko/ | pomysł ★★ |
| 30 s dźwięku z prawdziwej trasy | pomysł ★★★ |
| Podtytuł w sklepach słowami rodziców: „Zabawy w aucie i w domu. Dziecko odpowiada, nie tylko słucha.” (nazwa „audiozabawa” nie jest znana, więc nie na pierwszym miejscu w sklepie i reklamach) | **do zrobienia (16.10)**: wpisać w App Store i Google Play, zaktualizować `KARTA-DO-WKLEJENIA.md` i `SKLEPY.md` |
| Mail premierowy do całej listy MailerLite | **do zrobienia (16.10)** ★★★ |
| Reklamy według STRATEGII (plik ze strategią reklam) | **do zrobienia (16.10)** ★★★ |
| Wydarzenia w App Store i Google Play dla cotygodniowych premier | pomysł ★★ |
| Odpowiadanie na każdą opinię w 24 h (agent w CRM) | pomysł ★★ |

### 3.4. Badania i dowody

| Pomysł | Status |
|---|---|
| Tydzień testowy z dzienniczkiem (8–10 rodzin, w tym testerzy Google Play) | pomysł ★★★ |
| Rozmowy z rodzicami według scenariusza z badań (min. 3 ojców) | pomysł ★★ |
| Ankieta: „jak opisałbyś to znajomemu?” (test, czy rodzice w ogóle mówią „audiozabawa”) | **do zrobienia (16.10)** ★★ |
| Rozmowa z „W PODSKOKACH” o wspólnej serii ruchowej | pomysł ★ |

---

## 4. Do zrobienia przez Dawida (poza kodem)

- App Store Connect i Google Play: **wycofać ze sprzedaży** pakiety i zestawy (nie usuwać, żeby działało przywracanie zakupów).
- Google Play Console: sprawdzić, że w subskrypcji jest włączona opcja **pauzy**.
- Nowa wersja aplikacji w sklepach (testy zamknięte) z tymi zmianami.
- Konto recenzenta Google/Apple:
  - zaloguj się w aplikacji kodem z maila na osobny adres, a potem ustaw hasło (Więcej → Konto);
  - uruchom `tool/grant_test_access.sh <adres>`;
  - w Play Console wpisz adres i hasło w sekcji Zawartość aplikacji → Dane logowania.
