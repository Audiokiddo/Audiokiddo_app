# AudioKiddo: aplikacja mobilna

Interaktywne audiozabawy i piosenki dla dzieci, na iOS i Androida (Flutter). Architektura: [`ARCHITECTURE.md`](ARCHITECTURE.md). Raporty z etapów: [`docs/`](docs/).

## Struktura

```
app/                 aplikacja Flutter (iOS + Android)
packages/ak_core/    wspólna logika w czystym Darcie: katalog, dostęp, offline, skrypty zabaw
docs/                raporty etapów, materiały poglądowe
referencje/          klatki z aplikacji referencyjnych (tylko inspiracja)
```

## Wymagania

- macOS z Xcode 27+ (symulator iOS 27)
- Flutter 3.47.x (`~/development/flutter`, ścieżki w `~/.zshrc`)
- Android Studio + Android SDK 36/37, emulator `AudioKiddo_Pixel`
- CocoaPods

Sprawdzenie środowiska:

```bash
flutter doctor
```

## Uruchomienie

```bash
cd app && flutter pub get && flutter run
```

Na konkretnym urządzeniu (listę pokazuje `flutter devices`):

```bash
cd app && flutter run -d emulator-5554
```

## Testy

```bash
cd packages/ak_core && dart test
```

```bash
cd app && flutter test
```

## Treści testowe (do czasu serwera w Etapie 3)

Nagrania zastępcze i lokalny serwer plików:

```bash
python3 tool/dev_content.py
```

```bash
python3 -m http.server 8787 --bind 0.0.0.0 -d dev_content
```

Aplikacja w wersji debug pobiera z `http://127.0.0.1:8787` (iOS) i `http://10.0.2.2:8787` (emulator Androida). Inny adres: `flutter run --dart-define=CONTENT_BASE_URL=...`.

Symulowanie zakupów: zakładka **Moje → ikona klucza** (tylko wersja debug).

## Stan (Etap 2)

- Katalog przykładowy `app/assets/mock/catalog.json` z tytułami i czasami ze strony; pliki to nagrania zastępcze.
- Odtwarzacz z timerem snu, prędkością i trybem bez patrzenia; pobieranie offline z weryfikacją SHA-256; ulubione i postęp zapisywane lokalnie.
- Zakupy symulowane (Etap 3 podłączy sklepy i serwer).
- Identyfikator aplikacji: `pl.audiokiddo.app`.
