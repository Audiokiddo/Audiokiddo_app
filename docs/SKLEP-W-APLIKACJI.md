# Sklep w aplikacji

Stan: 2 października 2026. Kod: `app/lib/features/purchases/shop.dart` (logika) i `shop_screen.dart` (ekrany), testy `app/test/shop_test.dart`.

## Co działa

| Miejsce | Co robi |
|---|---|
| Zakładka **Sklep** (pasek: Start, Biblioteka, Sklep, Ulubione, Więcej) | Abonament „Wszystko w jednym” (rocznie i miesięcznie, okres próbny, cena roczna w przeliczeniu na miesiąc, uczciwy rabat liczony z cen sklepu), pakiety, zestawy, „Kupione na audiokiddo.pl?”, przywracanie zakupów, informacje prawne |
| Karta pakietu | Liczba zabaw, minuty słuchania, wiek, czego uczy, darmowa zabawa na próbę, cena albo „Masz ten pakiet” |
| Strona pakietu `/pakiet/<id>` | Opis, „Co ćwiczy”, „Wypróbuj za darmo”, cała zawartość z kłódkami, przycisk zakupu, podpowiedź zestawu (taniej o …), postęp dziecka w kupionym pakiecie |
| Zestawy | Oszczędność liczona z prawdziwych cen sklepu, pokazywana tylko gdy jest realna |
| Start | Po ukończeniu darmowej zabawy z pakietu: jedna spokojna karta „Chcecie więcej takich zabaw?”, do ukrycia na tydzień |
| Listy zabaw | Zablokowane zabawy mają kłódkę zamiast przycisku odtwarzania |
| Szczegóły zablokowanej zabawy | „Zobacz cały pakiet …” obok „Odblokuj” |

Zasady (kategoria „Dla dzieci” w App Store i Google Play):
- **Zakupy:** każdy zakup i każdy link poza aplikację przechodzi przez bramkę rodzica.
- **Tryb dziecka:** brak sklepu, cen i propozycji zakupu.
- **Bez sztuczek:** żadnych odliczających zegarów, fałszywych promocji ani zmyślonych opinii.
- **Ceny:** zawsze z App Store / Google Play, nigdy wpisane na sztywno w ekranie.

## Dodane 2 października 2026

| Pomysł | Jak działa |
|---|---|
| **Fragmenty płatnych zabaw** | `tool/make_previews.py` wycina 45 s (piosenki 30 s) z łagodnym wyciszeniem, 25 plików w `dev_content/previews/`, wpis `preview` w katalogu. Przycisk ze słuchawkami przy zablokowanej zabawie (listy, strona pakietu) i „Posłuchaj fragmentu” na ekranie zabawy. Grają z serwera, wstrzymują inne nagranie, kończą się po wyjściu z ekranu. Na serwerze to darmowe pliki (migracja `20261002000001_preview_files.sql`). |
| **Dyplom po ukończeniu pakietu** | Gdy dziecko ukończy wszystkie zabawy pakietu, na Starcie pojawia się „Pakiet … ukończony, Wręcz dyplom”. Ekran dyplomu: spadające konfetti, dyplom z rozetą, imieniem, datą i umiejętnościami, Szop’en, fanfara i gratulacje głosem. **Nagroda**: sekretna wiadomość od Szop’ena, osobna dla każdego pakietu (zagadka, zadanie detektywa, wyobraźnia na dobranoc), z tekstem na ekranie. Dyplom można zapisać lub wysłać jako obrazek (za bramką rodzica). Dyplomy zbierają się w profilu dziecka, a kupiony i ukończony pakiet ma „Zobacz dyplom”. |
| **Nowości i sezony** | Pole `released` (data wydania) w pakietach i zabawach: przez 30 dni etykieta „NOWE” i sekcja „Nowości” na Starcie. Pięć kolekcji sezonowych w katalogu (`season_from`/`season_to`): Jesienne wieczory, Zimowe wieczory w domu, Wiosenne zagadki, Wakacje w drodze, Nowy rok w przedszkolu. Start pokazuje tę, która pasuje do dnia. Daty i składy zmienia się w katalogu (Studio zachowuje pola). |

## Pomysły na później (do decyzji)

1. ~~Próbki płatnych zabaw~~ (zrobione). Krótki fragment każdej płatnej zabawy, przygotowany przy cięciu nagrań. Rodzic słyszy jakość, zanim kupi.
2. ~~Dyplom po ukończeniu pakietu~~ (zrobione) (jest już PDF dyplomu „Słowa i Wiedza”). Pamiątka dla dziecka, a dla rodzica naturalny moment na „co dalej”.
3. **Kod prezentowy.** Kupiony na audiokiddo.pl (np. dla dziadków), wpisany w aplikacji. Sklep nie zabiera wtedy prowizji, a w aplikacji nie ma linku do zakupu poza sklepem, więc zgadza się to z zasadami Apple i Google.
4. ~~Nowości~~ (zrobione). Etykieta „Nowe” w katalogu (pole z datą wydania) i jedna wzmianka na Starcie przy nowym pakiecie.
5. ~~Kolekcje sezonowe~~ (zrobione; pakiety sezonowe z nowymi nagraniami czekają na treści): święta, wakacje w aucie, pierwszy dzień w przedszkolu.
6. **Rekomendacja pakietu do wieku i celów dziecka** z ankiety rodzica w Planie.
7. **Rodzinne udostępnianie (Family Sharing).** Włączenie w App Store Connect, żeby zakup działał na telefonach obojga rodziców.
8. **Prawdziwe opinie rodziców** dopiero po premierze, za zgodą, z imieniem i miastem.
