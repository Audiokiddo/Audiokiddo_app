# Szop AudioKiddo — projekt 2,5D i przygotowanie animacji

## Dostarczone
- szop-koncepcja.png — prezentacja wyglądu i obu tonów postaci.
- szop-mimika.png — sześć referencji mimiki: cwaniak, mrugnięcie, olśnienie, ziewanie, ciepły uśmiech, mówienie.
- szop-baza-robocza.png — frontalna poza z odsuniętymi łapami. Plik roboczy, nie gotowy zasób produkcyjny: mimo kanału alfa eksport nadal pokazuje poświatę. Wymaga oczyszczenia maski.
Grafiki są płaskimi renderami. Nie zawierają osobnych warstw ani szkieletu. Plansza mimiki nie jest sekwencją klatek. Nie wdrożono postaci do aplikacji.

## Jak uzyskać animowane 2,5D
Zachować wygląd płytkiej, matowej bryły, ale poruszać oddzielnymi częściami 2D. Bez silnika 3D i bez renderowania futra na telefonie. Światło z lewego górnego rogu zapisane w grafice; tylko małe obroty, by cienie nie przeczyły ruchowi. Duże obroty głowy wymagają osobnego rysunku.

## Warstwy do przygotowania
Od tyłu: ogon (3 zachodzące segmenty), tylna noga, przednia noga, tułów z brzuchem, ramiona i przedramiona, dłonie zamienne, uszy, głowa z maską, białka i źrenice, powieki, osobne brwi, pysk z nosem, zamienne usta, identyfikator. Oddzielny cień pod stopami.
Każda część musi mieć odtworzoną powierzchnię schowaną pod sąsiednią warstwą. Nie wystarczy wyciąć widocznego fragmentu. Stawy pod naturalnymi zakładkami, margines ok. 10–15% długości części.
Stały punkt bazowy między stopami. Pivot głowy przy szyi, uszu u nasady, kończyn w stawach, ogona przy miednicy. Identyfikator przy zaczepie.
Zaakceptowaną głowę odrysować raz i na niej budować wszystkie miny — generowane studia różnią się drobnymi proporcjami.

## Ruch i osobowość
- Spoczynek: łagodny oddech, sporadyczne mrugnięcie; bez ciągłego podskakiwania.
- Cwaniak: spojrzenie w bok, pauza, jedna brew w górę, półuśmiech.
- Zaspał: opada głowa, zamknięte oczy, krótkie ziewnięcie.
- Przypomniał sobie: otwarcie oczu, uniesienie głowy, gest łapy; jedna krótka scenka.
- Dla dziecka: miękkie brwi, pogodny uśmiech, powolne machanie.
- Mówienie: kilka kształtów ust, uruchamianych tylko podczas kwestii maskotki, nigdy obcego lektora.
- Pomoc: krótki gest wskazujący, potem nieruchoma pozycja.
Scenki żartobliwe nie mogą faktycznie opóźniać przypomnień ani blokować przycisków.

## Budżety do sprawdzenia na telefonach — cele, nie zmierzone wyniki
Docelowy atlas 1024×1024 RGBA: ok. 4 MiB surowej tekstury; 2048×2048: ok. 16 MiB. Rozmiar PNG/WebP na dysku nie odpowiada zajętości pamięci.
Cel: jeden atlas podstawowy, warianty ubrań ładowane na żądanie, od 20 do 35 ruchomych elementów. Zweryfikować ostrość przy 48, 96 i 180 punktach logicznych; dla małej ikonki użyć samej głowy.
Zatrzymywać animację w tle, poza ekranem i przy ograniczeniu ruchu; zachować dotychczasowe mechanizmy aplikacji. Nie dekodować tekstur w każdej klatce.
Widget systemowy: statyczny eksport odpowiedniej miny, bez zakładania ciągłego odtwarzania animacji.
Przed wdrożeniem sprawdzić czas klatki, pamięć, krawędzie na jasnym i ciemnym tle oraz słabszy telefon. Nie wykonano jeszcze pomiarów.

## Następny etap
Oczyszczenie alfy, przygotowanie rzeczywistych warstw i szkieletu, prototyp trzech stanów (spoczynek/cwaniak/olśnienie), test wydajności, dopiero integracja. Obecny pakiet ustala wygląd i specyfikację, nie zastępuje tego etapu.

