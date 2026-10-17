# Strona audiokiddo.pl: wtyczka, wdrażanie, stan

Stan na 17.10.2026, wtyczka **audiokiddo-strona 3.8.0**. Gałęzie: `claude/fervent-meitner-jmt63o`
(wersja 3.7.0 + narzędzia wdrożeniowe) i `claude/eloquent-turing-t9k6n1` (3.8.0, commit `870daad`).

## Jak działa strona

WordPress + WooCommerce na hostingu LH.pl (serwer Apache, **nie** LiteSpeed). Motyw Woostify, Elementor,
Yoast SEO, Autoptimize, WPForms, MailerLite, PayU i inne wtyczki są zainstalowane, ale **wygląd stron
AudioKiddo robi własna wtyczka `audiokiddo-strona`** (folder `strona/audiokiddo-strona/` w repo). Wtyczka
podmienia szablon (`template_include`) i wyłącza style/skrypty motywu, Elementora i bloków na swoich widokach.

Widoki (`inc/routing.php`, funkcja `ak_view()`): `start` (strona główna, szablon „AudioKiddo: Start”),
`blog`, `post`, `guide` (poradniki/landingi), `info` (podstrony: jak-to-dziala, pakiety, pytania, o-nas,
logopedzi-i-pedagodzy…), `product` (strony pakietów), `404`, `search`.

Pliki:
- `templates/start.php`: strona główna (kolejność sekcji niżej). `templates/guide.php`, `info.php`, `product.php`…
- `inc/data.php`: **wszystkie teksty i dane** strony głównej: pakiety, ceny, opinie, specjaliści, FAQ,
  `ak_tour()` (kwestie Szop’ena prowadzącego), `ak_moments()` (dzień z Audiokiddo), `ak_hero_chat()`,
  `ak_home_contrast()` (przełącznik bez/z), `ak_home_skills()`, `ak_peeks()` (szop wychylający się),
  `ak_buy_steps()` i `ak_buy_where()` (droga po zakupie).
- `inc/ui.php`: pomocnicze funkcje HTML (`ak_icon()`, `ak_szop()`, `ak_peek()`, przyciski sklepów…).
- `inc/landings.php` (143 KB): poradniki (ok. 29 w kodzie), `inc/links.php`: linkowanie wewnętrzne,
  kafelki poradników na stronie głównej (`ak_home_guides()`, `ak_home_guide_art()`).
- `inc/woo.php` (teksty maili i strony „dziękujemy”), `inc/signup.php` (zapis do MailerLite przez serwer),
  `inc/seo.php` (dane strukturalne, llms.txt, robots), `inc/settings.php` (Ustawienia → AudioKiddo strona).
- `assets/css/strona.css`, `assets/js/strona.js`, `assets/fonts/` (Poppins + Baloo 2), `assets/img/`.
- Ustawienia w panelu: linki do sklepów aplikacji (puste = „wkrótce”), numery produktów WooCommerce,
  ceny abonamentu, formularz MailerLite, zdjęcia, przełączniki.

### Strona główna (kolejność sekcji w 3.8.0)

1. **Hero** (`#start`): „Ty pijesz ciepłą kawę. Dziecko ratuje świat.” + scena: odtwarzacz „Teraz gra:
   Złodziej naszyjnika”, rozmowa gry z dzieckiem (animowana pętla), liczniki „kawa wciąż ciepła / ekran
   0 min / dla Ciebie 15:00” (odlicza), cwaniacki Szop’en z dymkiem. Na telefonie scena jest tuż pod nagłówkiem.
2. **Jak to działa** (`#jak-to-dziala`): trzy kroki + „audiobook vs Audiokiddo”.
3. **Dzień z Audiokiddo** (`#kiedy`): zakładki z momentami dnia (auto, po przedszkolu, obiad, 18:37…).
4. **Ono ćwiczy. Ty odpoczywasz.** (`#co-zyskujesz`): przełącznik **Bez / Z Audiokiddo** (sam przeskakuje na „Z”
   po wejściu w sekcję, kliknięcie ma pierwszeństwo), pod spodem „Co ćwiczy” na okładkach prawdziwych zabaw.
5. **W akcji** (`#w-akcji`): 3 filmy dzieci. 6. **Opinie** (`#opinie`) i specjaliści.
7. **Pakiety** (`#pakiety`). 8. **Kupujesz raz. Masz wszędzie.** (`#po-zakupie`, nowa): linia z czterema
   krokami, po której przesuwa się paczka (wybierasz → mail z MP3/PDF → pakiet w aplikacji → odpalasz),
   pod spodem „Gdzie odpalisz?” (auto, dom, głośnik, offline, wydruk, u babci).
9. **Abonament** (`#cennik`). 10. **Pomysły na zabawy** (`#poradniki`): małe kafelki z okładką/szopem i tytułem.
11. **FAQ** (`#pytania`), zapis na darmowy pakiet, zakończenie.

**Szop’en wychylający się** (`ak_peek`): w czterech sekcjach (jak-to-dziala, co-zyskujesz, pakiety, pytania)
wysuwa się zza krawędzi (prawej/lewej) z nowym tekstem, gdy sekcja jest na środku ekranu, i chowa się, gdy
zniknie. W tym czasie szop-przewodnik z rogu ekranu znika (jeden szop naraz); też znika, gdy widać scenę
w hero. Zgodnie z prośbą: **nie we wszystkich sekcjach, żeby nie był nachalny**. Szop-przewodnik
(`parts/szopen.php`, `ak_tour()`) można wyciszyć („Ucisz mnie”).

Animacje respektują `prefers-reduced-motion`. Skrypt `strona.js` jest ładowany z `defer`.

## Wdrażanie (z sesji Claude)

Skrypty w `strona/tool/` logują się Playwrightem do `audiokiddo.pl/wp-admin` danymi ze **zmiennych
środowiska `WP_USER` i `WP_PASS`** (ustawionych w „Edit cloud environment”), nigdy z kodu ani czatu.

```bash
cd strona && rm -f /tmp/audiokiddo-strona.zip && zip -q -r -X /tmp/audiokiddo-strona.zip audiokiddo-strona
cd tool && NODE_PATH=$(npm root -g) OUT=/tmp node deploy-plugin.js /tmp/audiokiddo-strona.zip   # wgranie + zamiana wtyczki
NODE_PATH=$(npm root -g) node clear-cache.js     # po KAŻDYM wdrożeniu: czyści WP Fastest Cache i Autoptimize
NODE_PATH=$(npm root -g) OUT=/tmp node setup-cache.js   # tylko raz: instalacja i konfiguracja cache (u nas gotowe)
```

Przed wdrożeniem trzymaj kopię poprzedniego zip-a (łatwy powrót). **Po zakończeniu prac usuń konto
`claude-tymczasowy` w WordPressie i zmienne `WP_USER` / `WP_PASS` z ustawień środowiska** (jeśli jeszcze
tego nie zrobiono; do 17.10 nie potwierdzono).

## Szybkość (wymaganie: co najmniej 95 na telefonie i komputerze)

| Moment | Telefon | Komputer |
|---|---|---|
| Audyt 10.10.2026 (przed zmianami) | 59 | 84 |
| Po 3.7.0 + cache stron | 91 | 99 |
| **3.8.0 (17.10.2026), kilka pomiarów** | **96–98** | **96–98** |

Dostępność i SEO: po 100. Best practices: 96. Mierzone lokalnie **Lighthouse 12** (`npx lighthouse …
--preset=desktop` dla komputera), bo API PageSpeed Google zwracało 429 bez klucza. Proxy środowiska
blokowało skrypty śledzące (GTM, Facebook Pixel, Clarity, CookieYes), więc **wynik na pagespeed.web.dev
może być o kilka punktów niższy**; trzeba go sprawdzić. Jeśli wyjdzie poniżej 95, następny krok to
opóźnienie skryptów śledzących do pierwszej interakcji.

Co dało wynik:
1. **WP Fastest Cache**: czas odpowiedzi strony głównej z ok. 3 s do ok. 0,9 s. Ustawienia: cache stron,
   wstępne ładowanie (strona główna, wpisy, strony), gzip, cache przeglądarki (LBC), czyszczenie po
   publikacji/aktualizacji, wyłączone emoji. Koszyk i konto nie są cache’owane (tak ma być).
2. **Wyłączenie obcych zasobów na naszych widokach** (`ak_strip_foreign_assets()` w `routing.php`, uruchamiane
   także tuż przed wydrukiem tagów, bo motyw i Elementor dodawały swoje później): wspólny CSS z 386 KB
   do 142 KB. Wypadły: motyw Woostify, Elementor, Essential Addons, bloki WP (na start/guide/info),
   odtwarzacz muzyczny, PayU, dynamiczny CSS Woostify, price-history i MailerLite (na stronie głównej).
   Dopasowanie po fragmencie ścieżki (`/themes/<motyw>/`), nie po pełnym adresie.
3. Obrazy w hero **bez lazy-load** (`class="skip-lazy"`), bo lazy-load psuł LCP i dawał skoki układu.
4. **Obie** części czcionki Baloo 2 (latin i latin-ext, ą/ę/ś…) są preloadowane. Bez tego nagłówek „skakał”
   po doczytaniu polskich liter (CLS 0,18 → 0,07).
5. Okładki w małych kafelkach to osobne miniatury 240 px (`assets/img/covers/mini/`, ok. 17 KB) zamiast 520 px.

Przy dodawaniu nowych elementów: dawaj `width`/`height` obrazkom, nie ładuj nowych skryptów, mierz po zmianie.

## Pułapki, na które wpadliśmy

- **WP Fastest Cache nie zapisze ustawień**, dopóki w Elementorze (Ustawienia → Wydajność) włączone jest
  „Element Caching”. Wyłączone 10.10.2026. Formularz zapisuje się zwykłym `form.submit()`, kliknięcie
  przycisku „Submit” przez Playwright nie działało (okno preloadu).
- Po każdym wdrożeniu wyczyść oba cache (inaczej goście widzą starą stronę). Autoptimize łączy CSS/JS w
  pliki z hashem, więc stare style mogą zostać.
- Koszyk **otwierał się sam** przy każdym wejściu (motyw Woostify wołał `added_to_cart` bez argumentów);
  naprawione w 3.7.0 (`if(!fragments&&!button)return;`) i dodatkowo wyłączone skrypty motywu.
- Po dodaniu do koszyka WooCommerce przekierowuje na `/koszyk/` (ustawienie sklepu), szuflada koszyka
  istnieje tylko na stronach z naszym szablonem.
- Skrypty `ak-js`: elementy z `data-reveal` ukrywają się, dopóki skrypt nie ruszy (zabezpieczenie 3 s).
- Przy testach z chmurowego środowiska proxy blokuje część domen; błędy `ERR_TUNNEL_CONNECTION_FAILED`
  w konsoli to skutek proxy, nie błąd strony.
- W panelu wisi komunikat „WC Price History: Update Database” (nie ruszany, to zmiana w bazie sklepu).
- Duplicator zgłasza „Encrypted Settings Reset” (zmieniony klucz szyfrowania po migracji): do sprawdzenia przez Dawida.

## Co zostało zrobione w tej sesji (10–17.10.2026)

- 3.7.0 wgrana, WP Fastest Cache zainstalowany i skonfigurowany, sprawdzone: strona główna, koszyk,
  dodanie do koszyka (pakiet Wyobraźnia 49,99 zł).
- Nowe narzędzie `strona/tool/clear-cache.js`, uzupełniony `strona/tool/README.md`.
- 3.8.0: nowa pierwsza sekcja, nowy nagłówkowy krój pisma, przełącznik bez/z, miniatury okładek zamiast tekstu,
  nowa sekcja po zakupie, szop wychylający się, kafelki poradników, optymalizacje szybkości (wyżej).
