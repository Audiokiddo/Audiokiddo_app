# AudioKiddo: pakiet plików do Claude Projects

Stan na 17.10.2026. Zebrane z sesji nad stroną audiokiddo.pl (10–17.10.2026) i z dokumentacji repozytorium
`audiokiddo/audiokiddo_app`. Wgraj wszystkie pliki z tego folderu do **Project knowledge**, a poniższy tekst
wklej jako **Project instructions** (Custom instructions).

## Pliki w pakiecie

| Plik | Do czego |
|---|---|
| `01-projekt-i-marka.md` | Czym jest AudioKiddo, ludzie, pakiety, ceny, głos marki, Szop’en, kolory i czcionki |
| `02-strona-audiokiddo-pl.md` | Strona: wtyczka WordPress, struktura kodu, wdrażanie, wyniki szybkości, pułapki, co zrobione |
| `03-sklep-zakup-dostep-aplikacja.md` | Droga klienta: zakup → mail z plikami → ten sam pakiet w aplikacji; stan aplikacji i sklepów |
| `04-preferencje-i-decyzje.md` | Co Dawid i Nela lubią, a czego nie; zasady współpracy; ustalone decyzje |
| `05-do-zrobienia.md` | Otwarte zadania, SEO, marketing, pytania bez odpowiedzi, prompty do grafik (ChatGPT) |

## Czego NIE ma w tym pakiecie (a warto dołączyć z repozytorium, jeśli Project ma pracować nad aplikacją)

- `ARCHITECTURE.md` (42 KB): pełna architektura aplikacji Flutter i backendu Supabase.
- `docs/PRZEKAZANIE-PROJEKTU.md`: przekazanie projektu aplikacji z 4.10.2026 (zadania, ograniczenia sesji w chmurze).
- `docs/DOSTEP-Z-SKLEPU.md`: dostęp z zakupu na stronie do aplikacji (e-mail, numer zamówienia, kody).
- `docs/STRATEGIA-5000-DO-MILIONA.md`: plan reklam na 5 000 zł i rachunek na 1 mln zł zysku.
- `docs/WYDANIE.md`, `docs/SKLEPY.md`: wydanie w App Store i Google Play.
- `docs/strona/AUDYT-STRONY-2026-10-10.md`: audyt szybkości i SEO strony.

Haseł, kluczy API ani danych logowania **nie wklejaj** do plików Projects ani do rozmowy.

## Tekst do wklejenia jako „Project instructions”

```
Pracujesz nad projektem AudioKiddo: interaktywne audiozabawy dla dzieci 3–9 lat, bez ekranu
(aplikacja Flutter + sklep WooCommerce i strona audiokiddo.pl). Twórcy: Dawid (lektor, właściciel
agencji BiznesoweLove) i Nela (animatorka, współzałożycielka, lektorka). Maskotka: szop Szop’en.

Zasady:
- Odpowiadaj po polsku, prosto i konkretnie. Na końcu krótka lista „Co teraz zrobić”.
- Kod, komentarze w kodzie i commity po angielsku, w stylu otaczającego kodu.
- Nigdy nie proś o wklejanie haseł, kluczy API ani certyfikatów. Podawaj bezpieczny sposób
  (zmienne środowiska, pęk kluczy, `supabase secrets set`).
- Zakupy i linki zewnętrzne w aplikacji tylko za bramką rodzica (kategoria Kids).
- Strona audiokiddo.pl ma mieć w PageSpeed co najmniej 95 na telefonie i komputerze: każdą zmianę
  na stronie mierz (Lighthouse) i nie pogarszaj wyniku.
- Humor Szop’ena: cięty, suchy, wobec rodzica; wobec dziecka ciepły. Nigdy kosztem dziecka.
- Nie zmyślaj opinii, liczników ani danych o sprzedaży. Opinie tylko prawdziwe i za zgodą.
- Zanim zrobisz coś nieodwracalnego (usunięcie, publikacja, zmiana ceny, kampania), zapytaj.

Najpierw przeczytaj pliki 01–05 z Project knowledge. Stan prac i otwarte zadania są w 05.
```
