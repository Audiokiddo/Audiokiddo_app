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
  String get mineEmptyRecent => 'Tu pojawią się zabawy, których słuchaliście.';

  @override
  String get mineEmptyFavorites => 'Dotknij serca przy zabawie, aby dodać ją do ulubionych.';

  @override
  String get mineEmptyDownloads => 'Pobierz zabawy przed podróżą, żeby działały bez internetu.';

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
  String get pdfSection => 'Akta sprawy do druku';

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
      'Włączasz zabawę i odkładasz telefon. Dziecko słucha, odpowiada na głos i wykonuje zadania. Nie trzeba patrzeć w ekran.';

  @override
  String get onboardingHowKids =>
      'Tryb dziecka pokazuje tylko duże okładki: bez zakupów, linków i ustawień. Wyjście z niego wymaga rodzica.';

  @override
  String get onboardingHowOffline => 'Pobrane zabawy działają bez internetu, na przykład w samochodzie.';

  @override
  String get onboardingHowNoAds => 'Bez reklam i bez śledzenia.';

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
}
