# Polityka prywatności aplikacji AudioKiddo: SZKIC

> **Szkic do weryfikacji prawnej.** Przygotowany na podstawie faktycznego działania aplikacji (stan: Etap 5, 2026-09-27). Nie jest poradą prawną. Części oznaczone `[TODO]` wymagają uzupełnienia, a po podłączeniu serwera (Etap 3) dokument trzeba zaktualizować. Aplikacja jest przeznaczona dla dzieci, więc treść powinien sprawdzić prawnik znający RODO, prawo konsumenckie i wymagania sklepów (Apple Kids Category, Google Play Families).

## 1. Kto odpowiada za Twoje dane

Administratorem danych jest `[TODO: pełna nazwa działalności, adres, NIP — jak w regulaminie sklepu audiokiddo.pl]`, dalej „my”. Kontakt w sprawach prywatności: `[TODO: e-mail]`.

## 2. Najważniejsze w skrócie

- **Nie zbieramy danych o dzieciach.** Dziecko nie ma konta i nie podaje żadnych danych.
- **Bez reklam, bez śledzenia, bez narzędzi analitycznych firm trzecich.**
- **Mikrofon** (tylko w niektórych grach i tylko po zgodzie rodzica) działa wyłącznie w telefonie: dźwięk nie jest nagrywany, zapisywany ani wysyłany. `[Uwaga: funkcja jeszcze nieaktywna. Zostawić ten punkt dopiero po jej włączeniu.]`
- Konto rodzica jest **opcjonalne**. Bez konta zapisujemy na serwerze wyłącznie informacje potrzebne do potwierdzenia zakupu.

## 3. Jakie dane i po co

| Dane | Gdzie są | Po co | Podstawa | Jak długo |
|---|---|---|---|---|
| Postęp słuchania, ulubione, pobrane pliki, ustawienia trybu dziecka, przybliżony wiek dziecka (np. „3+”, jeśli podany) | **tylko w telefonie** | działanie aplikacji | nie dotyczy (nie trafiają do nas) | do usunięcia aplikacji |
| Losowy identyfikator instalacji (tworzony przy zakupie) i informacja o zakupach (produkt, status, daty) | serwer (Supabase, region UE) | potwierdzenie i przywrócenie zakupu, dostęp offline | art. 6 ust. 1 lit. b RODO (umowa) | do usunięcia konta lub `[TODO: okres]` |
| Adres e-mail rodzica (tylko jeśli założy konto) | serwer (Supabase, region UE) | logowanie, dostęp na kilku urządzeniach, przypisanie zakupów ze sklepu audiokiddo.pl | art. 6 ust. 1 lit. b RODO | do usunięcia konta |
| Zamówienia ze sklepu audiokiddo.pl (numer zamówienia, produkt, e-mail kupującego) | serwer (Supabase, region UE) | odblokowanie w aplikacji pakietów kupionych na stronie | art. 6 ust. 1 lit. b RODO | `[TODO: okres, np. do usunięcia konta + wymagany okres dla rozliczeń]` |
| Dane transakcji w App Store / Google Play | Apple / Google | płatność | umowa rodzica ze sklepem | zgodnie z zasadami sklepu |

Nie zbieramy imion ani dat urodzenia dzieci, lokalizacji, kontaktów, zdjęć ani identyfikatorów reklamowych.

## 4. Kto przetwarza dane w naszym imieniu

- **Supabase** (baza danych i pliki, serwery w UE): `[TODO: nazwa podmiotu, umowa powierzenia]`.
- **Apple** i **Google** przetwarzają płatności jako odrębni administratorzy, zgodnie ze swoimi politykami.
- Pliki nagrań pobierane są z naszego serwera. Adres IP urządzenia jest przy tym widoczny dla serwera jak przy każdym połączeniu internetowym `[TODO: logi serwera, okres przechowywania]`.

Nie sprzedajemy danych i nie przekazujemy ich reklamodawcom.

## 5. Twoje prawa

Masz prawo do dostępu do danych, ich sprostowania, usunięcia, ograniczenia przetwarzania, przeniesienia oraz do skargi do Prezesa UODO.

**Usunięcie konta:** w aplikacji (Ustawienia → Konto → Usuń konto, za bramką rodzicielską) albo przez stronę `[TODO: adres strony z formularzem usunięcia konta]`. Usunięcie konta **nie anuluje** subskrypcji. Subskrypcję anulujesz w ustawieniach App Store albo Google Play.

## 6. Dzieci

Aplikacja jest przeznaczona dla dzieci pod opieką rodziców. Dziecko korzysta z trybu dziecka bez zakupów, linków i ustawień. Wszystkie działania wymagające dorosłego (zakupy, linki, udostępnianie, ustawienia, wyjście z trybu dziecka) chroni bramka rodzicielska. Bramka nie jest weryfikacją wieku ani zgodą w rozumieniu RODO.

## 7. Bezpieczeństwo

Połączenia są szyfrowane (HTTPS). Pliki płatne pobierane są przez adresy ważne kilkanaście minut. Pobrane nagrania nie trafiają do kopii zapasowych iCloud ani Google.

## 8. Zmiany

O istotnych zmianach poinformujemy w aplikacji. Data wersji: `[TODO]`.
