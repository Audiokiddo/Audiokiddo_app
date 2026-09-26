# AudioKiddo Studio

Panel treści dla Dawida i Neli (Flutter Web). Korzysta z `packages/ak_core`, więc błędy wykrywa **tym samym kodem, którego używa aplikacja** w telefonie.

## Uruchomienie

```bash
cd studio && flutter run -d chrome
```

## Co potrafi (tryb lokalny)

- **Treści**: lista z oznaczeniem błędów; edycja tytułu, opisu dla rodzica, pakietu, wieku, czasu, sytuacji, wymagań, dostępu (darmowa / płatna) i ID produktu w sklepach. Wybór pliku audio lub PDF automatycznie wpisuje ścieżkę, rozmiar i sumę SHA-256.
- **Skrypty gier interaktywnych**: szablon, nagrania (segmenty), zmienne i kroki z formularzy. Błędy walidatora pokazują się na bieżąco po polsku.
- **Pakiety i półki**: edycja, zmiana kolejności na półkach przeciąganiem.
- **Publikacja**: podsumowanie błędów; eksport `catalog.json` z podbitą wersją jest możliwy tylko przy poprawnym katalogu.
- **Szkic** zapisuje się w przeglądarce co chwilę; import pliku JSON zastępuje szkic.

## Po podłączeniu serwera (Etap 3)

- logowanie tylko dla kont z rolą `admin` (tabela `admins`);
- zapis do bazy zamiast szkicu w przeglądarce;
- wysyłanie plików do Supabase Storage;
- „Publikuj” tworzy nową wersję katalogu, a „Przywróć” wraca do poprzedniej.
