# Audiokiddo: SEO i GEO

Stan: 10 października 2026, wtyczka strony 3.0.0. Cel: żeby Audiokiddo było podpowiadane rodzicom przez Google i przez asystentów AI (ChatGPT, Gemini, Perplexity, Copilot, Claude) jako **zabawy dla dzieci bez ekranu, które rozwijają dziecko, dają rodzicowi czas i są polecane przez logopedów i pedagogów**. Usługą wiodącą jest **abonament w aplikacji** (29,99 zł / mies., 269,99 zł / rok).

## 1. Słowa kluczowe (podpowiedzi Google, 10.10.2026)

Źródło: podpowiedzi wyszukiwarki Google dla Polski (`suggestqueries`, hl=pl). Podpowiedzi pokazują, czego ludzie naprawdę szukają, ale nie liczby wyszukań. Liczby sprawdźcie w Google Search Console po 4–6 tygodniach albo w Planerze słów kluczowych Google Ads.

| Klaster | Przykładowe frazy z podpowiedzi | Strona docelowa |
|---|---|---|
| Zabawy w domu | zabawy dla dzieci w domu, co robić z dzieckiem w domu, zabawy na deszczowy dzień, kreatywne zabawy w domu dla dzieci, zabawy dla dzieci w domu bez zabawek | `/zabawy-dla-dzieci-w-domu/` |
| Wiek | zabawy dla 3 / 4 / 5 / 6 latka (w domu, w przedszkolu, ruchowe, kreatywne, edukacyjne), zabawy dla przedszkolaków | `/zabawy-dla-przedszkolakow/`, `/zabawy-dla-dzieci-7-9-lat/` |
| Podróż | jak zająć dziecko w samochodzie / w samolocie / w podróży / w pociągu, zabawy w samochodzie dla dzieci, zabawy słowne w samochodzie | `/jak-zajac-dziecko-w-samochodzie/` |
| Mowa | zabawy logopedyczne (dla 3, 4, 5 latka, dla przedszkolaków), zabawy rozwijające mowę dziecka, ćwiczenia logopedyczne dla dzieci, zabawy słowne dla dzieci | `/zabawy-logopedyczne/` |
| Zagadki | zagadki dla dzieci, zagadki dla dzieci 4 5 lat / 6 7 lat / 7 8 lat z odpowiedziami, o zwierzętach | `/zagadki-dla-dzieci/` |
| Koncentracja | zabawy na koncentrację uwagi (dla 3–8 latka, przedszkole) | `/zabawy-na-koncentracje/` |
| Wieczór | zabawy wyciszające dla dzieci, zabawy przed snem, zabawy na wyciszenie dziecka przed snem | `/zabawy-wyciszajace-przed-snem/` |
| Słuchanie | audiobooki dla dzieci (na dobranoc, za darmo, spotify), słuchowiska dla dzieci, bajki do słuchania dla dzieci / dla przedszkolaków, interaktywne bajki | `/audiobooki-i-sluchowiska-dla-dzieci/` |
| Aplikacje | aplikacje edukacyjne dla dzieci (6, 7, 8 lat, po polsku, za darmo), aplikacja dla dzieci na telefon | `/aplikacje-edukacyjne-dla-dzieci/` |
| Ruch | zabawy ruchowe dla dzieci w domu, zabawy ruchowe dla przedszkolaków | `/zabawy-ruchowe-dla-dzieci-w-domu/` |
| Bez ekranu | zabawy bez ekranu, gry dla dzieci bez telefonu, czas przed ekranem dziecko | `/zabawy-bez-ekranu/` (strona filarowa) |
| Marka | audiokiddo, audio kiddo, audiozabawy | strona główna |

Ważne obserwacje:
- **Wiek w zapytaniu** pojawia się bardzo często („dla 4 latka”, „7 8 lat”). Każdy wpis i poradnik powinien mieć wiek w nagłówku.
- **„w domu” i „do druku”** to częste dopiski. Do zagadek i akt Detektywa warto zrobić wersje PDF do druku (pobranie za e-mail).
- **YouTube i Spotify** pojawiają się przy audiobookach, słuchowiskach i zabawach ruchowych. Rodzice szukają tam, więc trzeba tam być (punkt 4).
- **„z autyzmem” i „z ADHD”** to częste dopiski. To temat wrażliwy: tylko z konsultacją specjalisty i bez obietnic terapeutycznych.

## 2. Co jest zrobione na stronie (wtyczka 3.0.0)

**Strona główna** (nowe teksty Neli):
- **Kolejność sekcji:** hero → „To nie jest audiobook” → „Kiedy odpalić” → „Jak to działa” → dowody (filmy, próbki) → wiek i biblioteka → darmowe zabawy → opinie i specjaliści → cennik → pakiety → tablet → o nas → prywatność → FAQ → poradniki → zapis → blog → finał.
- **Abonament prowadzi:** przycisk w nagłówku („Abonament”) i główne przyciski prowadzą do aplikacji albo do cennika. Pakiety są alternatywą („Nie lubisz subskrypcji? Spoko.”).
- **Przed premierą aplikacji** przyciski uczciwie prowadzą do zapisu („Daj znać, gdy aplikacja ruszy”). Po wpisaniu linków do sklepów w ustawieniach wszystko samo przełącza się na „Pobierz” (na telefonie od razu właściwy sklep).

**12 poradników** pod klastry z tabeli: osobne adresy, „najważniejsze w skrócie” na górze (pod cytowanie przez AI), konkretne zabawy, cytat specjalisty tam, gdzie pasuje, FAQ i blok abonamentu. Hub: `/pomysly-na-zabawy/`. Treść jest w `strona/audiokiddo-strona/inc/landings.php`.

**Dane strukturalne (schema.org):**
- **Organization:** nazwa i nazwy alternatywne, założyciele, kontakt, obszar Polska, tematy (`knowsAbout`).
- **MobileApplication:** oferty darmowa / miesięczna / roczna z okresem rozliczenia, funkcje, zrzuty ekranu.
- **Pozostałe:** WebPage z `speakable`, HowTo („Jak to działa”), VideoObject (filmy dzieci), Product (pakiety i zestawy z cenami z WooCommerce), FAQPage, a na poradnikach Article, ItemList, FAQPage i BreadcrumbList.

**Pliki dla AI:**
- **`/llms.txt`:** fakty, cennik, sytuacje, wiek, rodzaje zabaw, poradniki, FAQ i blog.
- **`/llms-full.txt`:** pełna treść wszystkich poradników w Markdownie.

**Technicznie:**
- **Meta i kanoniczność:** własne tytuły, opisy, canonical, hreflang pl-PL, `robots` z `max-image-preview:large`, OG i Twitter card, `geo.region` PL.
- **Mapa strony:** poradniki w osobnej mapie `/ak-poradniki-sitemap.xml`, dopiętej do indeksu Yoast i do robots.txt.
- **Strony 404 i wyniki wyszukiwania:** w głosie marki i z `noindex`.

**Osobowość w sklepie:**
- strona po płatności („No i zajebiście…”);
- anulowanie („Bez dramatu…”);
- pusty koszyk;
- ładowanie przycisku koszyka („Szop coś grzebie…”);
- 404 („Tego nie ma. Nikt nic nie widział.”);
- brak wyników („Nic. Sprawdziliśmy nawet pod kanapą.”).

## 3. Co jeszcze zrobić na stronie (kolejność według zwrotu)

1. **Google Search Console i Bing Webmaster Tools.** Zgłoś mapę `sitemap_index.xml`. Bing jest ważny podwójnie, bo z jego indeksu korzysta wyszukiwanie w ChatGPT i Copilot. Włącz IndexNow (wtyczka IndexNow albo funkcja w Yoast), żeby nowe wpisy trafiały do Bing od razu.
2. **Blog co tydzień pod frazy z wiekiem**, np. „Zabawy dla 4 latka w domu: 20 pomysłów”, „Zagadki dla dzieci 7–8 lat o zwierzętach z odpowiedziami”, „Jak zająć dziecko w samolocie”. Fabryka artykułów w Studio ma dostać tę listę jako kolejkę tematów. Każdy wpis linkuje do właściwego poradnika i do cennika.
3. **PDF do druku za e-mail:** „30 zagadek dla dzieci do wydruku”, „Karta zabaw na podróż”. To odpowiedź na „do druku”, a przy okazji zbiera adresy do newslettera premierowego.
4. **Strona dla przedszkoli i logopedów** (`/dla-przedszkoli/`): oferta B2B i sposób pracy z grupą. Logopedzi i nauczyciele to źródła linków i poleceń.
5. **Strona specjalistów** z pełnymi cytatami, zdjęciami i opisem, kim są (Julia Kasielska, Maria Lewandowska-Nawrocka) i kolejnymi rekomendacjami. Każda nowa rekomendacja to argument dla Google (E-E-A-T) i dla AI.
6. **Opinie rodziców w sklepach z aplikacjami** po premierze. AI chętnie cytuje oceny z App Store i Google Play.
7. **Szybkość:** czcionki są jako TTF. Konwersja do WOFF2 to mniej o około 60%. Autoptimize nie powinien łączyć naszego skryptu z innymi (sprawdzić po wdrożeniu).

## 4. Poza stroną: największa dźwignia dla GEO

Asystenci AI polecają to, o czym piszą inne zaufane źródła. Strona daje fakty, ale o tym, czy Audiokiddo trafi do odpowiedzi „jakie aplikacje dla dzieci bez ekranu”, decydują wzmianki w innych miejscach.

1. **Rankingi i portale parentingowe:** artykuły typu „najlepsze aplikacje dla dzieci”, „zabawy bez ekranu”, „aplikacje edukacyjne po polsku” (Mamotoja, Dzieci są ważne, eDziecko, Parenting.pl, Mama:Du, blogi parentingowe). Proponujcie gotowy opis, zrzuty i darmowy dostęp dla redakcji.
2. **Logopedzi i pedagodzy:** współpraca z 10–20 specjalistami. Dostają darmowy dostęp, a w zamian piszą o Audiokiddo na swoich stronach, w grupach i na Instagramie. To najmocniejszy sygnał „polecane przez logopedów”.
3. **Podcast z darmowymi audiozabawami na Spotify i Apple Podcasts** („Audiokiddo: zabawy do słuchania”). Rodzice wpisują „słuchowiska dla dzieci spotify”, więc to darmowy kanał pozyskania z linkiem do aplikacji w każdym odcinku.
4. **YouTube i Shorts:** krótkie filmy „dziecko + audiozabawa” (ręce, plecy, bez twarzy, zgodnie z zasadą prywatności) i „zabawy ruchowe dla dzieci” z głosem Audiokiddo. YouTube wyskakuje w podpowiedziach przy zabawach ruchowych i bajkach.
5. **Wikidata:** wpis „Audiokiddo” (aplikacja, Polska, twórcy, strona, sklepy). Pomaga AI jednoznacznie rozpoznać markę. Wikipedia dopiero przy niezależnych artykułach prasowych.
6. **PR z danymi:** krótka ankieta wśród rodziców („Ile minut dziennie dziecko spędza przed ekranem, gdy rodzic gotuje?”) i komunikat do mediów. Dane są cytowane i dają linki.
7. **Grupy rodziców** (Facebook, fora): konkretna pomoc i pomysły, bez spamu. Link do poradnika, nie do sklepu.
8. **Profil Google (Google Business Profile)** jako marka online z Polski: nazwa, opis, link, zdjęcia. Wzmacnia rozpoznawalność marki w Google i w Gemini.

## 5. Jak mierzyć

- **Google Search Console:** wyświetlenia i kliknięcia dla poradników, frazy z wiekiem, CTR tytułów.
- **Bing Webmaster Tools:** wyświetlenia, w tym ruch z Copilota.
- **Wizyty z AI:** ruch z chatgpt.com, perplexity.ai i gemini.google.com (Google Analytics → Pozyskiwanie → Źródło).
- **Test raz w miesiącu:** zapytajcie ChatGPT, Gemini i Perplexity „jakie są zabawy dla dzieci bez ekranu / aplikacje dla dzieci bez ekranu po polsku / jak zająć dziecko w samochodzie” i zapiszcie, czy pada Audiokiddo.
- **Cel na 6 miesięcy:** 12 poradników w top 10 na swoje frazy, 40+ wpisów na blogu, 10 rekomendacji specjalistów, 5 wzmianek w rankingach aplikacji.
