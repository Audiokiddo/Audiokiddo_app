# Prompt do nowego wątku (AudioKiddo Care, 28.10.2026)

Wklej w nowej sesji. Najlepiej w Claude Code uruchomionym lokalnie w `/Users/dawidkubiak/Desktop/claude folder/audiokiddo-glos` (tam jest kod Care, iPhone i klucz ElevenLabs). Jeśli sesja jest w chmurze, skopiuj najpierw `docs/care/` i napisz, co jest dostępne.

```
Kontynuuję pracę nad AudioKiddo (polskie interaktywne audiozabawy dla dzieci 3–9 lat, szop Szop’en; właściciele Dawid Kubiak i Nela Mariak). Odpowiadaj po polsku, na końcu lista „Co teraz zrobić”. Kod, komentarze i commity po angielsku, styl jak w otoczeniu.

ZASADY: bez ikon ✨/auto_awesome i emoji-ikon w UI; nigdy nie proś o hasła, klucze ani certyfikaty w rozmowie (pęk kluczy macOS, `supabase secrets set`); wdrożenia produkcyjne (Supabase, FileZilla, sklepy) tylko po wyraźnej zgodzie Dawida w czacie; po większej zmianie dopisz ją do `PRZEKAZANIE-SESJI-2026-10-28.md` w Skarbnicy (/Users/dawidkubiak/Desktop/SkarbnicaAudiokiddo/07-zadania-i-otwarte-sprawy/); gdy limit konta zbliży się do ok. 97%, zatrzymaj się i przygotuj prompt dla kolejnego konta. Kids: zakupy i linki tylko za bramką rodzica, mikrofon i rozpoznawanie mowy tylko po zgodzie rodzica i tylko w telefonie. Instalacja na iPhonie: AK_DEVICE=00008120-001408903463C01E bash tool/phone_build.sh, po zmianach flutter test w app/.

NAJPIERW PRZECZYTAJ: Skarbnica: 07-zadania-i-otwarte-sprawy/PRZEKAZANIE-SESJI-2026-10-28.md oraz SKARBNICA-PRZEKAZANIE-2026-10-28-CHMURA.md; repo (gałąź claude/busy-babbage-aeq1ro): docs/care/KONCEPCJA-CARE.md, EKRAN-CARE-PROJEKT.md, PROMPT-SESJA-LOKALNA.md, odcinki/tacka-czy-taczka.md oraz AudioKiddo-Care-prezentacja.pdf.

STAN: Care („Uszy w górę”) = krótkie audiozabawy słuchowe do wspólnego słuchania, 5–6 lat, obok terapii, nie zamiast. Pilot bez mikrofonu, bez nagrań dzieci, bez ocen wymowy i procentów; ocenę „łatwo / w sam raz / trudno” wystawia rodzic. Pakiety: Szop’en i Szumiąca Szafa (sz–s, cz–c; pilot), Koszyk Rymusia, Kot Bąbel. Głosy: Szop’en = „szop” (Dawid), Szuszu = „nela”. Świąteczne odcinki Szop’ena bez zmian. W CRM są 9 zadań Care (klucze care-*). Jutro (29.10) Dawid rozmawia z dyrektorem szkoły w Malechowie (logopeda) i pokaże prezentację.

DO ZROBIENIA (domyślnie w tej kolejności; zapytaj mnie, od czego zacząć):
1. Nagraj odcinek próbny: python3 tool/care_episode.py tacka-czy-taczka --dry-run, potem bez --dry-run; sprawdź głosy.
2. Przebuduj zakładkę Care według EKRAN-CARE-PROJEKT.md (kontrast, brak procentów, jeden odtwarzacz, okładki zestawów, sekcja „Dla rodzica”, ekran po zabawie, karta tygodnia PDF) i połącz ze Startem (karta pod „Zabawą dnia”, „Co teraz?”, propozycja po zabawie, filtr w Bibliotece). Wgraj odcinek próbny do zestawu Szumiąca Szafa.
3. Po rozmowie w Malechowie: zaktualizuj zakres pilota i dokumenty o odpowiedzi dyrektora (konsultant, słowa, kolejność, lista „kiedy do logopedy”).
4. Audyt przepływów danych aplikacji pod pilota (konto, zdarzenia, kody; app/lib/features/insights/events.dart) i projekt polityki prywatności dla Care do prawnika.
5. Później: odcinki 1–8 Szumiącej Szafy, Koszyk Rymusia, wariant bez muzyki, wybór głosem (tylko na urządzeniu, wynik orientacyjny), panel logopedy.

OTWARTE (poza Care): konta w sklepach (Apple, Google Play, 12 testerów), wtyczka strony 3.25.2–3.25.3 (kodu nie ma na GitHubie), strona audiokiddo.pl: hasła „polecane przez logopedów” wymagają potwierdzenia, głos Szop’ena w aplikacji (tool/ui_voice.py --voice szop).

Na start zapytaj mnie, co chcę teraz zrobić.
```
