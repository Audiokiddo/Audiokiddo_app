// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'AudioKiddo';

  @override
  String get navHome => 'Start';

  @override
  String get navLibrary => 'Biblioteka';

  @override
  String get homeGreeting => 'Czas na zabawę!';

  @override
  String get homeSubtitle => 'Słuchajcie, odpowiadajcie, wymyślajcie. Bez patrzenia w ekran.';

  @override
  String get homeFeatured => 'Zabawa dnia';

  @override
  String get homeStartHere => 'Zacznij tu';

  @override
  String get homeWhatAreYouDoing => 'Co robicie?';

  @override
  String get homePacks => 'Pakiety';

  @override
  String ageFrom(int age) {
    return '$age+';
  }

  @override
  String ageGroupLabel(int age) {
    return 'Dla dzieci od $age lat';
  }

  @override
  String get situationPodroz => 'W podróży';

  @override
  String get situationPrzedSnem => 'Przed snem';

  @override
  String get situationWDomu => 'W domu';

  @override
  String get situationCzekanie => 'Czekamy';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String players(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: '$min osoby',
      many: '$min osób',
      few: '$min osoby',
      one: '1 osoba',
    );
    return '$_temp0';
  }

  @override
  String playersRange(int min, int max) {
    return '$min–$max osób';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zabawy',
      many: '$count zabaw',
      few: '$count zabawy',
      one: '1 zabawa',
    );
    return '$_temp0';
  }

  @override
  String get kindAll => 'Wszystko';

  @override
  String get kindAudioGame => 'Audiozabawy';

  @override
  String get kindSong => 'Piosenki';

  @override
  String get kindInteractiveGame => 'Gry bez ekranu';

  @override
  String get filterAge => 'Wiek';

  @override
  String get filterPack => 'Pakiet';

  @override
  String get filterSituation => 'Sytuacja';

  @override
  String get filterClear => 'Wyczyść filtry';

  @override
  String get libraryEmpty => 'Nic tu nie pasuje do wybranych filtrów.';

  @override
  String get free => 'Za darmo';

  @override
  String get locked => 'Wymaga odblokowania';

  @override
  String get detailsForParent => 'Dla rodzica';

  @override
  String get detailsPractises => 'Co ćwiczy';

  @override
  String get detailsYouNeed => 'Przyda się';

  @override
  String get requirementMikrofon => 'Mikrofon (opcjonalnie)';

  @override
  String get requirementMiejsceDoRuchu => 'Miejsce do ruchu';

  @override
  String get requirementKartkaIOlowek => 'Kartka i ołówek';

  @override
  String get requirementWydrukPdf => 'Wydrukowane akta sprawy (PDF)';

  @override
  String get listen => 'Słuchaj';

  @override
  String get unlock => 'Odblokuj';

  @override
  String get play => 'Odtwórz';

  @override
  String get pause => 'Pauza';

  @override
  String get rewind => 'Cofnij 15 sekund';

  @override
  String get forward => 'Przewiń 15 sekund';

  @override
  String get loadError => 'Nie udało się wczytać katalogu.';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get notFound => 'Nie znaleziono tej zabawy.';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pozycji',
      many: '$count pozycji',
      few: '$count pozycje',
      one: '1 pozycja',
    );
    return '$_temp0';
  }

  @override
  String get navMine => 'Moje';

  @override
  String get mineRecent => 'Ostatnio słuchane';

  @override
  String get mineFavorites => 'Ulubione';

  @override
  String get mineDownloads => 'Pobrane';

  @override
  String get mineEmptyRecent =>
      'Tu pojawią się zabawy, których słuchaliście. Na razie cisza. Podejrzana cisza.';

  @override
  String get mineEmptyFavorites =>
      'Dotknij serca przy zabawie, a trafi tutaj. Na razie pusto jak w lodówce w niedzielę wieczorem.';

  @override
  String get mineEmptyDownloads =>
      'Pobierz zabawy przed podróżą. Bez nich po 10 minutach jazdy padnie pytanie: „daleko jeszcze?”.';

  @override
  String storageUsage(String used, String free) {
    return 'Pobrane: $used · Wolne w telefonie: $free';
  }

  @override
  String storageUsed(String used) {
    return 'Pobrane: $used';
  }

  @override
  String get deleteAllDownloads => 'Usuń wszystkie pobrane';

  @override
  String get deleteAllConfirmTitle => 'Usunąć wszystkie pobrane zabawy?';

  @override
  String get deleteAllConfirmBody => 'Pliki znikną z telefonu. W każdej chwili możesz pobrać je ponownie.';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String download(String size) {
    return 'Pobierz ($size)';
  }

  @override
  String downloading(int percent) {
    return 'Pobieranie… $percent%';
  }

  @override
  String get downloadQueued => 'Czeka na pobranie…';

  @override
  String get verifying => 'Sprawdzanie pliku…';

  @override
  String get downloaded => 'Pobrano. Działa bez internetu.';

  @override
  String get removeDownload => 'Usuń z telefonu';

  @override
  String get cancelDownload => 'Anuluj pobieranie';

  @override
  String get downloadFailed => 'Nie udało się pobrać. Sprawdź internet i spróbuj ponownie.';

  @override
  String get retryDownload => 'Pobierz ponownie';

  @override
  String notEnoughSpace(String needed, String free) {
    return 'Za mało miejsca w telefonie: potrzeba $needed, wolne $free.';
  }

  @override
  String get favoriteAdd => 'Dodaj do ulubionych';

  @override
  String get favoriteRemove => 'Usuń z ulubionych';

  @override
  String resumeFrom(String time) {
    return 'Wznów od $time';
  }

  @override
  String get startOver => 'Od początku';

  @override
  String get playbackUnavailable =>
      'Nie można teraz odtworzyć. Sprawdź internet albo pobierz zabawę wcześniej.';

  @override
  String get needsRefresh => 'Dostęp do płatnych zabaw trzeba odświeżyć. Połącz się z internetem.';

  @override
  String get sleepTimer => 'Timer snu';

  @override
  String get sleepOff => 'Wyłącz timer';

  @override
  String get sleepEndOfItem => 'Do końca zabawy';

  @override
  String sleepRemaining(String time) {
    return 'Wyłączy się za $time';
  }

  @override
  String get sleepAtEnd => 'Wyłączy się po tej zabawie';

  @override
  String get speed => 'Prędkość';

  @override
  String get speedLocked => 'W tej zabawie tempo jest stałe.';

  @override
  String get noLookMode => 'Tryb bez patrzenia';

  @override
  String get noLookHint => 'Połóż telefon i słuchajcie. Aby wyjść, przytrzymaj przycisk na dole.';

  @override
  String get noLookExit => 'Przytrzymaj, aby wyjść';

  @override
  String get nowPlaying => 'Teraz odtwarzane';

  @override
  String get devTools => 'Narzędzia deweloperskie';

  @override
  String get devToolsHint =>
      'Widoczne tylko w wersji roboczej. Symulują zakupy do czasu podłączenia sklepów w Etapie 3.';

  @override
  String get devAccessMode => 'Symulowany dostęp';

  @override
  String get devRefresh => 'Odśwież dostęp (jak po połączeniu z internetem)';

  @override
  String get devExpireLease => 'Symuluj ponad 30 dni bez internetu';

  @override
  String devLeaseUntil(String date) {
    return 'Dostęp offline ważny do: $date';
  }

  @override
  String get devLeaseNone => 'Brak dzierżawy offline';

  @override
  String get gateTitle => 'Poproś rodzica';

  @override
  String get gateForChild => 'Ta część aplikacji jest dla dorosłych.';

  @override
  String get gateForParent => 'Dla rodzica: dotknij liczby';

  @override
  String get gateWrong => 'To nie ta liczba. Spróbuj jeszcze raz.';

  @override
  String gateLocked(int seconds) {
    return 'Zbyt wiele prób. Spróbuj ponownie za $seconds s.';
  }

  @override
  String get kidsTitle => 'Moje zabawy';

  @override
  String get kidsParentButton => 'Dla rodzica';

  @override
  String get kidsEmpty => 'Poproś rodzica, żeby przygotował zabawy.';

  @override
  String get kidsCannotPlay => 'Tej zabawy nie da się teraz włączyć. Poproś rodzica.';

  @override
  String get kidsEnterTitle => 'Tryb dziecka';

  @override
  String get kidsEnterSubtitle => 'Duże okładki, bez zakupów i ustawień';

  @override
  String get kidsSetupHint =>
      'Dziecko zobaczy tylko zabawy dostępne dla jego wieku, bez zakupów, linków i ustawień. Wyjście z trybu wymaga rodzica.';

  @override
  String get kidsSetupAge => 'Wiek dziecka';

  @override
  String get kidsSetupOnlyDownloaded => 'Tylko pobrane';

  @override
  String get kidsSetupOnlyDownloadedHint => 'Na podróż: pokaż wyłącznie zabawy działające bez internetu.';

  @override
  String get kidsStart => 'Włącz tryb dziecka';

  @override
  String get pdfSection => 'Do wydrukowania';

  @override
  String get pdfOpen => 'Otwórz do druku';

  @override
  String get pdfTitle => 'Karta do druku';

  @override
  String get pdfLoadError => 'Nie udało się otworzyć pliku. Sprawdź internet albo pobierz zabawę.';

  @override
  String get paywallTitle => 'Odblokuj zabawy';

  @override
  String paywallFor(String title) {
    return 'Chcesz słuchać: $title';
  }

  @override
  String get paywallSubscriptionHeader => 'Subskrypcja';

  @override
  String get paywallSubscriptionBody =>
      'Wszystkie audiozabawy, piosenki i nowości, na każdym urządzeniu z tym samym kontem sklepu.';

  @override
  String get paywallYearly => 'Rocznie (najkorzystniej)';

  @override
  String get paywallMonthly => 'Miesięcznie';

  @override
  String paywallTrialThen(int days, String price, String period) {
    return '$days dni za darmo, potem $price / $period';
  }

  @override
  String get periodMonth => 'miesiąc';

  @override
  String get periodYear => 'rok';

  @override
  String get paywallOneTimeHeader => 'Na zawsze, bez subskrypcji';

  @override
  String get paywallOneTimeBody => 'Kupujesz raz i zostaje z Wami.';

  @override
  String get paywallBundleTwo => 'Wyobraźnia + Słowa i Wiedza';

  @override
  String get paywallBundleThree => 'Wszystkie trzy pakiety';

  @override
  String get paywallSingle => 'Tylko ta zabawa';

  @override
  String paywallSingleHint(String price) {
    return 'Cały pakiet kosztuje $price';
  }

  @override
  String get paywallRestore => 'Przywróć zakupy';

  @override
  String paywallLegalRenewal(String store) {
    return 'Subskrypcja odnawia się automatycznie po tej samej cenie, chyba że wyłączysz ją co najmniej 24 godziny przed końcem okresu. Płatność pobiera $store.';
  }

  @override
  String get paywallLegalTrial =>
      'Po okresie próbnym, jeśli go nie anulujesz, zaczyna się płatna subskrypcja.';

  @override
  String paywallLegalManage(String store) {
    return 'Subskrypcją zarządzasz i anulujesz ją w ustawieniach konta $store.';
  }

  @override
  String get paywallTerms => 'Regulamin';

  @override
  String get paywallPrivacy => 'Polityka prywatności';

  @override
  String get paywallUnavailable => 'Sklep jest teraz niedostępny. Sprawdź internet i spróbuj później.';

  @override
  String get purchaseSuccess => 'Gotowe! Zabawy są odblokowane.';

  @override
  String get purchasePending => 'Zakup czeka na zatwierdzenie (np. przez opiekuna konta rodzinnego).';

  @override
  String get purchaseStoreError => 'Sklep zgłosił błąd. Spróbuj ponownie.';

  @override
  String get purchaseVerifyLater =>
      'Nie udało się jeszcze potwierdzić zakupu. Spróbujemy ponownie automatycznie, nie płać drugi raz.';

  @override
  String get purchaseNothingToRestore => 'Nie znaleźliśmy zakupów do przywrócenia na tym koncie sklepu.';

  @override
  String get devStoreOutcome => 'Wynik następnego zakupu w symulowanym sklepie';

  @override
  String get devClearPurchases => 'Wyczyść symulowane zakupy';

  @override
  String get playGame => 'Zagraj';

  @override
  String get gameListen => 'Słuchaj';

  @override
  String get gameYourTurn => 'Twoja kolej';

  @override
  String get gameTapNow => 'Dotknij ekranu!';

  @override
  String get gameFinished => 'Koniec zabawy';

  @override
  String get gameFailed => 'Nie udało się uruchomić zabawy.';

  @override
  String get onboardingHelloTitle => 'Cześć! Tu AudioKiddo.';

  @override
  String get onboardingHelloBody =>
      'Zanim zaczniemy: podgłośnij telefon do wygodnego poziomu. Tak, żeby było dobrze słychać, ale bez ogłuszania. Uszy są nam jeszcze potrzebne!';

  @override
  String get onboardingHowTitle => 'Jak to działa';

  @override
  String get onboardingHowListen =>
      'Włączasz zabawę i odkładasz telefon. Dziecko słucha, odpowiada i wykonuje zadania.';

  @override
  String get onboardingHowKids =>
      'Tylko duże okładki: bez zakupów, linków i ustawień. Wyjście z niego wymaga rodzica.';

  @override
  String get onboardingHowOffline => 'Pobrane zabawy działają bez internetu, na przykład w samochodzie.';

  @override
  String get onboardingHowNoAds => 'Żadnych reklam ani śledzenia. Nie zbieramy danych o dziecku.';

  @override
  String get onboardingAgeTitle => 'Ile lat ma dziecko?';

  @override
  String get onboardingAgeBody =>
      'Opcjonalnie. Podpowiemy zabawy dla tego wieku. Odpowiedź zostaje tylko w tym telefonie.';

  @override
  String get onboardingNext => 'Dalej';

  @override
  String get onboardingStart => 'Zaczynamy';

  @override
  String get onboardingSkip => 'Pomiń';

  @override
  String onboardingStep(int current, int total) {
    return 'Krok $current z $total';
  }

  @override
  String get resumeGame => 'Wznów grę';

  @override
  String get accountTitle => 'Konto rodzica';

  @override
  String get accountIntro =>
      'Konto nie jest potrzebne do słuchania. Przyda się, jeśli masz już pakiety przypisane do swojego adresu e-mail albo chcesz zachować dostęp po zmianie telefonu.';

  @override
  String get accountEmailLabel => 'Adres e-mail';

  @override
  String get accountSendCode => 'Wyślij kod';

  @override
  String accountCodeSent(String email) {
    return 'Wysłaliśmy kod na adres $email. Wpisz go poniżej. Jeśli go nie widzisz, zajrzyj do spamu.';
  }

  @override
  String get accountCodeLabel => 'Kod z e-maila';

  @override
  String get accountVerify => 'Zaloguj się';

  @override
  String get accountResend => 'Wyślij kod ponownie';

  @override
  String accountResendIn(int seconds) {
    return 'Nowy kod za $seconds s';
  }

  @override
  String get accountChangeEmail => 'Zmień adres e-mail';

  @override
  String get accountSignedInAs => 'Zalogowano jako';

  @override
  String get accountAccess => 'Dostęp na tym koncie';

  @override
  String get accountNoAccess => 'Na tym koncie nie ma jeszcze zakupów.';

  @override
  String get accountAllContent => 'Wszystkie zabawy (subskrypcja)';

  @override
  String accountPack(String title) {
    return 'Pakiet $title';
  }

  @override
  String accountValidUntil(String date) {
    return 'Ważne do $date';
  }

  @override
  String get accountRefresh => 'Sprawdź zakupy ponownie';

  @override
  String get accountRefreshed => 'Zakupy sprawdzone.';

  @override
  String get accountSignOut => 'Wyloguj się';

  @override
  String get accountSignOutBody =>
      'Pakiety z tego konta będą zablokowane do ponownego zalogowania. Pobrane pliki zostaną w telefonie.';

  @override
  String get accountDelete => 'Usuń konto';

  @override
  String get accountDeleteTitle => 'Usunąć konto?';

  @override
  String get accountDeleteBody =>
      'Usuniemy Twój adres e-mail i informacje o dostępie z naszego serwera. Tego nie da się cofnąć. Usunięcie konta nie anuluje subskrypcji: zrobisz to w ustawieniach App Store albo Google Play.';

  @override
  String get accountDeleted => 'Konto zostało usunięte.';

  @override
  String get accountErrorInvalidEmail => 'Sprawdź adres e-mail.';

  @override
  String get accountErrorTooMany => 'Za dużo prób. Odczekaj chwilę i spróbuj ponownie.';

  @override
  String get accountErrorWrongCode => 'Kod jest nieprawidłowy albo wygasł. Wyślij nowy.';

  @override
  String get accountErrorOffline => 'Brak połączenia z internetem.';

  @override
  String get accountErrorServer => 'Coś poszło nie tak po naszej stronie. Spróbuj za chwilę.';

  @override
  String get paywallHaveAccess => 'Masz już dostęp? Zaloguj się';

  @override
  String get gameAnswerNow => 'Twoja odpowiedź!';

  @override
  String get micTitle => 'Odpowiedzi głosem i klaśnięciem';

  @override
  String get micOffBody =>
      'Dziecko może odpowiadać klaśnięciem albo głosem, bez dotykania telefonu. Mikrofon działa tylko w czasie zabawy, a dźwięk jest analizowany w telefonie: nic nie jest nagrywane ani wysyłane.';

  @override
  String get micOnBody =>
      'Włączone. Zabawy słuchają klaśnięć i głosu dziecka tylko wtedy, gdy czekają na odpowiedź. Nic nie jest nagrywane ani wysyłane.';

  @override
  String get micEnable => 'Włącz mikrofon';

  @override
  String get micDisable => 'Wyłącz';

  @override
  String get micDenied =>
      'Telefon nie pozwolił na mikrofon. Możesz to zmienić w Ustawieniach telefonu → AudioKiddo. Do tego czasu zabawy działają bez mikrofonu.';

  @override
  String get micWithout =>
      'Bez mikrofonu zabawa podpowiada, kiedy odpowiedzieć, i czeka chwilę na odpowiedź.';

  @override
  String get signInApple => 'Kontynuuj z Apple';

  @override
  String get signInGoogle => 'Kontynuuj z Google';

  @override
  String get signInEmail => 'Kontynuuj z e-mailem';

  @override
  String get signInNotConfigured =>
      'To logowanie będzie dostępne wkrótce. Na razie zaloguj się adresem e-mail.';

  @override
  String get signInFooter => 'Konto jest dla rodzica. Nie zbieramy danych o dziecku ani reklamowych.';

  @override
  String get signInEmailTitle => 'Logowanie e-mailem';

  @override
  String get signInEmailBody => 'Bez hasła: wyślemy Ci jednorazowy kod.';

  @override
  String get accountSignedOutTitle => 'Zaloguj się';

  @override
  String get accountSectionAccount => 'Konto';

  @override
  String get accountAccessFooter =>
      'Pakiety przypisane do tego konta działają na każdym telefonie, na którym się zalogujesz.';

  @override
  String get accountDeleteFooter =>
      'Usuwa adres e-mail i informacje o dostępie z naszego serwera. Subskrypcję anulujesz w ustawieniach App Store albo Google Play.';

  @override
  String get onboardingHelloSubtitle => 'Audiozabawy pełne przygód';

  @override
  String get onboardingVolumeTitle => 'Najpierw głośność';

  @override
  String get onboardingHowListenTitle => 'Słuchanie bez ekranu';

  @override
  String get onboardingHowKidsTitle => 'Tryb dziecka';

  @override
  String get onboardingHowOfflineTitle => 'Działa bez internetu';

  @override
  String get onboardingHowNoAdsTitle => 'Bez reklam';

  @override
  String get onboardingAccountTitle => 'Konto rodzica';

  @override
  String get onboardingAccountBody =>
      'Opcjonalnie. Zaloguj się, jeśli masz już pakiety przypisane do adresu e-mail albo chcesz zachować dostęp po zmianie telefonu.';

  @override
  String get onboardingAccountDone => 'Zalogowano';

  @override
  String get onboardingStartWithoutAccount => 'Zacznij bez konta';

  @override
  String get introSkip => 'Pomiń';

  @override
  String get introVolumeTitle => 'Podgłośnij!';

  @override
  String get introVolumeBody => 'Żeby dobrze słyszeć Kiddo.';

  @override
  String get introPasswordTitle => 'MAGICZNE HASŁO';

  @override
  String get introPasswordSay => 'Powiedz głośno:';

  @override
  String get introPasswordWord => 'ABRAKADABRA!';

  @override
  String get introPasswordListening => '(słucham…)';

  @override
  String get introPasswordTap => '…i dotknij magicznej kuli';

  @override
  String get introPasswordOrb => 'Magiczna kula. Dotknij, aby wejść.';

  @override
  String get introGranted => 'Dostęp przyznany!';

  @override
  String get homeKiddo => 'Kiddo. Dotknij, a coś powie.';

  @override
  String get homeNew => 'Nowość!';

  @override
  String get homeNewHint => 'Odpowiadaj klaśnięciem albo głosem!';

  @override
  String get kidsHello1 => 'Hej! W co dziś zagramy?';

  @override
  String get kidsHello2 => 'Witaj z powrotem! Wybierz przygodę!';

  @override
  String get kidsHello3 => 'Gotowi na zabawę? Ja jestem gotowy!';

  @override
  String get quizBack => 'Wstecz';

  @override
  String get quizYourChild => 'Twoje dziecko';

  @override
  String get quizHello =>
      'Cześć! Zadam kilka szybkich pytań, żeby dobrać zabawy. Minutka, obiecuję. Kiddo nie kłamie.';

  @override
  String get quizHelloPoint1 => 'Około minuty na każde dziecko.';

  @override
  String get quizHelloPoint2 => 'Odpowiedzi zostają tylko w tym telefonie.';

  @override
  String get quizHelloPoint3 => 'Masz więcej dzieci? Każde dostanie własny plan.';

  @override
  String get quizName => 'Jak ma na imię Twoje dziecko?';

  @override
  String get quizNameHint => 'Imię albo przezwisko (opcjonalnie)';

  @override
  String get quizNamePrivacy => 'Zapisujemy je tylko w tym telefonie, żeby było wiadomo, czyj to plan.';

  @override
  String quizAge(String name) {
    return 'Ile lat ma $name?';
  }

  @override
  String get quizGoals => 'Co chcecie rozwijać? Możesz wybrać kilka.';

  @override
  String get quizSituations => 'Kiedy najczęściej słuchacie? (opcjonalnie)';

  @override
  String get quizMinutes => 'Ile czasu dziennie na zabawę?';

  @override
  String quizMinutesOption(int minutes) {
    return '$minutes min dziennie';
  }

  @override
  String get quizMinutes5 => 'Na rozgrzewkę. Tyle, ile stygnie kawa.';

  @override
  String get quizMinutes10 => 'W sam raz. Jeden cykl wirowania pralki.';

  @override
  String get quizMinutes15 => 'Ambitnie. Pół odcinka serialu, którego i tak nie obejrzysz.';

  @override
  String get quizMinutes20 => 'Z rozmachem. Prawie cały obiad bez „mamo, tato, a wiesz co?”.';

  @override
  String quizSummary(String name, int minutes) {
    return 'Gotowe! Plan dla: $name. Po $minutes min dziennie, zaczynamy od łatwych zabaw.';
  }

  @override
  String quizSummaryAge(int age) {
    return 'Zabawy dobrane do wieku: $age lat.';
  }

  @override
  String get quizSummaryLevels =>
      'Codziennie jedna porcja. Nowe rzeczy pojawiają się stopniowo, poziom po poziomie.';

  @override
  String get quizSummaryChange => 'Plan zmienisz w każdej chwili w zakładce Plan.';

  @override
  String get quizAnotherChild => 'Dodaj kolejne dziecko';

  @override
  String get quizStart => 'Zaczynamy';

  @override
  String get quizContinue => 'Dalej';

  @override
  String get quizFinish => 'Gotowe';

  @override
  String get quizSave => 'Zapisz';

  @override
  String get quizProgress => 'Postęp pytań';

  @override
  String get goalImagination => 'Wyobraźnia i opowiadanie';

  @override
  String get goalLanguage => 'Słownictwo i mowa';

  @override
  String get goalLogic => 'Logiczne myślenie';

  @override
  String get goalListening => 'Uważne słuchanie i skupienie';

  @override
  String get goalMovement => 'Ruch i rytm';

  @override
  String get goalCalm => 'Wyciszenie przed snem';

  @override
  String get reminder1Title => 'Kiddo czeka';

  @override
  String get reminder1Body =>
      'Dzień był długi? 10 minut zabawy i przez chwilę to ktoś inny odpowiada na pytania.';

  @override
  String get reminder2Title => 'Pora na przygodę';

  @override
  String get reminder2Body =>
      'Kawa znowu wystygła? Kawy nie uratujemy. Ciszę może tak: dzisiejsza zabawa czeka.';

  @override
  String get reminder3Title => 'Seria trwa!';

  @override
  String get reminder3Body =>
      'Jeszcze jeden dzień, a seria będzie dłuższa niż Twój ostatni nieprzerwany sen.';

  @override
  String get reminder4Title => 'Kiddo tu';

  @override
  String get reminder4Body => 'Dziecko zadało dziś już 347 pytań? Oddaj kilka Kiddo. On to lubi. Serio.';

  @override
  String get reminder5Title => 'Cisza w domu?';

  @override
  String get reminder5Body => 'Podejrzane. Sprawdź, co się dzieje, a potem włącz dzisiejszą zabawę.';

  @override
  String get reminder6Title => 'Bez ekranu, bez wyrzutów';

  @override
  String get reminder6Body => 'Oczy odpoczywają, uszy pracują, a Ty może nawet usiądziesz. Na chwilę.';

  @override
  String get reminder7Title => 'Kiddo nie śpi';

  @override
  String get reminder7Body =>
      'Kiddo nie śpi. Kiddo czeka. Kiddo trochę tęskni. Dzisiejsza porcja to kilka minut.';

  @override
  String get remindersAsk =>
      'Mogę przypominać o codziennej zabawie? Obiecuję nie przesadzać. Raz dziennie, z humorem.';

  @override
  String get remindersWhen => 'O której przypomnieć?';

  @override
  String get remindersMorning => 'Rano';

  @override
  String get remindersAfternoon => 'Po przedszkolu';

  @override
  String get remindersEvening => 'Wieczorem';

  @override
  String get remindersBedtime => 'Przed snem';

  @override
  String get remindersEnable => 'Włącz przypomnienia';

  @override
  String get remindersLater => 'Nie teraz';

  @override
  String get remindersDenied =>
      'Telefon nie pozwolił na powiadomienia. Możesz to zmienić w Ustawieniach telefonu.';

  @override
  String get remindersNote => 'Zmienisz to w każdej chwili w zakładce Plan.';

  @override
  String get remindersPreviewApp => 'AudioKiddo';

  @override
  String get remindersPreviewTime => 'teraz';

  @override
  String get navPlan => 'Plan';

  @override
  String childNumber(int n) {
    return 'Dziecko $n';
  }

  @override
  String get planEmptyTitle => 'Tu będzie plan zabaw na każdy dzień';

  @override
  String get planEmptyBody =>
      'Odpowiedz na kilka pytań (minuta), a Kiddo rozłoży zabawy na dni: po trochu, bez przytłaczania.';

  @override
  String get planEmptyButton => 'Dopasuj plan';

  @override
  String get planAddChild => 'Dodaj dziecko';

  @override
  String planAge(int age) {
    return '$age l.';
  }

  @override
  String get planStreak => 'dni z rzędu';

  @override
  String get planDays => 'dni planu';

  @override
  String get planAccuracy => 'dobrych odpowiedzi';

  @override
  String get planTodayDone =>
      'Dzisiejsza porcja zaliczona! Kolejna otworzy się jutro. Odpocznijcie, zasłużyliście.';

  @override
  String get planOpensTomorrow => 'Ten dzień otworzy się jutro. Po trochu, codziennie: tak działa najlepiej.';

  @override
  String planLockedDay(int day) {
    return 'Najpierw skończcie dzień $day.';
  }

  @override
  String planLevel(int level, int first, int last) {
    return 'Poziom $level · dni $first–$last';
  }

  @override
  String planNodeDone(int day) {
    return 'Dzień $day, zaliczony. Otwórz, aby powtórzyć.';
  }

  @override
  String planNodeToday(int day) {
    return 'Dzień $day, dzisiaj. Otwórz zabawy.';
  }

  @override
  String planNodeLocked(int day) {
    return 'Dzień $day, zablokowany.';
  }

  @override
  String planDayTitle(int day) {
    return 'Dzień $day';
  }

  @override
  String get planChest =>
      'Koniec tygodnia! Nagroda: pochwalcie się dziś przy kolacji, czego się nauczyliście. Kiddo pozdrawia.';

  @override
  String get level1Name => 'Poznajemy się';

  @override
  String get level1News => 'Krótkie zabawy i piosenki. Bez presji.';

  @override
  String get level2Name => 'Rozkręcamy się';

  @override
  String get level2News => 'Nowość: zabawy, w których dziecko odpowiada.';

  @override
  String get level3Name => 'Małe wyzwania';

  @override
  String get level3News => 'Nowość: dłuższe przygody i karty do druku.';

  @override
  String get level4Name => 'Mistrzowie słuchania';

  @override
  String get level4News => 'Wszystko odblokowane. Teraz Wy prowadzicie.';

  @override
  String get tipPhoneDown =>
      'Połóżcie telefon ekranem w dół i słuchajcie razem. Za pierwszym razem najlepiej z Tobą obok.';

  @override
  String get tipKidsMode => 'Włącz tryb dziecka na stronie Start: duże okładki i żadnych zakupów.';

  @override
  String get tipDownload =>
      'Pobierz zabawy na drogę: działają bez internetu, nawet w tunelu i u teściów na wsi.';

  @override
  String get tipFavorites => 'Serduszko przy zabawie i ulubione są zawsze pod ręką w zakładce Moje.';

  @override
  String get tipMicrophone =>
      'Nowość: dziecko może odpowiadać klaśnięciem albo głosem. Włączysz to w szczegółach zabawy.';

  @override
  String get tipSleepTimer => 'Wieczorem ustaw w odtwarzaczu timer snu. Zabawa sama ucichnie. Ty nie musisz.';

  @override
  String get tipPrintables => 'Niektóre zabawy mają karty do druku, np. dyplom albo akta detektywa.';

  @override
  String get tipAccount => 'Załóż konto rodzica, żeby zakupy działały też na innych telefonach.';

  @override
  String get progressTitle => 'Postęp';

  @override
  String progressOf(String name) {
    return 'Postęp: $name';
  }

  @override
  String get progressEmpty =>
      'Tu pojawi się postęp. Na razie jest tu cicho. Tak cicho, jak w domu, kiedy dzieci coś kombinują.';

  @override
  String get progressStreak => 'dni z rzędu';

  @override
  String get progressDays => 'dni z zabawą';

  @override
  String get progressMinutes => 'minut słuchania';

  @override
  String get progressCorrect => 'dobre odpowiedzi';

  @override
  String get progressSkills => 'Umiejętności';

  @override
  String get progressSkillsFooter =>
      'Ile razy dziecko ćwiczyło daną umiejętność. Procent pokazujemy tam, gdzie zabawa sprawdza odpowiedzi.';

  @override
  String progressTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count razy',
      many: '$count razy',
      few: '$count razy',
      one: '1 raz',
    );
    return '$_temp0';
  }

  @override
  String get progressAdvice => 'Podpowiedzi';

  @override
  String get progressSettings => 'Ustawienia planu';

  @override
  String get progressEditProfile => 'Wiek, cele i czas';

  @override
  String progressProfileSummary(int age, int minutes) {
    return '$age lat · $minutes min dziennie';
  }

  @override
  String get progressReminders => 'Przypomnienia';

  @override
  String progressRemindersAt(String time) {
    return 'Codziennie o $time. Dotknij, aby wyłączyć.';
  }

  @override
  String get progressRemindersOff => 'Wyłączone. Dotknij, aby włączyć.';

  @override
  String get progressRemoveChild => 'Usuń profil dziecka';

  @override
  String get progressRemoveBody => 'Usuniemy profil i postęp tego dziecka z telefonu. Zakupy zostają.';

  @override
  String adviceExcelling(String skill) {
    return '$skill: świetnie idzie! Czas na coś trudniejszego.';
  }

  @override
  String adviceExcellingPack(String skill, String pack) {
    return '$skill: świetnie idzie! Spróbujcie pakietu $pack.';
  }

  @override
  String adviceNeedsPractice(String skill) {
    return '$skill: warto poćwiczyć. Powtarzajcie ulubione zabawy.';
  }

  @override
  String adviceNeedsPracticePack(String skill, String pack) {
    return '$skill: warto poćwiczyć. Pomoże pakiet $pack.';
  }

  @override
  String adviceUntouched(String skill) {
    return '$skill: to Wasz cel, a jeszcze go nie ćwiczyliście.';
  }

  @override
  String adviceUntouchedPack(String skill, String pack) {
    return '$skill: to Wasz cel. Najwięcej takich zabaw ma pakiet $pack.';
  }

  @override
  String get adviceComeBack =>
      'Kilka dni przerwy? Zdarza się najlepszym. Wystarczy 5 minut dziś, żeby wrócić do rytmu.';

  @override
  String get adviceLevelUp => 'Regularność na medal! Można dodać kilka minut dziennie.';

  @override
  String get paywallCarTrial => 'Mamo, tato… daleko jeszcze? A może 7 dni za darmo, zanim dojedziemy?';

  @override
  String get paywallCar => 'Mamo, tato… daleko jeszcze? Z zabawami będzie bliżej!';
}
