# Preferencje i decyzje (co powiedział Dawid)

Zebrane z rozmowy 10–17.10.2026. Traktuj jako obowiązujące, dopóki Dawid nie zmieni zdania.

## Jak ze mną pracować

- Odpowiadaj **po polsku**; pisz na bieżąco, co robisz (prośba: „pisz co robisz po polsku”).
- Na końcu odpowiedzi lista „Co teraz zrobić” z krokami po stronie Dawida (np. wgranie plików, usunięcie konta).
- Pliki dla Dawida zapisuj w folderze projektu (`/home/user/Audiokiddo_app/…`), bo tylko takie otworzy w aplikacji.
- Wdrażaj sam, gdy Dawid o to prosi, ale **mierz po wdrożeniu** (strona, koszyk, Lighthouse) i mów uczciwie,
  co jest sprawdzone, a co nie.
- Gdy Dawid pyta, czego brakuje w grafikach: **podaj prompty do ChatGPT** (sam je wygeneruje). Prompty w `05-do-zrobienia.md`.

## Wymagania twarde

- **PageSpeed co najmniej 95 na telefonie i na komputerze** (cel z 10.10, powtórzony 17.10: „pamiętaj, by strona
  uzyskała ponad 95% co najmniej w speedpage”). Każda zmiana strony musi to utrzymać.
- Strona i koszyk muszą działać po każdej zmianie (dodanie do koszyka, przejście do `/koszyk/`).
- Konto `claude-tymczasowy` i zmienne `WP_USER`/`WP_PASS` mają zostać usunięte po zakończeniu wdrożeń.

## Projekt strony głównej: ustalone życzenia

1. **Pierwsza sekcja jest najważniejsza**: ma zatrzymać rodzica i zrobić wrażenie. Szop ma być tam **bardziej
   cwaniacki** i ma **zwizualizować działanie Audiokiddo** (zrobione: scena z rozmową gry i dziecka).
2. **Więcej ilustracji niż tekstu.** Sekcja z pomysłami na zabawy ma być **mniejsza**: tytuł plus okładka albo ikonka.
3. **Czcionka nagłówków** (szeryfowa, która była) **się nie podobała** → Baloo 2.
4. Sekcja „Ono ćwiczy. Ty odpoczywasz.” była **słabo wykonana wizualnie**, bez animacji → ma być lepsza w UX/UI,
   ciekawsza, praktyczniejsza, przykuwać wzrok (zrobione: przełącznik bez/z + okładki umiejętności).
5. Strona ma być **zabawna i z ciętym dowcipem**, ale tak, by rodzic **w prosty sposób dowiedział się
   wszystkiego, co najważniejsze**, **miał wszystko zwizualizowane i nie musiał się domyślać**, **chciał kupić**
   oraz **polubił markę i maskotkę**.
6. **Szop przemieszcza się podczas przewijania**: wychodzi zza krawędzi, znika, pojawia się w innej sekcji z nowym
   tekstem, ale **nie we wszystkich sekcjach**, żeby nie był nachalny (zrobione: cztery sekcje).
7. **Proces od zamówienia do otrzymania**: co się dzieje, gdzie kupujący może to wykorzystać, że dostaje nie tylko
   pliki, ale też dostęp do swojego pakietu w aplikacji, najlepiej graficznie i z animacją (zrobione: sekcja
   `#po-zakupie` z paczką wędrującą po krokach).
8. Dawid przysyła **najnowsze zdjęcia szopa** (arkusz 16 póz, 17.10): używać ich zamiast starych, gdy trafią do repo.

## Decyzje z wcześniejszych dokumentów (nadal obowiązują)

- Produkt: pakiety na własność (MP3 + dostęp w aplikacji), darmowe zabawy w aplikacji, abonament tylko w aplikacji.
- Marka: turkus, lawenda, żółty; Szop’en dyskretny, wyciszalny, nie przerywa nagrań żartami.
- Kategoria „Kids” w App Store: bramka rodzica przed zakupami i linkami, mikrofon po zgodzie, mowa tylko lokalnie.
- Budżet reklam startowych 5 000 zł, cel zysk 1 mln zł, mierzenie po zamówieniach (zob. plik 03).
- Opinie i zdjęcia specjalistów tylko za ich zgodą. Logopedka Maria Lewandowska-Nawrocka zgodę wyraziła.
- Odpowiedzi do Dawida po polsku, kod i commity po angielsku, hasła i klucze nigdy w rozmowie.

## Nierozwiązane

- 17.10 padła wiadomość: **„tak niech okładki z nimi wracają”**. W rozmowie nie było wcześniej pytania o okładki,
  więc nie wiadomo, o co chodziło (możliwe: okładki zabaw przy opisach umiejętności/pakietów, albo okładki
  w kafelkach poradników; obie rzeczy są już w 3.8.0). **Zapytaj Dawida, co dokładnie ma wrócić.**
