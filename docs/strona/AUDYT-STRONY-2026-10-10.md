# Audyt audiokiddo.pl – 10.10.2026 (szybkość i SEO)

Zrobiony z zewnątrz (pobranie stron, map strony i zasobów, test w Chromium jak telefon).
Bez dostępu do panelu WordPressa ani kodu wtyczki `audiokiddo-strona`.

## Szybkość (PageSpeed: telefon 59, komputer 84)

| # | Problem | Dowód | Poprawka |
|---|---|---|---|
| 1 | **Koszyk otwiera się sam przy każdym wejściu** | Motyw Woostify (`quantity-button.min.js`, `woostifyValidLoopItemAddToCartButton`) wywołuje `jQuery(document.body).trigger("added_to_cart")` bez argumentów. Wtyczka `audiokiddo-strona` na to zdarzenie woła `openCart(true)`. Odtworzone w Chromium. | W JS wtyczki, na początku handlera `added_to_cart`: `if(!fragments&&!button)return;` |
| 2 | **Serwer odpowiada 2,5–4,7 s na każdej stronie** | `cache-control: no-store`, ciasteczko `PHPSESSID` na każdej stronie (jakaś wtyczka woła `session_start()`), brak cache stron. | Wtyczka cache stron (WP Fastest Cache / WP Super Cache; serwer to Apache, nie LiteSpeed). Znaleźć wtyczkę, która zakłada sesję PHP dla każdego gościa. |
| 3 | Pliki wtyczki bez cache przeglądarki | `hero.webp`, `logo.png`, `Poppins-Bold.ttf`: `cache-control: private`, bez `max-age` (to te 774 KiB). | Reguły `Expires`/`Cache-Control` w `.htaccess` (poniżej). |
| 4 | Czcionka ładowana dwa razy, w ciężkim formacie | Google Fonts Poppins **i** lokalny `Poppins-Bold.ttf` (156 KB, TTF, preload). | Zostawić tylko lokalną, w WOFF2 (ok. 40 KB), usunąć Google Fonts z motywu. |
| 5 | Ogromny wspólny CSS blokujący wyświetlanie | Autoptimize łączy CSS w jeden plik 385 KB (67 KB po kompresji): Elementor, Woostify, WooCommerce, wtyczka. | Krytyczny CSS w treści strony, reszta odroczona; nie ładować CSS/JS WooCommerce i Contact Form 7 poza sklepem i kontaktem. |
| 6 | jQuery, `wp-hooks`, `wp-i18n` bez `defer` | Lista skryptów na stronie głównej. | Odroczyć (po wyłączeniu CF7 poza `/kontakt/` `wp-i18n` zniknie sam). |
| 7 | Audyt „agentowy”: `role="dialog"` na `<aside>` | `#ak-cart-drawer` | Zmienić znacznik na `<div>` albo usunąć `role`. |

Reguły do `.htaccess` (Yoast SEO → Narzędzia → Edytor plików, na końcu pliku):

```apache
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/webp "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/svg+xml "access plus 1 year"
  ExpiresByType font/ttf "access plus 1 year"
  ExpiresByType font/woff2 "access plus 1 year"
  ExpiresByType text/css "access plus 1 year"
  ExpiresByType application/javascript "access plus 1 year"
</IfModule>
<IfModule mod_headers.c>
  <FilesMatch "\.(webp|png|jpe?g|svg|ttf|woff2|css|js)$">
    Header set Cache-Control "public, max-age=31536000"
  </FilesMatch>
</IfModule>
```

## SEO

Stan lepszy, niż widać w Google: działa Yoast, są mapy strony, dane strukturalne (Article, FAQPage,
Product, BreadcrumbList, HowTo) i ok. 30 poradników (`ak-poradniki-sitemap.xml`): zagadki, podróż,
logopedia, zabawy wg wieku 3–8 lat, nuda, samodzielna zabawa. Stare adresy (`/sklep/`,
`/czym-sa-audiozabawy-2/`, `/sklep-produkty/`) przekierowują poprawnie.

Problemy:
1. **Google zna tylko ok. 6 adresów.** Mapa `ak-poradniki-sitemap.xml` jest tylko w robots.txt, nie
   w indeksie map Yoast. Zgłosić w Search Console obie mapy i poprosić o zaindeksowanie hubów.
2. **Słabe linkowanie wewnętrzne.** Każdy poradnik ma w treści tylko 6 linków (te same: Start,
   Pomysły, 4 sąsiednie). Do poradników prowadzą 2–5 linki. Hub `/pomysly-na-zabawy/` (28 linków
   wychodzących) ma tylko 1 link przychodzący z treści. Strona główna nie linkuje do poradników.
3. **Cienka treść.** Poradniki mają 340–830 słów. `/zagadki-dla-dzieci/` ma 645 słów; na hasło
   „zagadki dla dzieci” wygrywają strony z setkami zagadek.
4. `/zapis-pakiet-darmowy/`: tytuł „Pakiet Darmowy - Landing Page”, brak H1, opisu i canonical,
   zero linków przychodzących.
5. Menu „Pakiety” prowadzi do `#pakiety`, czyli do jednozdaniowego linku pod cennikiem, a nie do
   sekcji z pakietami (gotowa sekcja: `sekcja-pakiety.html`).
6. Niespójny wiek Detektywa: produkt „od 7 lat”, aplikacja i katalog „od 6 lat”.
7. robots.txt ma dwie grupy `User-agent: *` (wtyczka + Yoast). Google je łączy, ale lepiej jedna.
8. `/kontakt/`, regulaminy i polityki: bez opisu i H1 (mała waga, do uzupełnienia przy okazji).

## Plan

1. Poprawki 1–3 z tabeli szybkości (koszyk, cache stron, cache plików).
2. Search Console: obie mapy strony, indeksowanie hubów.
3. Linkowanie: sekcja „Poradniki” na stronie głównej; w każdym poradniku blok 6–8 linków
   tematycznych + link do pasującego pakietu; z produktów 2–3 linki do poradników; huby linkują
   wszystkie swoje strony.
4. Rozbudowa filarów: zagadki (200+ z odpowiedziami, podstrony tematyczne), podróż (samochód,
   pociąg, samolot, święta), Detektyw do druku (szyfry, podchody, gra detektywistyczna PDF).
5. Notka „sprawdzone przez logopedkę” (Maria Lewandowska-Nawrocka, zgoda jest) na pakietach,
   w poradnikach o mowie i na `/logopedzi-i-pedagodzy/`, z danymi Person w schemacie.
