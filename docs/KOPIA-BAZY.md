# Codzienna kopia bazy (GitHub Actions)

Plan darmowy Supabase nie robi kopii zapasowych. Ta kopia robi się sama co noc o 4:15. Jest zaszyfrowana (AES-256) i trzymana 30 dni na GitHubie. Dzięki temu możemy zostać na planie darmowym do czasu, aż przychód pokryje plan Pro.

## Ważne: repozytorium jest publiczne

Dziś (6.10.2026) repozytorium `Audiokiddo/Audiokiddo_app` jest **publiczne**. Każdy widzi kod aplikacji, serwera i CRM. Haseł ani kluczy w nim nie ma, a kopia bazy jest zaszyfrowana, ale kod firmy nie powinien być publiczny.

Zmień to: github.com/Audiokiddo/Audiokiddo_app → Settings → na dole **Danger Zone** → **Change visibility** → Private.

W prywatnym repozytorium GitHub daje 2000 darmowych minut automatycznych testów miesięcznie. Kopia zajmuje ok. 90 minut miesięcznie. Pełne testy z buildem iOS przy każdej zmianie zużywają więcej, więc w razie potrzeby wyłączę build iOS w testach.

## Ustawienie (raz, 10 minut)

1. **Adres bazy:**
   1. Supabase → projekt audiokiddo → przycisk **Connect** (u góry).
   2. Zakładka „Connection string”, typ **Session pooler** (działa z GitHuba).
   3. Skopiuj adres. Zamiast `[YOUR-PASSWORD]` wklej hasło bazy z aplikacji Hasła.
2. **Hasło do kopii:** w aplikacji Hasła utwórz nowy wpis „AudioKiddo kopia bazy” z długim, wygenerowanym hasłem. Bez niego kopii nie otworzysz.
3. **Sekrety w GitHubie:**
   1. github.com/Audiokiddo/Audiokiddo_app → Settings → Secrets and variables → Actions → **New repository secret**.
   2. Dodaj `SUPABASE_DB_URL`: adres z punktu 1.
   3. Dodaj `BACKUP_PASSPHRASE`: hasło z punktu 2.
4. **Sprawdzenie:** zakładka **Actions** → „Kopia bazy” → **Run workflow**. Po 2–3 minutach na dole przebiegu pojawi się plik `audiokiddo-RRRR-MM-DD`.

Jeśli kopia się nie uda, GitHub wyśle Ci mail o nieudanym przebiegu.

## Odtworzenie (gdyby coś poszło bardzo źle)

1. Pobierz plik z zakładki Actions i rozpakuj ZIP.
2. W Terminalu (zapyta o hasło do kopii):
   ```
   gpg -d audiokiddo-RRRR-MM-DD.tar.gz.gpg | tar xz
   ```
3. Napisz do mnie. Odtworzę bazę do nowego projektu Supabase komendami z dokumentacji Supabase (role, schemat, dane), a Ty wpiszesz hasło nowej bazy w swoim terminalu.
