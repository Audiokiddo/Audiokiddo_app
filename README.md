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

## Stan (Etap 1)

- Katalog to plik przykładowy `app/assets/mock/catalog.json` (tytuły i czasy ze strony audiokiddo.pl; pliki, okładki i skład próbki tymczasowe).
- Każda zabawa odtwarza dźwięk testowy `app/assets/dev/test_tone_90s.m4a`, dopóki nie ma prawdziwych nagrań.
- Brak zakupów i konta: odblokowana jest tylko darmowa próbka (Etap 3).
- Identyfikator aplikacji: `pl.audiokiddo.app` (do potwierdzenia przed pierwszym wysłaniem do sklepów).
