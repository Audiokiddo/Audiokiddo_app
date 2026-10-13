# Panel (Studio), statystyki, promocje i katalog z serwera

Stan: 6 października 2026.

## Co doszło

| Funkcja | Gdzie | Jak działa |
|---|---|---|
| **Statystyki** | Studio → Serwer → Statystyki | Rodziny płacące teraz, aktywne abonamenty, nowe instalacje, lejek (pierwsze uruchomienie → start zabawy → ukończenie → oferta → zakup), zakupy według produktu i źródła (App Store, Google Play, audiokiddo.pl), polecenia. Okres 7, 30, 90 albo 365 dni |
| **Katalog z serwera** | Studio → Serwer → Katalog w aplikacji | „Publikuj w aplikacji” zapisuje nową wersję katalogu. Rodziny dostają ją przy następnym otwarciu aplikacji, bez aktualizacji w sklepie. Pliki nowych zabaw są od razu dopuszczone do pobierania |
| **Kalendarz nowości** | Data premiery (`released`) w przyszłości | Zabawa pokazuje się na Starcie w „Wkrótce w AudioKiddo” z datą, a w dniu premiery staje się dostępna. Rodzice z włączonymi powiadomieniami dostają wtedy powiadomienie |
| **Promocje** | Studio → Serwer → Promocje | Tytuł, opis, etykieta (np. −20%), czego dotyczy (pakiet, subscription, bundle albo wszystko), daty od–do. W aplikacji baner na Starcie, w Sklepie i na stronie pakietu, z prawdziwą datą końca. Samą cenę zmieniasz w App Store Connect, Google Play i WooCommerce |
| **Własne statystyki w aplikacji** | Tabela `app_events` | Losowy identyfikator instalacji i zdarzenia: uruchomienie, start i koniec zabawy, oferta, zakup, polecenie, pobranie pakietu, włączenie powiadomień. Bez danych dziecka i bez narzędzi firm trzecich |

## Wdrożenie (robi Dawid, w Terminalu w folderze `audiokiddo-app`)

```bash
supabase db push
```

```bash
supabase functions deploy admin
```

## Jednorazowo: Twoje konto administratora

1. Zaloguj się raz w aplikacji swoim e-mailem (Więcej → Konto i zakupy), żeby konto istniało.
2. Supabase → SQL Editor → wklej i uruchom, podmieniając adres:

```sql
insert into public.admins (user_id)
select id from auth.users where email = 'twoj@adres.pl';
```

Tak samo możesz dodać Nelę.

## Uruchomienie Studio

Na Macu:

```bash
cd studio && flutter run -d chrome
```

Logujesz się w zakładce **Serwer** kodem z maila. Studio możesz też zbudować (`flutter build web`) i wgrać folder `studio/build/web` na serwer, na przykład pod `audiokiddo.pl/studio/`. Bez konta administratora panel niczego nie pokaże.

## Jak dodać nową audiozabawę

1. Wgraj nagranie (i okładkę) przez FileZillę do `nagrania/audio/<pakiet>/`.
2. Studio → Treści → dodaj zabawę, wybierz ten sam plik z dysku. Studio wpisze ścieżkę, rozmiar i sumę SHA-256.
3. Opcjonalnie ustaw datę premiery w przyszłości (kalendarz nowości).
4. Studio → Serwer → Katalog w aplikacji → **Publikuj w aplikacji**.
5. Sprawdź: `python3 tool/verify_server_files.py`.

Przed pierwszą publikacją z Studio kliknij **Wczytaj katalog z serwera**. Jeśli serwer nie ma jeszcze katalogu, zaimportuj `app/assets/mock/catalog.json` przez „Importuj JSON”, żeby zacząć od aktualnej wersji.

## Darmowy plan Supabase

Wystarczy na testy, także gdy korzystasz z aplikacji sam albo z kilkoma testerami:
- limity są daleko poza Waszym ruchem (500 MB bazy, 50 000 aktywnych użytkowników miesięcznie, 500 000 wywołań funkcji);
- projekt usypia się po 7 dniach bez żadnego ruchu. Wystarczy otworzyć aplikację raz w tygodniu, a uśpiony projekt wznowisz jednym przyciskiem w panelu Supabase;
- przed publikacją w sklepach przejdź na plan Pro (25 USD miesięcznie): bez usypiania, z kopiami zapasowymi.
