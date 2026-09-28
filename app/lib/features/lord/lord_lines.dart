/// Lord Von Ekran's lines. One dog, two audiences (docs/golden, "Sprawy Domowe" strategy):
/// - to the child he is warm and curious (spoken, [kidHello]);
/// - to the parent he is an officer of the Home Affairs Office: deadpan, bureaucratic, facts
///   and times, no exclamation marks, no emoji. He mocks objects and situations, never the
///   child or how the parent copes.
///
/// Parent lines are text on screen only; they never talk over an audio activity. The widget
/// gets the lighter, relatable pool ([widget]).
enum LordPool {
  launchMorning,
  launchMidday,
  launchAfternoon,
  launchEvening,
  gameListening,
  gameWaiting,
  gameFinished,
  trip,
  bedtime,
  kidsHome,
  hello,
  widgetMorning,
  widgetMidday,
  widgetAfternoon,
  widgetEvening,
}

const lordLines = <LordPool, List<String>>{
  // Start screen, once per app launch, by part of the day.
  LordPool.launchMorning: [
    'Godzina 07:12. Zgłoszenie: brak drugiego buta.',
    'Kawa zaparzona 06:40. Status: zimna.',
    'Negocjacje w sprawie skarpetek trwają. Bez postępów.',
    'Wyjście z domu, podejście trzecie. Przyjęto do akt.',
    'Śniadanie zjedzone w 40 procentach. Uznano za sukces.',
  ],
  LordPool.launchMidday: [
    'Cisza od 14:07. Wszczęto postępowanie.',
    'Klocek nadal na wolności. Trzeci dzień.',
    'Pan Karton współpracuje. Reszta domu nie.',
    'Obiad przyjęty warunkowo. Marchewka odrzucona.',
    'Pisak zatrzymany przy ścianie. Ściana nie wnosi skarg.',
  ],
  LordPool.launchAfternoon: [
    'Droga z przedszkola. Dziewiętnaście pytań „dlaczego”.',
    '17:40. Plac zabaw odmawia wydania dziecka.',
    'Korek. Spacer byłby szybszy. Sprawdzone.',
    'Tylna kanapa auta: okruchy. Pochodzenie nieustalone.',
    'Kurtka założona. Czapka zaginęła w akcji.',
  ],
  LordPool.launchEvening: [
    '20:00. Rozpoczęto negocjacje w sprawie piżamy.',
    'Kąpiel zakończona. Łazienka w trakcie oględzin.',
    'Jeszcze jedna bajka. Wniosek rozpatrywany.',
    'Szklanka wody numer trzy. Przyjęto do akt.',
    'Dzień zamknięty. Protokół podpisany kredką.',
  ],
  // While Lord is gentle with the child, a line for the parent on the screen.
  LordPool.gameListening: [
    'Przesłuchanie trwa. Świadek odpowiada klaśnięciem.',
    'Proszę nie podpowiadać. Taki mamy protokół.',
    'Dziecko myśli. Ty możesz usiąść.',
    'Ekran leży. Świadek zajęty. Kawa jeszcze ciepła.',
  ],
  LordPool.gameWaiting: [
    'Czas na odpowiedź. Rodzic milczy jak kamień.',
    'Pauza w przesłuchaniu. Nikt nie wychodzi z pokoju.',
    'Świadek się zastanawia. Sąd czeka cierpliwie.',
  ],
  LordPool.gameFinished: [
    'Sprawa zamknięta. Nikt nie patrzył w ekran.',
    'Wynik: remis z kanapą. Gratulacje nieformalne.',
    'Zabawa zakończona. Akta trafiają do szuflady.',
  ],
  LordPool.trip: [
    'Kierowca skupiony. Tylne siedzenie zajęte zagadką.',
    '„Daleko jeszcze” odroczone o kwadrans.',
    'Trasa: 40 minut. Pytań: nieograniczona liczba.',
    'Postój na stacji nie jest planowany. Na razie.',
  ],
  LordPool.bedtime: [
    'Tryb wieczorny. Lord mówi szeptem. Ty też.',
    'Kołysanka w toku. Zakaz wchodzenia do pokoju.',
    'Po dobranoc kanapa jest twoja. Do odwołania.',
    'Negocjacje zakończone. Strony zmęczone, ale zadowolone.',
  ],
  LordPool.kidsHome: [
    'Tryb dziecka. Zakupy zablokowane. Portfel dziękuje.',
    'Dziecko wybiera samo. Ty wybierasz kawę.',
    'Strefa dziecka. Rodzic przebywa tu gościnnie.',
  ],
  // The "meet me" sheet on Start: a little longer, still dry.
  LordPool.hello: [
    'Lord Von Ekran. „Von” brzmi drogo. Reszta reaguje na szynkę.',
    'Prowadzę akta tego domu. Klocek ma już teczkę grubszą niż ja.',
    'Wybierz zabawę. Nie róbmy z wieczoru sprawy pod tytułem „co obejrzymy”.',
    'Ty ogarnij kawę. Ja ogarnę zagadki. Ekspres ma do mnie zakaz zbliżania.',
    'Mam plan. Poprzedni też był dobry, tylko kanapa się nie zgodziła.',
  ],
  // Home-screen widget: lighter lines a parent can recognise themselves in.
  LordPool.widgetMorning: [
    'Ty ogarnij kawę. Ja ogarnę zagadki.',
    'Drugi but się znajdzie. Zwykle pod kanapą.',
    'Pięć minut spokoju? Pakiet luksusowy.',
    'Zimna kawa to też kawa. Sprawdziłem.',
  ],
  LordPool.widgetMidday: [
    'Cisza w domu? Sprawdź, co robi pisak.',
    'Klocek wciąż na wolności. Uważaj na stopy.',
    'Obiad zjedzony w połowie. To też wynik.',
    'Ja mam zagadkę. Ty masz chwilę dla siebie.',
  ],
  LordPool.widgetAfternoon: [
    'Zanim padnie „daleko jeszcze?”, włącz zagadkę.',
    'Korek to też przygoda. Podobno.',
    'Plac zabaw nie odda dziecka bez negocjacji.',
    'Tylna kanapa pełna okruchów. Nie pytaj.',
  ],
  LordPool.widgetEvening: [
    'Kołysanka dla dziecka, cisza dla ciebie.',
    'Negocjacje o piżamę? Mam argumenty.',
    'Jeszcze jedna szklanka wody. Wiemy.',
    'Po dobranoc kanapa jest twoja.',
  ],
};

/// Line [index] of [pool], wrapping around.
String lordLine(LordPool pool, int index) {
  final lines = lordLines[pool]!;
  return lines[index % lines.length];
}
