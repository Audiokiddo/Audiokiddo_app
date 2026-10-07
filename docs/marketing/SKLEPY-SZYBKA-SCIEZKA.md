# Aplikacja w sklepach: najkrótsza droga do pierwszych pieniędzy

Stan: 7 października 2026. Pełna lista kroków: `docs/WYDANIE.md`. Teksty do sklepów: `docs/SKLEPY.md`. Tutaj tylko kolejność, która najszybciej uruchamia sprzedaż w aplikacji.

Bez kont deweloperskich aplikacja nie zarobi ani złotówki: abonament (239,88 zł/rok, 24,99 zł/mies.) i pakiety w aplikacji działają tylko przez App Store i Google Play. Najdłużej trwa test zamknięty w Google Play (14 dni), więc zaczynamy od niego.

## Dzień 1 (Dawid, ok. 1 godzina)

1. **Google Play Console** (play.google.com/console, 25 USD jednorazowo). Konto prywatne albo firmowe:
   - konto **firmowe** (z numerem D-U-N-S) nie wymaga testu zamkniętego, ale D-U-N-S trwa do 2 tygodni;
   - konto **prywatne** od razu, ale przed publikacją: **12 testerów przez 14 dni bez przerwy**.
   Przy jednoosobowej działalności: konto prywatne i od razu zbieramy testerów.
2. **Apple Developer** (developer.apple.com, 99 USD rocznie). Przy JDG konto indywidualne (sprzedawca: imię i nazwisko).
3. W obu panelach: umowy i dane do wypłat (App Store Connect › Umowy, podatki i bankowość; Play › Profil płatności). Bez tego zakupy nie działają nawet w testach.

## Dni 1–3: 12 testerów Androida

Kto: znajomi rodzice z Androidem, rodzina, klienci z Empiku i sklepu (mailem, jeśli mają zgodę). Lepiej zebrać 16–18 osób, bo ktoś zawsze odpadnie, a 12 musi wytrwać 14 dni.

Każdy tester dostaje **kod na wszystkie zabawy na 90 dni** (darmowy dostęp jako podziękowanie):

```bash
python3 tool/make_codes.py wszystko -n 1 --uses 20 --days 90 --expires 2026-12-31 --note "Testerzy Google Play" --apply
```

Wiadomość do testera (SMS, WhatsApp, mail):

> Cześć! Wypuszczamy AudioKiddo, aplikację z audiozabawami dla dzieci 3–9 lat (bez ekranu: dziecko słucha i odpowiada). Google wymaga, żeby przed premierą 12 osób miało ją przez 2 tygodnie na telefonie z Androidem. Pomożesz?
>
> 1. Podaj mi adres Gmail, którego używasz w Sklepie Play.
> 2. Kliknij link, który Ci wyślę, i zainstaluj aplikację.
> 3. Nie odinstalowuj jej przez 14 dni. Włącz ją czasem dziecku, jeśli chcesz.
>
> W podziękowaniu masz wszystkie zabawy za darmo na 3 miesiące: w aplikacji Sklep › „Masz już dostęp z audiokiddo.pl?” › „Mam kod” › **[KOD]**.

W Play Console: Testowanie › Test zamknięty › utwórz ścieżkę, dodaj adresy Gmail testerów, wyślij link do akceptacji.

## Dni 2–4: pierwsze wersje (lokalna sesja Claude na Macu)

- Android: `flutter build appbundle` podpisany kluczem przesyłania (`docs/WYDANIE.md`, sekcja 3) → Play › test zamknięty.
- iOS: Xcode z kontem Apple Developer (`docs/WYDANIE.md`, sekcja 4) → TestFlight. Od tego momentu aplikacja na Twoim iPhonie nie wygasa po 7 dniach (TestFlight: 90 dni).
- Produkty w obu sklepach (`docs/WYDANIE.md`, sekcja 5): najpierw tylko abonament roczny i miesięczny oraz zestaw 3 pakietów. Pozostałe dopiero, gdy pierwsze działają.

## Dni 4–14: formularze i recenzja Apple

- Apple: kategoria Edukacja + Kids (5 lat i młodsze), App Privacy, polityka prywatności (`docs/strona/sklepy/`), notatka dla recenzenta. Recenzja trwa zwykle 1–3 dni, w Kids czasem dłużej.
- Google: grupa docelowa (dzieci, program Families), Data safety, IARC, adres usuwania konta (`docs/strona/sklepy/usuwanie-konta.html` na audiokiddo.pl).
- **iOS może wejść do sklepu przed Androidem.** Nie czekamy na Google: publikujemy iOS, gdy tylko Apple zatwierdzi.

## Dzień 15+: publikacja Androida

Po 14 dniach testu: Play › wnioskuj o dostęp do produkcji (krótka ankieta o teście) → publikacja.

## Co mierzymy od pierwszego dnia

Studio › Serwer › KPI: True Activation, Free → Paid, D7. Pierwsze 2 tygodnie po premierze traktujemy jako baseline (`docs/ANEKS-ANALITYCZNY.md`, część D).
