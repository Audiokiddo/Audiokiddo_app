# CarPlay

Kod jest gotowy. W aucie pojawi się lista jak w Android Auto: Na drogę, Pobrane, Piosenki, Na dobranoc. Stuknięcie włącza zabawę i pokazuje ekran „Teraz odtwarzane” z okładką i przyciskami.

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
