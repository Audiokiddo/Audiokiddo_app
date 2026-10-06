# CRM AudioKiddo i agent COO

Stan: 5 października 2026. CRM jest częścią AudioKiddo Studio (zakładka **CRM**), działa w przeglądarce pod `https://audiokiddo.pl/studio/`. Wchodzi tylko konto z tabeli `admins` (logowanie kodem z maila, sesja zapamiętana w tej przeglądarce). Strona ma `noindex`, więc Google jej nie pokaże.

## Co jest w CRM

| Zakładka | Do czego |
|---|---|
| **Pulpit** | Trend 12 tygodni (aktywne rodziny, nowe konta, zabawy, oferta, zakupy, przychód; zmiana do zeszłego tygodnia). Zysk w tym miesiącu (szacunek: MRR netto po VAT i prowizjach minus koszty), MRR, płacące rodziny, abonamenty, użytkownicy, przychód z 30 dni. Ostatni raport COO, zadania na dziś i zaległe, kalendarz na 14 dni |
| **Decyzje** | Wszystko, co zaproponował agent: zatwierdzasz, odrzucasz albo poprawiasz. Bez Twojej decyzji nic nie trafia na tablice |
| **Zadania** | Tablica: Do zrobienia, W toku, Zrobione. Właściciel (Dawid, Nela, Claude), termin, priorytet |
| **Pomysły** | Pakiety, scenariusze, funkcje, posty i rolki ze statusem (nowy, wybrany, w produkcji, opublikowany). Przy pakiecie przycisk „Agent: napisz scenariusz zabawy” oraz „Do kalendarza” |
| **Kalendarz** | Premiery pakietów, rolki, posty, newslettery i promocje, miesiąc po miesiącu |
| **Reklamy** | Podgląd reklam i rolek jak na telefonie: haczyk, tekst, grupa docelowa, budżet testu |
| **Kampanie** | Meta Ads, Pixel, Google Ads i Google Analytics: wyniki, propozycje agenta reklam do zatwierdzenia, ręczne zmiany budżetów i wstrzymywanie kampanii. Szczegóły i podłączenie kont: `docs/REKLAMY.md` |
| **Mailing** | Wyniki z MailerLite (subskrybenci, otwarcia, kliknięcia, automatyzacje), newslettery i automatyzacje z podglądem. Przycisk „Szkic w MailerLite” tworzy kampanię, którą sprawdzasz i wysyłasz sam |
| **Użytkownicy** | **Obsługa klienta**: wyszukanie rodzica po e-mailu, jego zakupy, aktywność z 30 dni, „Daj dostęp ręcznie” (prezent, reklamacja, tester) i cofnięcie. Liczby kont, nowe konta, płacący, sprzedane pakiety, lista ostatnich kont |
| **Aktualizacje** | Historia wersji i propozycje zmian w aplikacji. „Jako zadanie” robi z propozycji zadanie dla Claude |
| **Ustawienia** | Rytm agenta (co przygotowuje sam rano) i koszty miesięczne liczone w zysku |

Statystyki zachowania w aplikacji (ukończenia, powtórki, powroty, konwersja) są w zakładce **Serwer → Statystyki**, agent też je widzi.

## Agent COO: jak z nim pracować

Agent działa na Claude API. Przy każdym wywołaniu dostaje stan firmy: liczby, statystyki aplikacji, katalog, otwarte zadania, pomysły, kalendarz i Twoje decyzje z ostatnich 45 dni (żeby uczył się, co akceptujesz). Nie dostaje adresów e-mail.

Przyciski:
- **Raport COO**: co zrobione, co utknęło, 3 priorytety na dziś, ryzyka, liczba do obserwowania i 3–6 propozycji zadań.
- **Pomysły na pakiety**: 4 pakiety z listą zabaw i miesiącem premiery.
- **Reklamy i rolki**: 5 koncepcji z haczykiem, ujęciami, tekstem i budżetem testu.
- **Newsletter**: gotowy numer (temat, tip, zabawa na dziś, miejsce na rolkę, nowość) i propozycje automatyzacji.
- **Propozycje zmian**: zmiany w aplikacji i ofercie wynikające z liczb.
- **Napisz scenariusz zabawy** (przy zatwierdzonym pakiecie w Pomysłach): pełny scenariusz do nagrania z rolami i pauzami.

W polu „Wskazówka dla agenta” możesz dopisać kierunek, np. „skup się na Bożym Narodzeniu” albo „krótsze zabawy dla 3-latków”.

**Rytm agenta (sam, około 6:30):** codziennie Raport COO, w poniedziałki pomysły na reklamy i rolki, co drugi czwartek gotowy newsletter. Wszystko czeka w „Decyzje”. Włączasz i wyłączasz w Ustawieniach.

**Newsletter od pomysłu do wysyłki:** agent pisze numer → zatwierdzasz w „Decyzje” → Mailing → „Zaplanuj wysyłkę” (grupa, dzień, godzina). Kampania powstaje w MailerLite i wyjdzie sama; do tego czasu możesz ją jeszcze zmienić w MailerLite.

**Codzienny rytm (10 minut):** rano Raport COO, potem Decyzje (zatwierdź lub odrzuć), przesuń zadania na tablicy. W poniedziałki pomysły na reklamy, co drugi czwartek newsletter.

## Ścieżka nowego pakietu (z decyzją na każdym kroku)

1. **Pomysły na pakiety**: wybierasz pakiet w Decyzjach.
2. **Napisz scenariusz zabawy**: dla każdej zabawy, zatwierdzasz albo poprawiasz.
3. Nela nagrywa. Zadanie trafia na tablicę.
4. Claude dodaje zabawy w Studio (Treści), Ty publikujesz katalog w Serwer → Katalog w aplikacji.
5. **Do kalendarza**: premiera. Agent proponuje rolki i newsletter o nowym pakiecie, Ty wybierasz.

Generowanie dźwięku i okładek zostaje ręczne: nagrania Neli i okładki to wyróżnik marki.

## Wdrożenie (robisz Ty, w terminalu w folderze projektu)

1. Baza CRM:
   ```
   supabase db push
   ```
2. Funkcje (agent, MailerLite, kampanie i `admin`):
   ```
   supabase functions deploy coo mailerlite admin ads
   ```
3. Klucze wpisujesz sam, w terminalu albo w Supabase → Edge Functions → Secrets. Nie wklejaj ich do rozmowy:
   ```
   supabase secrets set ANTHROPIC_API_KEY=twój_klucz
   supabase secrets set MAILERLITE_API_KEY=twój_klucz MAILERLITE_FROM=kontakt@audiokiddo.pl
   ```
   Klucz Claude: console.anthropic.com → API Keys (ustaw tam limit miesięczny, np. 100 zł). Klucz MailerLite: MailerLite → Integrations → API.
4. Studio na stronę: `bash tool/studio_build.sh`, potem w FileZilli wgraj zawartość `studio/build/web` do `public_html/studio`.

Koszt agenta: raport to kilka groszy do kilkunastu groszy, scenariusz do około 1 zł. Przy codziennym użyciu to zwykle 20–60 zł miesięcznie.

## MailerLite: plan maili do rodziców

Make i HubSpot nie są teraz potrzebne. MailerLite (darmowy do 1000 adresów) ma formularze, automatyzacje i newsletter. Make warto dodać, gdy będzie więcej niż 300 zakupów w sklepie miesięcznie (np. zakup w WooCommerce → tag w MailerLite).

**Zbieranie adresów (zgodnie z RODO, tylko dorośli):**
- formularz na audiokiddo.pl z prezentem: karta zabaw bez ekranu do druku („10 zabaw na nudę w aucie”);
- checkbox zgody marketingowej przy zakupie w WooCommerce (MailerLite ma wtyczkę);
- w aplikacji nie zbieramy maili do newslettera (kategoria Kids).

**Automatyzacje:**
1. **Powitanie (3 maile):** dzień 0 prezent i jak zacząć; dzień 2 tryb dziecka i zabawy offline; dzień 5 abonament z nowym pakietem co miesiąc i darmowy tydzień.
2. **Po zakupie pakietu:** dzień 1 jak grać (akta Detektywa); dzień 14 „zostały Wam 2 pakiety: w abonamencie taniej”.
3. **Przed premierą pakietu:** zapowiedź 3 dni przed i „już jest” w dniu premiery.
4. **Powrót:** brak otwarć przez 60 dni, wtedy krótki mail „Szop’en tęskni” z jedną zabawą.

**Newsletter co 2 tygodnie** (temat do 45 znaków, krótko, jeden link główny):
- powitanie Szop’ena (2 zdania z humorem);
- jeden tip wychowawczy (nuda, emocje, mowa, sen);
- zabawa bez ekranu na dziś (do zrobienia od razu);
- rolka dla rodziców: link do Instagrama lub TikToka z krótkim opisem;
- nowość lub promocja w aplikacji;
- P.S. z pytaniem do rodziców (odpowiedzi to pomysły na kolejne zabawy).
