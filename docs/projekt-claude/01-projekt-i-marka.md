# AudioKiddo: projekt i marka

## Czym jest AudioKiddo

Interaktywne **audiozabawy dla dzieci 3–9 lat, bez ekranu**. Rodzic włącza zabawę i odkłada telefon.
Dziecko słucha, odpowiada głosem, klaśnięciem albo słowem, szuka rzeczy w pokoju, rusza się, rozwiązuje
zagadki. Zabawy trwają kilka minut (ok. 4–19 min każda), cały pakiet to ok. 10 zabaw.

Dwa kanały sprzedaży:
1. **Strona i sklep audiokiddo.pl** (WordPress + WooCommerce): pakiety na własność, kupowane jednorazowo.
   Klient dostaje pliki MP3 (a przy Detektywie także PDF z aktami sprawy) mailem.
2. **Aplikacja mobilna** (Flutter, iOS i Android, po polsku): te same pakiety po zalogowaniu tym samym
   e-mailem, darmowe zabawy na start i abonament (miesięczny lub roczny). Aplikacja jest w przygotowaniu do
   sklepów; na stronie zapis „Daj znać, gdy aplikacja ruszy”.

## Ludzie

- **Dawid Kubiak**: lektor („100 bajkowych głosów w jednym ciele”), właściciel agencji BiznesoweLove,
  odpowiada za technikę, serwer, sklepy aplikacji.
- **Nela Mariak**: animatorka, współzałożycielka, głos zabaw (lektorka), pilnuje treści i social mediów.
- Specjalistki na stronie: **Julia Kasielska** (fizjoterapeutka dziecięca) i **Maria Lewandowska-Nawrocka**
  (logopeda, pedagog; zgoda na użycie jej nazwiska jest). Opinie specjalistów i rodziców tylko prawdziwe,
  za zgodą; nie wolno tworzyć fikcyjnych opinii ani liczników.

## Pakiety (jak w sklepie i w aplikacji)

| Pakiet | Wiek | Co ćwiczy | Zabawy |
|---|---|---|---|
| **Wyobraźnia** (lawenda) | od 4 lat | wyobraźnię, opowiadanie, słuchanie ze zrozumieniem | Magiczny sklep, Zaginiony skarb, Podróż na inną planetę, Wymyśl znaczenie, Mikstura, Mój superbohater, Dokończ historię, Mistrz kuchni, Magiczny teatr, Co oni odpowiedzieli? |
| **Słowa i Wiedza** (turkus) | od 4 lat | słownictwo, skojarzenia, logiczne myślenie | Co to za przedmiot?, Co to za dźwięk?, Szybkie skojarzenia, Co tu nie pasuje?, Wymień trzy, Znajdź przeciwieństwo, Znajdź synonimy, Ułóż zdanie, Dokończ zgodnie z prawdą, Kto to powiedział? |
| **Detektyw** (żółty) | od 7 lat (w aplikacji i katalogu bywa „od 6”: niespójność do ujednolicenia) | uważne słuchanie, wnioskowanie, pamięć | Złodziej naszyjnika, Znikające dzwonki rowerowe, Na ratunek budce z lodami, Tajemnicze znaki i inne poszlaki, Gadający śmietnik; do każdej sprawy akta do wydrukowania; bohaterowie Max i Mila |

Dodatkowo: gra „Zgubiona Gwiazdka” (5 zakończeń, głos Neli, ElevenLabs), w produkcji „Czas na zakupy”.

Ceny (stan z audytu strategii, 4.10.2026; sprawdzać w sklepie przed każdą kampanią): zestaw trzech pakietów
159,99 zł, Słowa i Wiedza 49,99 zł, Wyobraźnia 49,99 zł, Detektyw 69,99 zł. Zestaw dwóch pakietów
(Wyobraźnia + Słowa i Wiedza) też jest w sklepie. Abonament w aplikacji: ceny miesięczna i roczna z ustawień
wtyczki (przykład: 29,99 zł / 269,99 zł), muszą zgadzać się ze sklepami aplikacji.

## Szop’en: maskotka

Szop pręgowany (Szop’en von Ekran). **Dla dziecka ciepły i zabawny, dla rodzica cięty, suchy, urzędowo-
sarkastyczny.** Jest dyskretny i da się go wyciszyć; w aplikacji nie przerywa nagrań żartami i nie wyskakuje
samoczynnie nad odtwarzaczem.

Pozy (webp na stronie, `strona/audiokiddo-strona/assets/img/szop/`): `chytry` (cwaniak, ręka przy twarzy),
`klaszcze`, `nasluchuje`, `prosi`, `zadowolony` (z kubkiem kawy), `zdziwiony`, a od 3.8.0 także
`znudzony`, `zmeczony`, `zestresowany`. W aplikacji (`app/assets/szop/`): te same plus `placze` oraz ikony
`ikona-*.png`. 17.10.2026 Dawid przysłał nowy arkusz 16 póz (szop z przodu, z boku, z tyłu, cwaniak, zły,
zmartwiony, roześmiany, wzruszający ramionami). **W repozytorium go jeszcze nie ma** (czeka na wgranie).

Pliki o szopie: `docs/szop/PROMPTY.md`, `ANIMACJA.md`, `WDROZENIE.md`, `docs/branding/`.

### Przykłady głosu (do naśladowania)

- Hero: „Ty pijesz ciepłą kawę. Dziecko ratuje świat.”
- „Dobra, żarty żartami. Zobacz, co robi dziecko.”
- „Czwarty raz być smokiem? Dziś smokiem jestem ja.”
- „Ty kroisz cebulę, ja zajmuję dziecko. Nikt nie płacze.”
- „Anulować można zawsze. Nie obrażę się. No, może troszkę.”
- „Ja tylko pilnuję, żeby nikt nie włączył bajki.”
- Porównanie: „Twoja kawa: zimna, wypita na stojąco” kontra „ciepła, wypita na siedząco”.

Zasady: krótko, konkretnie, bez przechwałek; żart nie zastępuje powodu zakupu (to „potrzebuję zabawy na
20 minut”, „jedziemy autem”, „pora wyciszenia”); nic kosztem dziecka; bez obietnic typu „gwarantowane
20 minut ciszy”.

## Kolory i czcionki

- Krem `#FFFBF2`, turkus `#3AAFB0` (ciemny `#1D7478` dla tekstu na białym), żółty `#FAC119`, lawenda
  `#A98EC1` (ciemna `#6B4C8A`), fiolet/noc `#241B3A`, atrament `#1D1A2B`.
- Strona: **nagłówki Baloo 2** (zaokrąglona, własny hosting, od 3.8.0), tekst **Poppins**.
  Wcześniej nagłówki wyświetlały się szeryfową czcionką (błąd: motyw prosił o niezaładowany „Poppins”),
  co się Dawidowi nie podobało.
- Aplikacja: Poppins, zwarte nagłówki, zaokrąglenia 18–24 px, motyw jasny domyślny (`DESIGN.md`).

## Wyróżniki (jak je mówić)

Jedno zdanie: **„Zabawy, które dziecko słyszy, a nie ogląda. I na które odpowiada.”**
Dziecko odpowiada głosem/klaśnięciem; „W drogę” jednym przyciskiem i offline; wieczorny rytuał;
bez reklam i bez śledzenia (tryb dziecka, bramka rodzica); kupione na stronie działa w aplikacji;
mowa rozpoznawana na urządzeniu, nic nie jest nagrywane. Szczegóły: `docs/strona/WYROZNIKI.md`.
