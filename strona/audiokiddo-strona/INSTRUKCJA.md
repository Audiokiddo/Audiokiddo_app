# AudioKiddo – strona 2.2

Wtyczka zastępuje widok strony głównej i pokazuje dwa sposoby zakupu: jednorazowe pakiety oraz subskrypcje do aplikacji. Oferta na stronie czyta ceny pakietów i subskrypcji bezpośrednio z WooCommerce.

## Uruchomienie

1. Zainstaluj lub zaktualizuj tę wtyczkę w WordPressie. Strona główna powinna korzystać z szablonu **AudioKiddo: Start**.
2. Sprawdź identyfikatory istniejących pakietów w **Ustawienia → AudioKiddo strona → Sklep**.
3. Utwórz w WooCommerce proste produkty subskrypcyjne z rozliczeniem miesięcznym i rocznym. Do sprzedaży cyklicznej potrzebny jest działający moduł subskrypcji oraz bramka obsługująca odnowienia.
4. W **Ustawienia → AudioKiddo strona → Subskrypcje w sklepie** wpisz ID produktów odpowiednich dla każdego planu i okresu. Puste lub błędne ID nie pokazuje ceny ani przycisku zakupu.
5. Połącz opłacone zamówienia, odnowienia i anulowania z kontami w aplikacji. Ta wtyczka prezentuje ofertę i prowadzi do zakupów w WooCommerce; sama nie przyznaje dostępu w aplikacji.
6. Ustaw adresy App Store i Google Play, jeśli aplikacja jest już opublikowana. Przetestuj całe przejście: zakup → konto w aplikacji → dostęp → odnowienie → anulowanie → zwrot. Dopiero wtedy zaznacz **Włącz sprzedaż subskrypcji na stronie**.

Obecne `sync-web-purchases` i webhook w aplikacji rozpoznają zakupy pakietów z WooCommerce. Nie obsługują jeszcze czasu ważności, odnowień i anulowań subskrypcji ze strony. Włączenie sprzedaży wymaga rozbudowy tego połączenia; do tego czasu sekcja subskrypcji prowadzi do aplikacji lub kontaktu.

Ceny i warunki subskrypcji widoczne na stronie pochodzą z produktów WooCommerce. Warto sprawdzić, czy opis produktu zawiera czas trwania, zasady odnowienia i sposób aktywacji dostępu w aplikacji.
