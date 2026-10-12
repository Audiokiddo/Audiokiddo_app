# CarPlay

Kod jest gotowy. W aucie są cztery zakładki:
- **Na drogę**: zabawy na podróż, pobrane najpierw;
- **Ostatnie**: to, czego rodzina słuchała, z paskiem postępu i „Zostało X min”;
- **Pakiety**: każdy pakiet otwiera listę swoich zabaw, niżej darmowe zabawy „Na start”;
- **Więcej**: Piosenki, Na dobranoc, Pobrane.

Stuknięcie włącza zabawę i pokazuje ekran „Teraz odtwarzane” z okładką, przyciskami i przyciskiem **zapętlenia** (ten sam co w aplikacji). Aktualnie grana zabawa ma znacznik na liście. Listy odświeżają się same, gdy zmieni się dostęp (zakup), pobrane, aktywne dziecko albo grana zabawa.

Kod natywny jest w `app/ios/Runner/SceneDelegate.swift` (CarPlaySceneDelegate), dane w `app/lib/features/player/car_library.dart` (`carPlayTabs`, testy w `app/test/car_library_test.dart`). Swift nie był kompilowany w chmurze: przy pierwszym buildzie na Macu sprawdzić, czy Xcode nie zgłasza błędów w tym pliku.

Gry na głos (z mikrofonem) są w aucie ukryte celowo, bo potrzebują telefonu.

## Co musisz zrobić (konto Apple Developer)

1. Wejdź na developer.apple.com/contact/carplay i wypełnij wniosek **CarPlay App Entitlement**:
   - typ aplikacji: **Audio**;
   - opis: „Audio stories and listening games for children, played in the car (no video, no text input)”.
2. Apple odpowiada zwykle w ciągu kilku dni do kilku tygodni.
3. Po akceptacji: developer.apple.com → Certificates, IDs & Profiles → Identifiers → `pl.audiokiddo.app` → zaznacz **CarPlay Audio** → Save.
4. Napisz mi „CarPlay przyznany”. Dopiszę uprawnienie `com.apple.developer.carplay-audio` do aplikacji. Wcześniej nie wolno go dodać, bo Xcode nie podpisze aplikacji.

## Sprawdzenie bez auta

Xcode → Open Developer Tool → Simulator. Uruchom aplikację, potem I/O → External Displays → CarPlay. Działa dopiero z przyznanym uprawnieniem.

## Ograniczenie

Gdy aplikacja jest całkiem zamknięta, a telefon połączy się z autem, CarPlay pokaże „Otwórz AudioKiddo na telefonie”. Wystarczy raz otworzyć aplikację i lista się wczyta (stuknięcie w komunikat odświeża). W kolejnej wersji mogę to usunąć, uruchamiając silnik aplikacji w tle.
