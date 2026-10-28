# Maile AudioKiddo (MailerLite)

Stan: 7 października 2026. Gotowe teksty do wklejenia w MailerLite. Pisane do rodzica, krótko, z jednym przyciskiem. Szop’en mówi do dorosłych urzędowo-sarkastycznie, ale nigdy nie straszy i nie zawstydza.

Zasady:
- Wysyłamy tylko do osób ze zgodą marketingową (zapis na stronie, checkbox w kasie). Mail o porzuconym koszyku wymaga zgody tak samo jak newsletter.
- Bez sztucznej presji („ostatnie sztuki”, liczniki). Termin podajemy tylko, gdy jest prawdziwy (np. koniec promocji, Wigilia).
- Linki z parametrami: `?utm_source=mailerlite&utm_medium=email&utm_campaign=<nazwa>`. Wtedy w zamówieniu WooCommerce widać, który mail sprzedał, a w Studio (KPI) który kanał.
- `{$name}` to pole imienia w MailerLite. Gdy go nie ma, MailerLite wstawi pusty tekst, więc powitania są pisane tak, żeby działały i bez imienia.

---

## 1. Porzucony koszyk (automatyzacja MailerLite + WooCommerce)

Wymaga integracji MailerLite z WooCommerce (wtyczka „MailerLite – WooCommerce integration”, opcja „Porzucone koszyki”). Wyzwalacz: koszyk porzucony, warunek: brak zamówienia.

**Mail 1 (po 1 godzinie)**
- Temat: Coś zostało w koszyku (Szop’en pilnuje)
- Podgląd: Zabawy czekają. Dziecko jeszcze o nich nie wie.

> Cześć {$name},
>
> w koszyku AudioKiddo czeka: **{$cart_items}**. Szop’en stoi przy nim od godziny i udaje, że nie patrzy.
>
> Jeśli coś przerwało zakup (telefon, obiad, dziecko na szafie), wystarczy jedno kliknięcie, żeby wrócić do zakupu.
>
> **[Wracam do koszyka]**
>
> Masz pytanie przed zakupem? Odpisz na tego maila, odpowiadamy po ludzku.

**Mail 2 (po 24 godzinach)**
- Temat: Jak to wygląda w praktyce (2 minuty)
- Podgląd: Posłuchaj fragmentu, zanim zdecydujesz.

> Cześć {$name},
>
> najczęstsze pytanie rodziców przed zakupem: „czy moje dziecko się w to wciągnie?”. Najprościej sprawdzić: włącz przy nim **[fragment zabawy]** i zobacz, co zrobi.
>
> - działa bez ekranu: dziecko słucha i odpowiada,
> - 10–20 minut jedna zabawa, dla 3–9 lat,
> - kupujesz raz, bez abonamentu.
>
> **[Dokończ zakup]**

**Mail 3 (po 72 godzinach, ostatni)**
- Temat: Ostatnie przypomnienie, potem Szop’en odpuszcza
- Podgląd: Koszyk zostaje, my już nie piszemy.

> Cześć {$name},
>
> to ostatni mail o koszyku, obiecujemy. Jeśli AudioKiddo to nie jest teraz dobry moment, rozumiemy.
>
> A jeśli po prostu zabrakło chwili: **[koszyk czeka tutaj]**.
>
> Szop’en (Departament Spokojnych Popołudni)

---

## 2. Po pobraniu próbki (zapis „Wyślij mi próbkę”)

Wyzwalacz: dołączenie do grupy „Próbka”. Formularz na stronie: e-mail i zgoda, bez innych pól.

**Mail 1 (od razu)**
- Temat: Twoja próbka AudioKiddo
- Podgląd: Włącz przy dziecku i zobacz, co się stanie.

> Cześć,
>
> oto obiecana próbka: **[Posłuchaj teraz]**. Najlepiej działa tak: włącz, połóż telefon i nic nie tłumacz. Zabawa sama powie dziecku, co robić.
>
> Jutro napiszę, jak inni rodzice używają AudioKiddo na co dzień.

**Mail 2 (po 2 dniach)**
- Temat: 3 momenty, w których rodzice włączają AudioKiddo
- Podgląd: Obiad, samochód, wieczór.

> Cześć,
>
> rodzice najczęściej sięgają po AudioKiddo w trzech sytuacjach:
>
> 1. **Gotowanie obiadu:** dziecko szuka przedmiotów w kuchni, Ty kroisz.
> 2. **Samochód:** zagadki i zgadywanki zamiast „daleko jeszcze?”.
> 3. **Wyciszenie wieczorem:** spokojne przygody przed snem.
>
> Wszystkie trzy znajdziesz w zestawie trzech pakietów: **[Zobacz zestaw]**.

**Mail 3 (po 5 dniach)**
- Temat: Zestaw trzech pakietów, raz i na zawsze
- Podgląd: Bez abonamentu, bez reklam, bez ekranu.

> Cześć,
>
> jeśli próbka się spodobała, zestaw trzech pakietów to najprostszy wybór: Detektyw, Słowa i Wiedza oraz Wyobraźnia, razem kilkadziesiąt zabaw.
>
> - kupujesz raz, masz na zawsze,
> - działa offline po pobraniu,
> - bez reklam i bez zbierania danych dziecka.
>
> **[Kupuję zestaw]**
>
> Wolisz zacząć od jednego pakietu? **[Zobacz pakiety]**

---

## 3. Dawni klienci: drugi pakiet

Segment: klienci, którzy kupili jeden pakiet, a nie kupili zestawu. Kampania jednorazowa. Kod rabatowy tworzysz w WooCommerce (np. `DRUGIPAKIET`, −20% na pakiety, ważny 14 dni, jedno użycie na klienta).

- Temat: Który pakiet będzie następny?
- Podgląd: Dla tych, którzy już znają AudioKiddo: −20% na drugi pakiet.

> Cześć {$name},
>
> dziękujemy, że AudioKiddo jest już u Was. Jeśli Twoje dziecko polubiło **{pakiet}**, to dwa pozostałe pakiety działają podobnie, tylko inaczej ćwiczą:
>
> - **Detektyw:** logiczne myślenie i uważne słuchanie,
> - **Słowa i Wiedza:** słownictwo i skojarzenia,
> - **Wyobraźnia:** opowiadanie i podejmowanie decyzji.
>
> Przez 14 dni drugi pakiet jest tańszy o 20% z kodem **DRUGIPAKIET**.
>
> **[Wybieram pakiet]**

---

## 4. Święta (lista: wszyscy subskrybenci)

**Mail A (ok. 12 listopada)**
- Temat: Prezent, który nie zbiera kurzu
- Podgląd: Audiozabawy z kodem do kartki. Dla wnuków, chrześniaków, dzieci znajomych.

> Cześć {$name},
>
> szukasz prezentu dla dziecka 3–9 lat, który nie jest kolejnym plastikiem ani ekranem? Kupujesz na stronie, dostajesz **kod mailem**, drukujesz **kartkę z Szop’enem** i wręczasz.
>
> **[Zobacz prezenty]** (link: audiokiddo.pl/prezent)

**Mail B (ok. 18 grudnia)**
- Temat: Prezent na ostatnią chwilę? Kod przychodzi w kilka minut
- Podgląd: Działa nawet w Wigilię rano.

> Cześć {$name},
>
> kurier już nie zdąży, my tak. Kod prezentowy AudioKiddo przychodzi mailem kilka minut po zakupie, kartkę drukujesz w domu.
>
> **[Kupuję prezent]**

---

## 5. Automatyzacje do włączenia w MailerLite (kolejność)

1. Porzucony koszyk (sekcja 1): największy zwrot za najmniej pracy.
2. Próbka (sekcja 2): wymaga formularza „Wyślij mi próbkę” na stronie.
3. Kampania „drugi pakiet” (sekcja 3): jednorazowo, potem co kwartał dla nowych klientów.
4. Kampanie świąteczne (sekcja 4).

Szkice możesz też zrobić w Studio › CRM › Mailing › „Szkic w MailerLite”. Wtedy wysyłkę zatwierdzasz sam.
