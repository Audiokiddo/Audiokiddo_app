import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pl')];

  /// No description provided for @appTitle.
  ///
  /// In pl, this message translates to:
  /// **'AudioKiddo'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In pl, this message translates to:
  /// **'Start'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In pl, this message translates to:
  /// **'Biblioteka'**
  String get navLibrary;

  /// No description provided for @homeGreeting.
  ///
  /// In pl, this message translates to:
  /// **'Czas na zabawę!'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Słuchajcie, odpowiadajcie, wymyślajcie. Bez patrzenia w ekran.'**
  String get homeSubtitle;

  /// No description provided for @homeFeatured.
  ///
  /// In pl, this message translates to:
  /// **'Zabawa dnia'**
  String get homeFeatured;

  /// No description provided for @homeStartHere.
  ///
  /// In pl, this message translates to:
  /// **'Zacznij tu'**
  String get homeStartHere;

  /// No description provided for @homeWhatAreYouDoing.
  ///
  /// In pl, this message translates to:
  /// **'Co robicie?'**
  String get homeWhatAreYouDoing;

  /// No description provided for @homePacks.
  ///
  /// In pl, this message translates to:
  /// **'Pakiety'**
  String get homePacks;

  /// No description provided for @ageFrom.
  ///
  /// In pl, this message translates to:
  /// **'{age}+'**
  String ageFrom(int age);

  /// No description provided for @ageGroupLabel.
  ///
  /// In pl, this message translates to:
  /// **'Dla dzieci od {age} lat'**
  String ageGroupLabel(int age);

  /// No description provided for @situationPodroz.
  ///
  /// In pl, this message translates to:
  /// **'W podróży'**
  String get situationPodroz;

  /// No description provided for @situationPrzedSnem.
  ///
  /// In pl, this message translates to:
  /// **'Przed snem'**
  String get situationPrzedSnem;

  /// No description provided for @situationWDomu.
  ///
  /// In pl, this message translates to:
  /// **'W domu'**
  String get situationWDomu;

  /// No description provided for @situationCzekanie.
  ///
  /// In pl, this message translates to:
  /// **'Czekamy'**
  String get situationCzekanie;

  /// No description provided for @minutes.
  ///
  /// In pl, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @players.
  ///
  /// In pl, this message translates to:
  /// **'{min, plural, =1{1 osoba} few{{min} osoby} many{{min} osób} other{{min} osoby}}'**
  String players(int min);

  /// No description provided for @playersRange.
  ///
  /// In pl, this message translates to:
  /// **'{min}–{max} osób'**
  String playersRange(int min, int max);

  /// No description provided for @itemsCount.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 zabawa} few{{count} zabawy} many{{count} zabaw} other{{count} zabawy}}'**
  String itemsCount(int count);

  /// No description provided for @kindAll.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko'**
  String get kindAll;

  /// No description provided for @kindAudioGame.
  ///
  /// In pl, this message translates to:
  /// **'Audiozabawy'**
  String get kindAudioGame;

  /// No description provided for @kindSong.
  ///
  /// In pl, this message translates to:
  /// **'Piosenki'**
  String get kindSong;

  /// No description provided for @kindInteractiveGame.
  ///
  /// In pl, this message translates to:
  /// **'Gry bez ekranu'**
  String get kindInteractiveGame;

  /// No description provided for @filterAge.
  ///
  /// In pl, this message translates to:
  /// **'Wiek'**
  String get filterAge;

  /// No description provided for @filterPack.
  ///
  /// In pl, this message translates to:
  /// **'Pakiet'**
  String get filterPack;

  /// No description provided for @filterSituation.
  ///
  /// In pl, this message translates to:
  /// **'Sytuacja'**
  String get filterSituation;

  /// No description provided for @filterClear.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść filtry'**
  String get filterClear;

  /// No description provided for @libraryEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Nic tu nie pasuje do wybranych filtrów.'**
  String get libraryEmpty;

  /// No description provided for @free.
  ///
  /// In pl, this message translates to:
  /// **'Za darmo'**
  String get free;

  /// No description provided for @locked.
  ///
  /// In pl, this message translates to:
  /// **'Wymaga odblokowania'**
  String get locked;

  /// No description provided for @detailsForParent.
  ///
  /// In pl, this message translates to:
  /// **'Dla rodzica'**
  String get detailsForParent;

  /// No description provided for @detailsPractises.
  ///
  /// In pl, this message translates to:
  /// **'Co ćwiczy'**
  String get detailsPractises;

  /// No description provided for @detailsYouNeed.
  ///
  /// In pl, this message translates to:
  /// **'Przyda się'**
  String get detailsYouNeed;

  /// No description provided for @requirementMikrofon.
  ///
  /// In pl, this message translates to:
  /// **'Mikrofon (opcjonalnie)'**
  String get requirementMikrofon;

  /// No description provided for @requirementMiejsceDoRuchu.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce do ruchu'**
  String get requirementMiejsceDoRuchu;

  /// No description provided for @requirementKartkaIOlowek.
  ///
  /// In pl, this message translates to:
  /// **'Kartka i ołówek'**
  String get requirementKartkaIOlowek;

  /// No description provided for @requirementWydrukPdf.
  ///
  /// In pl, this message translates to:
  /// **'Wydrukowane akta sprawy (PDF)'**
  String get requirementWydrukPdf;

  /// No description provided for @listen.
  ///
  /// In pl, this message translates to:
  /// **'Słuchaj'**
  String get listen;

  /// No description provided for @unlock.
  ///
  /// In pl, this message translates to:
  /// **'Odblokuj'**
  String get unlock;

  /// No description provided for @play.
  ///
  /// In pl, this message translates to:
  /// **'Odtwórz'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In pl, this message translates to:
  /// **'Pauza'**
  String get pause;

  /// No description provided for @rewind.
  ///
  /// In pl, this message translates to:
  /// **'Cofnij 15 sekund'**
  String get rewind;

  /// No description provided for @forward.
  ///
  /// In pl, this message translates to:
  /// **'Przewiń 15 sekund'**
  String get forward;

  /// No description provided for @loadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać katalogu.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In pl, this message translates to:
  /// **'Spróbuj ponownie'**
  String get retry;

  /// No description provided for @notFound.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono tej zabawy.'**
  String get notFound;

  /// No description provided for @resultsCount.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 pozycja} few{{count} pozycje} many{{count} pozycji} other{{count} pozycji}}'**
  String resultsCount(int count);

  /// No description provided for @navMine.
  ///
  /// In pl, this message translates to:
  /// **'Moje'**
  String get navMine;

  /// No description provided for @mineRecent.
  ///
  /// In pl, this message translates to:
  /// **'Ostatnio słuchane'**
  String get mineRecent;

  /// No description provided for @mineFavorites.
  ///
  /// In pl, this message translates to:
  /// **'Ulubione'**
  String get mineFavorites;

  /// No description provided for @mineDownloads.
  ///
  /// In pl, this message translates to:
  /// **'Pobrane'**
  String get mineDownloads;

  /// No description provided for @mineEmptyRecent.
  ///
  /// In pl, this message translates to:
  /// **'Tu pojawią się zabawy, których słuchaliście. Na razie cisza. Podejrzana cisza.'**
  String get mineEmptyRecent;

  /// No description provided for @mineEmptyFavorites.
  ///
  /// In pl, this message translates to:
  /// **'Dotknij serca przy zabawie, a trafi tutaj. Na razie pusto jak w lodówce w niedzielę wieczorem.'**
  String get mineEmptyFavorites;

  /// No description provided for @mineEmptyDownloads.
  ///
  /// In pl, this message translates to:
  /// **'Pobierz zabawy przed podróżą. Bez nich po 10 minutach jazdy padnie pytanie: „daleko jeszcze?”.'**
  String get mineEmptyDownloads;

  /// No description provided for @storageUsage.
  ///
  /// In pl, this message translates to:
  /// **'Pobrane: {used} · Wolne w telefonie: {free}'**
  String storageUsage(String used, String free);

  /// No description provided for @storageUsed.
  ///
  /// In pl, this message translates to:
  /// **'Pobrane: {used}'**
  String storageUsed(String used);

  /// No description provided for @deleteAllDownloads.
  ///
  /// In pl, this message translates to:
  /// **'Usuń wszystkie pobrane'**
  String get deleteAllDownloads;

  /// No description provided for @deleteAllConfirmTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć wszystkie pobrane zabawy?'**
  String get deleteAllConfirmTitle;

  /// No description provided for @deleteAllConfirmBody.
  ///
  /// In pl, this message translates to:
  /// **'Pliki znikną z telefonu. W każdej chwili możesz pobrać je ponownie.'**
  String get deleteAllConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get delete;

  /// No description provided for @download.
  ///
  /// In pl, this message translates to:
  /// **'Pobierz ({size})'**
  String download(String size);

  /// No description provided for @downloading.
  ///
  /// In pl, this message translates to:
  /// **'Pobieranie… {percent}%'**
  String downloading(int percent);

  /// No description provided for @downloadQueued.
  ///
  /// In pl, this message translates to:
  /// **'Czeka na pobranie…'**
  String get downloadQueued;

  /// No description provided for @verifying.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdzanie pliku…'**
  String get verifying;

  /// No description provided for @downloaded.
  ///
  /// In pl, this message translates to:
  /// **'Pobrano. Działa bez internetu.'**
  String get downloaded;

  /// No description provided for @removeDownload.
  ///
  /// In pl, this message translates to:
  /// **'Usuń z telefonu'**
  String get removeDownload;

  /// No description provided for @cancelDownload.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj pobieranie'**
  String get cancelDownload;

  /// No description provided for @downloadFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się pobrać. Sprawdź internet i spróbuj ponownie.'**
  String get downloadFailed;

  /// No description provided for @retryDownload.
  ///
  /// In pl, this message translates to:
  /// **'Pobierz ponownie'**
  String get retryDownload;

  /// No description provided for @notEnoughSpace.
  ///
  /// In pl, this message translates to:
  /// **'Za mało miejsca w telefonie: potrzeba {needed}, wolne {free}.'**
  String notEnoughSpace(String needed, String free);

  /// No description provided for @favoriteAdd.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj do ulubionych'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In pl, this message translates to:
  /// **'Usuń z ulubionych'**
  String get favoriteRemove;

  /// No description provided for @resumeFrom.
  ///
  /// In pl, this message translates to:
  /// **'Wznów od {time}'**
  String resumeFrom(String time);

  /// No description provided for @startOver.
  ///
  /// In pl, this message translates to:
  /// **'Od początku'**
  String get startOver;

  /// No description provided for @playbackUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Nie można teraz odtworzyć. Sprawdź internet albo pobierz zabawę wcześniej.'**
  String get playbackUnavailable;

  /// No description provided for @needsRefresh.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp do płatnych zabaw trzeba odświeżyć. Połącz się z internetem.'**
  String get needsRefresh;

  /// No description provided for @sleepTimer.
  ///
  /// In pl, this message translates to:
  /// **'Timer snu'**
  String get sleepTimer;

  /// No description provided for @sleepOff.
  ///
  /// In pl, this message translates to:
  /// **'Wyłącz timer'**
  String get sleepOff;

  /// No description provided for @sleepEndOfItem.
  ///
  /// In pl, this message translates to:
  /// **'Do końca zabawy'**
  String get sleepEndOfItem;

  /// No description provided for @sleepRemaining.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączy się za {time}'**
  String sleepRemaining(String time);

  /// No description provided for @sleepAtEnd.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączy się po tej zabawie'**
  String get sleepAtEnd;

  /// No description provided for @speed.
  ///
  /// In pl, this message translates to:
  /// **'Prędkość'**
  String get speed;

  /// No description provided for @speedLocked.
  ///
  /// In pl, this message translates to:
  /// **'W tej zabawie tempo jest stałe.'**
  String get speedLocked;

  /// No description provided for @noLookMode.
  ///
  /// In pl, this message translates to:
  /// **'Tryb bez patrzenia'**
  String get noLookMode;

  /// No description provided for @noLookHint.
  ///
  /// In pl, this message translates to:
  /// **'Połóż telefon i słuchajcie. Aby wyjść, przytrzymaj przycisk na dole.'**
  String get noLookHint;

  /// No description provided for @noLookExit.
  ///
  /// In pl, this message translates to:
  /// **'Przytrzymaj, aby wyjść'**
  String get noLookExit;

  /// No description provided for @nowPlaying.
  ///
  /// In pl, this message translates to:
  /// **'Teraz odtwarzane'**
  String get nowPlaying;

  /// No description provided for @devTools.
  ///
  /// In pl, this message translates to:
  /// **'Narzędzia deweloperskie'**
  String get devTools;

  /// No description provided for @devToolsHint.
  ///
  /// In pl, this message translates to:
  /// **'Widoczne tylko w wersji roboczej. Symulują zakupy do czasu podłączenia sklepów w Etapie 3.'**
  String get devToolsHint;

  /// No description provided for @devAccessMode.
  ///
  /// In pl, this message translates to:
  /// **'Symulowany dostęp'**
  String get devAccessMode;

  /// No description provided for @devRefresh.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież dostęp (jak po połączeniu z internetem)'**
  String get devRefresh;

  /// No description provided for @devExpireLease.
  ///
  /// In pl, this message translates to:
  /// **'Symuluj ponad 30 dni bez internetu'**
  String get devExpireLease;

  /// No description provided for @devLeaseUntil.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp offline ważny do: {date}'**
  String devLeaseUntil(String date);

  /// No description provided for @devLeaseNone.
  ///
  /// In pl, this message translates to:
  /// **'Brak dzierżawy offline'**
  String get devLeaseNone;

  /// No description provided for @gateTitle.
  ///
  /// In pl, this message translates to:
  /// **'Poproś rodzica'**
  String get gateTitle;

  /// No description provided for @gateForChild.
  ///
  /// In pl, this message translates to:
  /// **'Ta część aplikacji jest dla dorosłych.'**
  String get gateForChild;

  /// No description provided for @gateForParent.
  ///
  /// In pl, this message translates to:
  /// **'Dla rodzica: dotknij liczby'**
  String get gateForParent;

  /// No description provided for @gateWrong.
  ///
  /// In pl, this message translates to:
  /// **'To nie ta liczba. Spróbuj jeszcze raz.'**
  String get gateWrong;

  /// No description provided for @gateLocked.
  ///
  /// In pl, this message translates to:
  /// **'Zbyt wiele prób. Spróbuj ponownie za {seconds} s.'**
  String gateLocked(int seconds);

  /// No description provided for @kidsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Moje zabawy'**
  String get kidsTitle;

  /// No description provided for @kidsParentButton.
  ///
  /// In pl, this message translates to:
  /// **'Dla rodzica'**
  String get kidsParentButton;

  /// No description provided for @kidsEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Poproś rodzica, żeby przygotował zabawy.'**
  String get kidsEmpty;

  /// No description provided for @kidsCannotPlay.
  ///
  /// In pl, this message translates to:
  /// **'Tej zabawy nie da się teraz włączyć. Poproś rodzica.'**
  String get kidsCannotPlay;

  /// No description provided for @kidsEnterTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tryb dziecka'**
  String get kidsEnterTitle;

  /// No description provided for @kidsEnterSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Duże okładki, bez zakupów i ustawień'**
  String get kidsEnterSubtitle;

  /// No description provided for @kidsSetupHint.
  ///
  /// In pl, this message translates to:
  /// **'Dziecko zobaczy tylko zabawy dostępne dla jego wieku, bez zakupów, linków i ustawień. Wyjście z trybu wymaga rodzica.'**
  String get kidsSetupHint;

  /// No description provided for @kidsSetupAge.
  ///
  /// In pl, this message translates to:
  /// **'Wiek dziecka'**
  String get kidsSetupAge;

  /// No description provided for @kidsSetupOnlyDownloaded.
  ///
  /// In pl, this message translates to:
  /// **'Tylko pobrane'**
  String get kidsSetupOnlyDownloaded;

  /// No description provided for @kidsSetupOnlyDownloadedHint.
  ///
  /// In pl, this message translates to:
  /// **'Na podróż: pokaż wyłącznie zabawy działające bez internetu.'**
  String get kidsSetupOnlyDownloadedHint;

  /// No description provided for @kidsStart.
  ///
  /// In pl, this message translates to:
  /// **'Włącz tryb dziecka'**
  String get kidsStart;

  /// No description provided for @pdfSection.
  ///
  /// In pl, this message translates to:
  /// **'Do wydrukowania'**
  String get pdfSection;

  /// No description provided for @pdfOpen.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz do druku'**
  String get pdfOpen;

  /// No description provided for @pdfTitle.
  ///
  /// In pl, this message translates to:
  /// **'Karta do druku'**
  String get pdfTitle;

  /// No description provided for @pdfLoadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się otworzyć pliku. Sprawdź internet albo pobierz zabawę.'**
  String get pdfLoadError;

  /// No description provided for @paywallTitle.
  ///
  /// In pl, this message translates to:
  /// **'Odblokuj zabawy'**
  String get paywallTitle;

  /// No description provided for @paywallFor.
  ///
  /// In pl, this message translates to:
  /// **'Chcesz słuchać: {title}'**
  String paywallFor(String title);

  /// No description provided for @paywallSubscriptionHeader.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja'**
  String get paywallSubscriptionHeader;

  /// No description provided for @paywallSubscriptionBody.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie audiozabawy, piosenki i nowości, na każdym urządzeniu z tym samym kontem sklepu.'**
  String get paywallSubscriptionBody;

  /// No description provided for @paywallYearly.
  ///
  /// In pl, this message translates to:
  /// **'Rocznie (najkorzystniej)'**
  String get paywallYearly;

  /// No description provided for @paywallMonthly.
  ///
  /// In pl, this message translates to:
  /// **'Miesięcznie'**
  String get paywallMonthly;

  /// No description provided for @paywallTrialThen.
  ///
  /// In pl, this message translates to:
  /// **'{days} dni za darmo, potem {price} / {period}'**
  String paywallTrialThen(int days, String price, String period);

  /// No description provided for @periodMonth.
  ///
  /// In pl, this message translates to:
  /// **'miesiąc'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In pl, this message translates to:
  /// **'rok'**
  String get periodYear;

  /// No description provided for @paywallOneTimeHeader.
  ///
  /// In pl, this message translates to:
  /// **'Na zawsze, bez subskrypcji'**
  String get paywallOneTimeHeader;

  /// No description provided for @paywallOneTimeBody.
  ///
  /// In pl, this message translates to:
  /// **'Kupujesz raz i zostaje z Wami.'**
  String get paywallOneTimeBody;

  /// No description provided for @paywallBundleTwo.
  ///
  /// In pl, this message translates to:
  /// **'Wyobraźnia + Słowa i Wiedza'**
  String get paywallBundleTwo;

  /// No description provided for @paywallBundleThree.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie trzy pakiety'**
  String get paywallBundleThree;

  /// No description provided for @paywallSingle.
  ///
  /// In pl, this message translates to:
  /// **'Tylko ta zabawa'**
  String get paywallSingle;

  /// No description provided for @paywallSingleHint.
  ///
  /// In pl, this message translates to:
  /// **'Cały pakiet kosztuje {price}'**
  String paywallSingleHint(String price);

  /// No description provided for @paywallRestore.
  ///
  /// In pl, this message translates to:
  /// **'Przywróć zakupy'**
  String get paywallRestore;

  /// No description provided for @paywallLegalRenewal.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcja odnawia się automatycznie po tej samej cenie, chyba że wyłączysz ją co najmniej 24 godziny przed końcem okresu. Płatność pobiera {store}.'**
  String paywallLegalRenewal(String store);

  /// No description provided for @paywallLegalTrial.
  ///
  /// In pl, this message translates to:
  /// **'Po okresie próbnym, jeśli go nie anulujesz, zaczyna się płatna subskrypcja.'**
  String get paywallLegalTrial;

  /// No description provided for @paywallLegalManage.
  ///
  /// In pl, this message translates to:
  /// **'Subskrypcją zarządzasz i anulujesz ją w ustawieniach konta {store}.'**
  String paywallLegalManage(String store);

  /// No description provided for @paywallTerms.
  ///
  /// In pl, this message translates to:
  /// **'Regulamin'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In pl, this message translates to:
  /// **'Polityka prywatności'**
  String get paywallPrivacy;

  /// No description provided for @paywallUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Sklep jest teraz niedostępny. Sprawdź internet i spróbuj później.'**
  String get paywallUnavailable;

  /// No description provided for @purchaseSuccess.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe! Zabawy są odblokowane.'**
  String get purchaseSuccess;

  /// No description provided for @purchasePending.
  ///
  /// In pl, this message translates to:
  /// **'Zakup czeka na zatwierdzenie (np. przez opiekuna konta rodzinnego).'**
  String get purchasePending;

  /// No description provided for @purchaseStoreError.
  ///
  /// In pl, this message translates to:
  /// **'Sklep zgłosił błąd. Spróbuj ponownie.'**
  String get purchaseStoreError;

  /// No description provided for @purchaseVerifyLater.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się jeszcze potwierdzić zakupu. Spróbujemy ponownie automatycznie, nie płać drugi raz.'**
  String get purchaseVerifyLater;

  /// No description provided for @purchaseNothingToRestore.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleźliśmy zakupów do przywrócenia na tym koncie sklepu.'**
  String get purchaseNothingToRestore;

  /// No description provided for @devStoreOutcome.
  ///
  /// In pl, this message translates to:
  /// **'Wynik następnego zakupu w symulowanym sklepie'**
  String get devStoreOutcome;

  /// No description provided for @devClearPurchases.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść symulowane zakupy'**
  String get devClearPurchases;

  /// No description provided for @playGame.
  ///
  /// In pl, this message translates to:
  /// **'Zagraj'**
  String get playGame;

  /// No description provided for @gameListen.
  ///
  /// In pl, this message translates to:
  /// **'Słuchaj'**
  String get gameListen;

  /// No description provided for @gameYourTurn.
  ///
  /// In pl, this message translates to:
  /// **'Twoja kolej'**
  String get gameYourTurn;

  /// No description provided for @gameTapNow.
  ///
  /// In pl, this message translates to:
  /// **'Dotknij ekranu!'**
  String get gameTapNow;

  /// No description provided for @gameFinished.
  ///
  /// In pl, this message translates to:
  /// **'Koniec zabawy'**
  String get gameFinished;

  /// No description provided for @gameFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się uruchomić zabawy.'**
  String get gameFailed;

  /// No description provided for @onboardingHelloTitle.
  ///
  /// In pl, this message translates to:
  /// **'Cześć! Tu AudioKiddo.'**
  String get onboardingHelloTitle;

  /// No description provided for @onboardingHelloBody.
  ///
  /// In pl, this message translates to:
  /// **'Zanim zaczniemy: podgłośnij telefon do wygodnego poziomu. Tak, żeby było dobrze słychać, ale bez ogłuszania. Uszy są nam jeszcze potrzebne!'**
  String get onboardingHelloBody;

  /// No description provided for @onboardingHowTitle.
  ///
  /// In pl, this message translates to:
  /// **'Jak to działa'**
  String get onboardingHowTitle;

  /// No description provided for @onboardingHowListen.
  ///
  /// In pl, this message translates to:
  /// **'Włączasz zabawę i odkładasz telefon. Dziecko słucha, odpowiada i wykonuje zadania.'**
  String get onboardingHowListen;

  /// No description provided for @onboardingHowKids.
  ///
  /// In pl, this message translates to:
  /// **'Tylko duże okładki: bez zakupów, linków i ustawień. Wyjście z niego wymaga rodzica.'**
  String get onboardingHowKids;

  /// No description provided for @onboardingHowOffline.
  ///
  /// In pl, this message translates to:
  /// **'Pobrane zabawy działają bez internetu, na przykład w samochodzie.'**
  String get onboardingHowOffline;

  /// No description provided for @onboardingHowNoAds.
  ///
  /// In pl, this message translates to:
  /// **'Żadnych reklam ani śledzenia. Nie zbieramy danych o dziecku.'**
  String get onboardingHowNoAds;

  /// No description provided for @onboardingAgeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Ile lat ma dziecko?'**
  String get onboardingAgeTitle;

  /// No description provided for @onboardingAgeBody.
  ///
  /// In pl, this message translates to:
  /// **'Opcjonalnie. Podpowiemy zabawy dla tego wieku. Odpowiedź zostaje tylko w tym telefonie.'**
  String get onboardingAgeBody;

  /// No description provided for @onboardingNext.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In pl, this message translates to:
  /// **'Zaczynamy'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń'**
  String get onboardingSkip;

  /// No description provided for @onboardingStep.
  ///
  /// In pl, this message translates to:
  /// **'Krok {current} z {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @resumeGame.
  ///
  /// In pl, this message translates to:
  /// **'Wznów grę'**
  String get resumeGame;

  /// No description provided for @accountTitle.
  ///
  /// In pl, this message translates to:
  /// **'Konto rodzica'**
  String get accountTitle;

  /// No description provided for @accountIntro.
  ///
  /// In pl, this message translates to:
  /// **'Konto nie jest potrzebne do słuchania. Przyda się, jeśli masz już pakiety przypisane do swojego adresu e-mail albo chcesz zachować dostęp po zmianie telefonu.'**
  String get accountIntro;

  /// No description provided for @accountEmailLabel.
  ///
  /// In pl, this message translates to:
  /// **'Adres e-mail'**
  String get accountEmailLabel;

  /// No description provided for @accountSendCode.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij kod'**
  String get accountSendCode;

  /// No description provided for @accountCodeSent.
  ///
  /// In pl, this message translates to:
  /// **'Wysłaliśmy kod na adres {email}. Wpisz go poniżej. Jeśli go nie widzisz, zajrzyj do spamu.'**
  String accountCodeSent(String email);

  /// No description provided for @accountCodeLabel.
  ///
  /// In pl, this message translates to:
  /// **'Kod z e-maila'**
  String get accountCodeLabel;

  /// No description provided for @accountVerify.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get accountVerify;

  /// No description provided for @accountResend.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij kod ponownie'**
  String get accountResend;

  /// No description provided for @accountResendIn.
  ///
  /// In pl, this message translates to:
  /// **'Nowy kod za {seconds} s'**
  String accountResendIn(int seconds);

  /// No description provided for @accountChangeEmail.
  ///
  /// In pl, this message translates to:
  /// **'Zmień adres e-mail'**
  String get accountChangeEmail;

  /// No description provided for @accountSignedInAs.
  ///
  /// In pl, this message translates to:
  /// **'Zalogowano jako'**
  String get accountSignedInAs;

  /// No description provided for @accountAccess.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp na tym koncie'**
  String get accountAccess;

  /// No description provided for @accountNoAccess.
  ///
  /// In pl, this message translates to:
  /// **'Na tym koncie nie ma jeszcze zakupów.'**
  String get accountNoAccess;

  /// No description provided for @accountAllContent.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie zabawy (subskrypcja)'**
  String get accountAllContent;

  /// No description provided for @accountPack.
  ///
  /// In pl, this message translates to:
  /// **'Pakiet {title}'**
  String accountPack(String title);

  /// No description provided for @accountValidUntil.
  ///
  /// In pl, this message translates to:
  /// **'Ważne do {date}'**
  String accountValidUntil(String date);

  /// No description provided for @accountRefresh.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź zakupy ponownie'**
  String get accountRefresh;

  /// No description provided for @accountRefreshed.
  ///
  /// In pl, this message translates to:
  /// **'Zakupy sprawdzone.'**
  String get accountRefreshed;

  /// No description provided for @accountSignOut.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj się'**
  String get accountSignOut;

  /// No description provided for @accountSignOutBody.
  ///
  /// In pl, this message translates to:
  /// **'Pakiety z tego konta będą zablokowane do ponownego zalogowania. Pobrane pliki zostaną w telefonie.'**
  String get accountSignOutBody;

  /// No description provided for @accountDelete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń konto'**
  String get accountDelete;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In pl, this message translates to:
  /// **'Usunąć konto?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteBody.
  ///
  /// In pl, this message translates to:
  /// **'Usuniemy Twój adres e-mail i informacje o dostępie z naszego serwera. Tego nie da się cofnąć. Usunięcie konta nie anuluje subskrypcji: zrobisz to w ustawieniach App Store albo Google Play.'**
  String get accountDeleteBody;

  /// No description provided for @accountDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Konto zostało usunięte.'**
  String get accountDeleted;

  /// No description provided for @accountErrorInvalidEmail.
  ///
  /// In pl, this message translates to:
  /// **'Sprawdź adres e-mail.'**
  String get accountErrorInvalidEmail;

  /// No description provided for @accountErrorTooMany.
  ///
  /// In pl, this message translates to:
  /// **'Za dużo prób. Odczekaj chwilę i spróbuj ponownie.'**
  String get accountErrorTooMany;

  /// No description provided for @accountErrorWrongCode.
  ///
  /// In pl, this message translates to:
  /// **'Kod jest nieprawidłowy albo wygasł. Wyślij nowy.'**
  String get accountErrorWrongCode;

  /// No description provided for @accountErrorOffline.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia z internetem.'**
  String get accountErrorOffline;

  /// No description provided for @accountErrorServer.
  ///
  /// In pl, this message translates to:
  /// **'Coś poszło nie tak po naszej stronie. Spróbuj za chwilę.'**
  String get accountErrorServer;

  /// No description provided for @paywallHaveAccess.
  ///
  /// In pl, this message translates to:
  /// **'Masz już dostęp? Zaloguj się'**
  String get paywallHaveAccess;

  /// No description provided for @gameAnswerNow.
  ///
  /// In pl, this message translates to:
  /// **'Twoja odpowiedź!'**
  String get gameAnswerNow;

  /// No description provided for @micTitle.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedzi głosem i klaśnięciem'**
  String get micTitle;

  /// No description provided for @micOffBody.
  ///
  /// In pl, this message translates to:
  /// **'Dziecko może odpowiadać klaśnięciem albo głosem, bez dotykania telefonu. Mikrofon działa tylko w czasie zabawy, a dźwięk jest analizowany w telefonie: nic nie jest nagrywane ani wysyłane.'**
  String get micOffBody;

  /// No description provided for @micOnBody.
  ///
  /// In pl, this message translates to:
  /// **'Włączone. Zabawy słuchają klaśnięć i głosu dziecka tylko wtedy, gdy czekają na odpowiedź. Nic nie jest nagrywane ani wysyłane.'**
  String get micOnBody;

  /// No description provided for @micEnable.
  ///
  /// In pl, this message translates to:
  /// **'Włącz mikrofon'**
  String get micEnable;

  /// No description provided for @micDisable.
  ///
  /// In pl, this message translates to:
  /// **'Wyłącz'**
  String get micDisable;

  /// No description provided for @micDenied.
  ///
  /// In pl, this message translates to:
  /// **'Telefon nie pozwolił na mikrofon. Możesz to zmienić w Ustawieniach telefonu → AudioKiddo. Do tego czasu zabawy działają bez mikrofonu.'**
  String get micDenied;

  /// No description provided for @micWithout.
  ///
  /// In pl, this message translates to:
  /// **'Bez mikrofonu zabawa podpowiada, kiedy odpowiedzieć, i czeka chwilę na odpowiedź.'**
  String get micWithout;

  /// No description provided for @signInApple.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z Apple'**
  String get signInApple;

  /// No description provided for @signInGoogle.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z Google'**
  String get signInGoogle;

  /// No description provided for @signInEmail.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z e-mailem'**
  String get signInEmail;

  /// No description provided for @signInNotConfigured.
  ///
  /// In pl, this message translates to:
  /// **'To logowanie będzie dostępne wkrótce. Na razie zaloguj się adresem e-mail.'**
  String get signInNotConfigured;

  /// No description provided for @signInFooter.
  ///
  /// In pl, this message translates to:
  /// **'Konto jest dla rodzica. Nie zbieramy danych o dziecku ani reklamowych.'**
  String get signInFooter;

  /// No description provided for @signInEmailTitle.
  ///
  /// In pl, this message translates to:
  /// **'Logowanie e-mailem'**
  String get signInEmailTitle;

  /// No description provided for @signInEmailBody.
  ///
  /// In pl, this message translates to:
  /// **'Bez hasła: wyślemy Ci jednorazowy kod.'**
  String get signInEmailBody;

  /// No description provided for @accountSignedOutTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get accountSignedOutTitle;

  /// No description provided for @accountSectionAccount.
  ///
  /// In pl, this message translates to:
  /// **'Konto'**
  String get accountSectionAccount;

  /// No description provided for @accountAccessFooter.
  ///
  /// In pl, this message translates to:
  /// **'Pakiety przypisane do tego konta działają na każdym telefonie, na którym się zalogujesz.'**
  String get accountAccessFooter;

  /// No description provided for @accountDeleteFooter.
  ///
  /// In pl, this message translates to:
  /// **'Usuwa adres e-mail i informacje o dostępie z naszego serwera. Subskrypcję anulujesz w ustawieniach App Store albo Google Play.'**
  String get accountDeleteFooter;

  /// No description provided for @onboardingHelloSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Audiozabawy pełne przygód'**
  String get onboardingHelloSubtitle;

  /// No description provided for @onboardingVolumeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw głośność'**
  String get onboardingVolumeTitle;

  /// No description provided for @onboardingHowListenTitle.
  ///
  /// In pl, this message translates to:
  /// **'Słuchanie bez ekranu'**
  String get onboardingHowListenTitle;

  /// No description provided for @onboardingHowKidsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tryb dziecka'**
  String get onboardingHowKidsTitle;

  /// No description provided for @onboardingHowOfflineTitle.
  ///
  /// In pl, this message translates to:
  /// **'Działa bez internetu'**
  String get onboardingHowOfflineTitle;

  /// No description provided for @onboardingHowNoAdsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Bez reklam'**
  String get onboardingHowNoAdsTitle;

  /// No description provided for @onboardingAccountTitle.
  ///
  /// In pl, this message translates to:
  /// **'Konto rodzica'**
  String get onboardingAccountTitle;

  /// No description provided for @onboardingAccountBody.
  ///
  /// In pl, this message translates to:
  /// **'Opcjonalnie. Zaloguj się, jeśli masz już pakiety przypisane do adresu e-mail albo chcesz zachować dostęp po zmianie telefonu.'**
  String get onboardingAccountBody;

  /// No description provided for @onboardingAccountDone.
  ///
  /// In pl, this message translates to:
  /// **'Zalogowano'**
  String get onboardingAccountDone;

  /// No description provided for @onboardingStartWithoutAccount.
  ///
  /// In pl, this message translates to:
  /// **'Zacznij bez konta'**
  String get onboardingStartWithoutAccount;

  /// No description provided for @introSkip.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń'**
  String get introSkip;

  /// No description provided for @introVolumeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Podgłośnij!'**
  String get introVolumeTitle;

  /// No description provided for @introVolumeBody.
  ///
  /// In pl, this message translates to:
  /// **'Żeby dobrze słyszeć Kiddo.'**
  String get introVolumeBody;

  /// No description provided for @introPasswordTitle.
  ///
  /// In pl, this message translates to:
  /// **'MAGICZNE HASŁO'**
  String get introPasswordTitle;

  /// No description provided for @introPasswordSay.
  ///
  /// In pl, this message translates to:
  /// **'Powiedz głośno:'**
  String get introPasswordSay;

  /// No description provided for @introPasswordWord.
  ///
  /// In pl, this message translates to:
  /// **'ABRAKADABRA!'**
  String get introPasswordWord;

  /// No description provided for @introPasswordListening.
  ///
  /// In pl, this message translates to:
  /// **'(słucham…)'**
  String get introPasswordListening;

  /// No description provided for @introPasswordTap.
  ///
  /// In pl, this message translates to:
  /// **'…i dotknij magicznej kuli'**
  String get introPasswordTap;

  /// No description provided for @introPasswordOrb.
  ///
  /// In pl, this message translates to:
  /// **'Magiczna kula. Dotknij, aby wejść.'**
  String get introPasswordOrb;

  /// No description provided for @introGranted.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp przyznany!'**
  String get introGranted;

  /// No description provided for @homeKiddo.
  ///
  /// In pl, this message translates to:
  /// **'Kiddo. Dotknij, a coś powie.'**
  String get homeKiddo;

  /// No description provided for @homeNew.
  ///
  /// In pl, this message translates to:
  /// **'Nowość!'**
  String get homeNew;

  /// No description provided for @homeNewHint.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiadaj klaśnięciem albo głosem!'**
  String get homeNewHint;

  /// No description provided for @kidsHello1.
  ///
  /// In pl, this message translates to:
  /// **'Hej! W co dziś zagramy?'**
  String get kidsHello1;

  /// No description provided for @kidsHello2.
  ///
  /// In pl, this message translates to:
  /// **'Witaj z powrotem! Wybierz przygodę!'**
  String get kidsHello2;

  /// No description provided for @kidsHello3.
  ///
  /// In pl, this message translates to:
  /// **'Gotowi na zabawę? Ja jestem gotowy!'**
  String get kidsHello3;

  /// No description provided for @quizBack.
  ///
  /// In pl, this message translates to:
  /// **'Wstecz'**
  String get quizBack;

  /// No description provided for @quizYourChild.
  ///
  /// In pl, this message translates to:
  /// **'Twoje dziecko'**
  String get quizYourChild;

  /// No description provided for @quizHello.
  ///
  /// In pl, this message translates to:
  /// **'Cześć! Zadam kilka szybkich pytań, żeby dobrać zabawy. Minutka, obiecuję. Kiddo nie kłamie.'**
  String get quizHello;

  /// No description provided for @quizHelloPoint1.
  ///
  /// In pl, this message translates to:
  /// **'Około minuty na każde dziecko.'**
  String get quizHelloPoint1;

  /// No description provided for @quizHelloPoint2.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedzi zostają tylko w tym telefonie.'**
  String get quizHelloPoint2;

  /// No description provided for @quizHelloPoint3.
  ///
  /// In pl, this message translates to:
  /// **'Masz więcej dzieci? Każde dostanie własny plan.'**
  String get quizHelloPoint3;

  /// No description provided for @quizName.
  ///
  /// In pl, this message translates to:
  /// **'Jak ma na imię Twoje dziecko?'**
  String get quizName;

  /// No description provided for @quizNameHint.
  ///
  /// In pl, this message translates to:
  /// **'Imię albo przezwisko (opcjonalnie)'**
  String get quizNameHint;

  /// No description provided for @quizNamePrivacy.
  ///
  /// In pl, this message translates to:
  /// **'Zapisujemy je tylko w tym telefonie, żeby było wiadomo, czyj to plan.'**
  String get quizNamePrivacy;

  /// No description provided for @quizAge.
  ///
  /// In pl, this message translates to:
  /// **'Ile lat ma {name}?'**
  String quizAge(String name);

  /// No description provided for @quizGoals.
  ///
  /// In pl, this message translates to:
  /// **'Co chcecie rozwijać? Możesz wybrać kilka.'**
  String get quizGoals;

  /// No description provided for @quizSituations.
  ///
  /// In pl, this message translates to:
  /// **'Kiedy najczęściej słuchacie? (opcjonalnie)'**
  String get quizSituations;

  /// No description provided for @quizMinutes.
  ///
  /// In pl, this message translates to:
  /// **'Ile czasu dziennie na zabawę?'**
  String get quizMinutes;

  /// No description provided for @quizMinutesOption.
  ///
  /// In pl, this message translates to:
  /// **'{minutes} min dziennie'**
  String quizMinutesOption(int minutes);

  /// No description provided for @quizMinutes5.
  ///
  /// In pl, this message translates to:
  /// **'Na rozgrzewkę. Tyle, ile stygnie kawa.'**
  String get quizMinutes5;

  /// No description provided for @quizMinutes10.
  ///
  /// In pl, this message translates to:
  /// **'W sam raz. Jeden cykl wirowania pralki.'**
  String get quizMinutes10;

  /// No description provided for @quizMinutes15.
  ///
  /// In pl, this message translates to:
  /// **'Ambitnie. Pół odcinka serialu, którego i tak nie obejrzysz.'**
  String get quizMinutes15;

  /// No description provided for @quizMinutes20.
  ///
  /// In pl, this message translates to:
  /// **'Z rozmachem. Prawie cały obiad bez „mamo, tato, a wiesz co?”.'**
  String get quizMinutes20;

  /// No description provided for @quizSummary.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe! Plan dla: {name}. Po {minutes} min dziennie, zaczynamy od łatwych zabaw.'**
  String quizSummary(String name, int minutes);

  /// No description provided for @quizSummaryAge.
  ///
  /// In pl, this message translates to:
  /// **'Zabawy dobrane do wieku: {age, plural, =1{1 rok} few{{age} lata} many{{age} lat} other{{age} lat}}.'**
  String quizSummaryAge(int age);

  /// No description provided for @quizSummaryLevels.
  ///
  /// In pl, this message translates to:
  /// **'Codziennie jedna porcja. Nowe rzeczy pojawiają się stopniowo, poziom po poziomie.'**
  String get quizSummaryLevels;

  /// No description provided for @quizSummaryChange.
  ///
  /// In pl, this message translates to:
  /// **'Plan zmienisz w każdej chwili w zakładce Plan.'**
  String get quizSummaryChange;

  /// No description provided for @quizAnotherChild.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj kolejne dziecko'**
  String get quizAnotherChild;

  /// No description provided for @quizStart.
  ///
  /// In pl, this message translates to:
  /// **'Zaczynamy'**
  String get quizStart;

  /// No description provided for @quizContinue.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get quizContinue;

  /// No description provided for @quizFinish.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe'**
  String get quizFinish;

  /// No description provided for @quizSave.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get quizSave;

  /// No description provided for @quizProgress.
  ///
  /// In pl, this message translates to:
  /// **'Postęp pytań'**
  String get quizProgress;

  /// No description provided for @goalImagination.
  ///
  /// In pl, this message translates to:
  /// **'Wyobraźnia i opowiadanie'**
  String get goalImagination;

  /// No description provided for @goalLanguage.
  ///
  /// In pl, this message translates to:
  /// **'Słownictwo i mowa'**
  String get goalLanguage;

  /// No description provided for @goalLogic.
  ///
  /// In pl, this message translates to:
  /// **'Logiczne myślenie'**
  String get goalLogic;

  /// No description provided for @goalListening.
  ///
  /// In pl, this message translates to:
  /// **'Uważne słuchanie i skupienie'**
  String get goalListening;

  /// No description provided for @goalMovement.
  ///
  /// In pl, this message translates to:
  /// **'Ruch i rytm'**
  String get goalMovement;

  /// No description provided for @goalCalm.
  ///
  /// In pl, this message translates to:
  /// **'Wyciszenie przed snem'**
  String get goalCalm;

  /// No description provided for @reminder1Title.
  ///
  /// In pl, this message translates to:
  /// **'Kiddo czeka'**
  String get reminder1Title;

  /// No description provided for @reminder1Body.
  ///
  /// In pl, this message translates to:
  /// **'Dzień był długi? 10 minut zabawy i przez chwilę to ktoś inny odpowiada na pytania.'**
  String get reminder1Body;

  /// No description provided for @reminder2Title.
  ///
  /// In pl, this message translates to:
  /// **'Pora na przygodę'**
  String get reminder2Title;

  /// No description provided for @reminder2Body.
  ///
  /// In pl, this message translates to:
  /// **'Kawa znowu wystygła? Kawy nie uratujemy. Ciszę może tak: dzisiejsza zabawa czeka.'**
  String get reminder2Body;

  /// No description provided for @reminder3Title.
  ///
  /// In pl, this message translates to:
  /// **'Seria trwa!'**
  String get reminder3Title;

  /// No description provided for @reminder3Body.
  ///
  /// In pl, this message translates to:
  /// **'Jeszcze jeden dzień, a seria będzie dłuższa niż Twój ostatni nieprzerwany sen.'**
  String get reminder3Body;

  /// No description provided for @reminder4Title.
  ///
  /// In pl, this message translates to:
  /// **'Kiddo tu'**
  String get reminder4Title;

  /// No description provided for @reminder4Body.
  ///
  /// In pl, this message translates to:
  /// **'Dziecko zadało dziś już 347 pytań? Oddaj kilka Kiddo. On to lubi. Serio.'**
  String get reminder4Body;

  /// No description provided for @reminder5Title.
  ///
  /// In pl, this message translates to:
  /// **'Cisza w domu?'**
  String get reminder5Title;

  /// No description provided for @reminder5Body.
  ///
  /// In pl, this message translates to:
  /// **'Podejrzane. Sprawdź, co się dzieje, a potem włącz dzisiejszą zabawę.'**
  String get reminder5Body;

  /// No description provided for @reminder6Title.
  ///
  /// In pl, this message translates to:
  /// **'Bez ekranu, bez wyrzutów'**
  String get reminder6Title;

  /// No description provided for @reminder6Body.
  ///
  /// In pl, this message translates to:
  /// **'Oczy odpoczywają, uszy pracują, a Ty może nawet usiądziesz. Na chwilę.'**
  String get reminder6Body;

  /// No description provided for @reminder7Title.
  ///
  /// In pl, this message translates to:
  /// **'Kiddo nie śpi'**
  String get reminder7Title;

  /// No description provided for @reminder7Body.
  ///
  /// In pl, this message translates to:
  /// **'Kiddo nie śpi. Kiddo czeka. Kiddo trochę tęskni. Dzisiejsza porcja to kilka minut.'**
  String get reminder7Body;

  /// No description provided for @remindersAsk.
  ///
  /// In pl, this message translates to:
  /// **'Mogę przypominać o codziennej zabawie? Obiecuję nie przesadzać. Raz dziennie, z humorem.'**
  String get remindersAsk;

  /// No description provided for @remindersWhen.
  ///
  /// In pl, this message translates to:
  /// **'O której przypomnieć?'**
  String get remindersWhen;

  /// No description provided for @remindersMorning.
  ///
  /// In pl, this message translates to:
  /// **'Rano'**
  String get remindersMorning;

  /// No description provided for @remindersAfternoon.
  ///
  /// In pl, this message translates to:
  /// **'Po przedszkolu'**
  String get remindersAfternoon;

  /// No description provided for @remindersEvening.
  ///
  /// In pl, this message translates to:
  /// **'Wieczorem'**
  String get remindersEvening;

  /// No description provided for @remindersBedtime.
  ///
  /// In pl, this message translates to:
  /// **'Przed snem'**
  String get remindersBedtime;

  /// No description provided for @remindersEnable.
  ///
  /// In pl, this message translates to:
  /// **'Włącz przypomnienia'**
  String get remindersEnable;

  /// No description provided for @remindersLater.
  ///
  /// In pl, this message translates to:
  /// **'Nie teraz'**
  String get remindersLater;

  /// No description provided for @remindersDenied.
  ///
  /// In pl, this message translates to:
  /// **'Telefon nie pozwolił na powiadomienia. Możesz to zmienić w Ustawieniach telefonu.'**
  String get remindersDenied;

  /// No description provided for @remindersNote.
  ///
  /// In pl, this message translates to:
  /// **'Zmienisz to w każdej chwili w zakładce Plan.'**
  String get remindersNote;

  /// No description provided for @remindersPreviewApp.
  ///
  /// In pl, this message translates to:
  /// **'AudioKiddo'**
  String get remindersPreviewApp;

  /// No description provided for @remindersPreviewTime.
  ///
  /// In pl, this message translates to:
  /// **'teraz'**
  String get remindersPreviewTime;

  /// No description provided for @navPlan.
  ///
  /// In pl, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @childNumber.
  ///
  /// In pl, this message translates to:
  /// **'Dziecko {n}'**
  String childNumber(int n);

  /// No description provided for @planEmptyTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tu będzie plan zabaw na każdy dzień'**
  String get planEmptyTitle;

  /// No description provided for @planEmptyBody.
  ///
  /// In pl, this message translates to:
  /// **'Odpowiedz na kilka pytań (minuta), a Kiddo rozłoży zabawy na dni: po trochu, bez przytłaczania.'**
  String get planEmptyBody;

  /// No description provided for @planEmptyButton.
  ///
  /// In pl, this message translates to:
  /// **'Dopasuj plan'**
  String get planEmptyButton;

  /// No description provided for @planAddChild.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj dziecko'**
  String get planAddChild;

  /// No description provided for @planAge.
  ///
  /// In pl, this message translates to:
  /// **'{age} l.'**
  String planAge(int age);

  /// No description provided for @planStreak.
  ///
  /// In pl, this message translates to:
  /// **'dni z rzędu'**
  String get planStreak;

  /// No description provided for @planDays.
  ///
  /// In pl, this message translates to:
  /// **'dni planu'**
  String get planDays;

  /// No description provided for @planAccuracy.
  ///
  /// In pl, this message translates to:
  /// **'dobrych odpowiedzi'**
  String get planAccuracy;

  /// No description provided for @planTodayDone.
  ///
  /// In pl, this message translates to:
  /// **'Dzisiejsza porcja zaliczona! Kolejna otworzy się jutro. Odpocznijcie, zasłużyliście.'**
  String get planTodayDone;

  /// No description provided for @planOpensTomorrow.
  ///
  /// In pl, this message translates to:
  /// **'Ten dzień otworzy się jutro. Po trochu, codziennie: tak działa najlepiej.'**
  String get planOpensTomorrow;

  /// No description provided for @planLockedDay.
  ///
  /// In pl, this message translates to:
  /// **'Najpierw skończcie dzień {day}.'**
  String planLockedDay(int day);

  /// No description provided for @planLevel.
  ///
  /// In pl, this message translates to:
  /// **'Poziom {level} · dni {first}–{last}'**
  String planLevel(int level, int first, int last);

  /// No description provided for @planNodeDone.
  ///
  /// In pl, this message translates to:
  /// **'Dzień {day}, zaliczony. Otwórz, aby powtórzyć.'**
  String planNodeDone(int day);

  /// No description provided for @planNodeToday.
  ///
  /// In pl, this message translates to:
  /// **'Dzień {day}, dzisiaj. Otwórz zabawy.'**
  String planNodeToday(int day);

  /// No description provided for @planNodeLocked.
  ///
  /// In pl, this message translates to:
  /// **'Dzień {day}, zablokowany.'**
  String planNodeLocked(int day);

  /// No description provided for @planDayTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dzień {day}'**
  String planDayTitle(int day);

  /// No description provided for @planChest.
  ///
  /// In pl, this message translates to:
  /// **'Koniec tygodnia! Nagroda: pochwalcie się dziś przy kolacji, czego się nauczyliście. Kiddo pozdrawia.'**
  String get planChest;

  /// No description provided for @level1Name.
  ///
  /// In pl, this message translates to:
  /// **'Poznajemy się'**
  String get level1Name;

  /// No description provided for @level1News.
  ///
  /// In pl, this message translates to:
  /// **'Krótkie zabawy i piosenki. Bez presji.'**
  String get level1News;

  /// No description provided for @level2Name.
  ///
  /// In pl, this message translates to:
  /// **'Rozkręcamy się'**
  String get level2Name;

  /// No description provided for @level2News.
  ///
  /// In pl, this message translates to:
  /// **'Nowość: zabawy, w których dziecko odpowiada.'**
  String get level2News;

  /// No description provided for @level3Name.
  ///
  /// In pl, this message translates to:
  /// **'Małe wyzwania'**
  String get level3Name;

  /// No description provided for @level3News.
  ///
  /// In pl, this message translates to:
  /// **'Nowość: dłuższe przygody i karty do druku.'**
  String get level3News;

  /// No description provided for @level4Name.
  ///
  /// In pl, this message translates to:
  /// **'Mistrzowie słuchania'**
  String get level4Name;

  /// No description provided for @level4News.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko odblokowane. Teraz Wy prowadzicie.'**
  String get level4News;

  /// No description provided for @tipPhoneDown.
  ///
  /// In pl, this message translates to:
  /// **'Połóżcie telefon ekranem w dół i słuchajcie razem. Za pierwszym razem najlepiej z Tobą obok.'**
  String get tipPhoneDown;

  /// No description provided for @tipKidsMode.
  ///
  /// In pl, this message translates to:
  /// **'Włącz tryb dziecka na stronie Start: duże okładki i żadnych zakupów.'**
  String get tipKidsMode;

  /// No description provided for @tipDownload.
  ///
  /// In pl, this message translates to:
  /// **'Pobierz zabawy na drogę: działają bez internetu, nawet w tunelu i u teściów na wsi.'**
  String get tipDownload;

  /// No description provided for @tipFavorites.
  ///
  /// In pl, this message translates to:
  /// **'Serduszko przy zabawie i ulubione są zawsze pod ręką w zakładce Moje.'**
  String get tipFavorites;

  /// No description provided for @tipMicrophone.
  ///
  /// In pl, this message translates to:
  /// **'Nowość: dziecko może odpowiadać klaśnięciem albo głosem. Włączysz to w szczegółach zabawy.'**
  String get tipMicrophone;

  /// No description provided for @tipSleepTimer.
  ///
  /// In pl, this message translates to:
  /// **'Wieczorem ustaw w odtwarzaczu timer snu. Zabawa sama ucichnie. Ty nie musisz.'**
  String get tipSleepTimer;

  /// No description provided for @tipPrintables.
  ///
  /// In pl, this message translates to:
  /// **'Niektóre zabawy mają karty do druku, np. dyplom albo akta detektywa.'**
  String get tipPrintables;

  /// No description provided for @tipAccount.
  ///
  /// In pl, this message translates to:
  /// **'Załóż konto rodzica, żeby zakupy działały też na innych telefonach.'**
  String get tipAccount;

  /// No description provided for @progressTitle.
  ///
  /// In pl, this message translates to:
  /// **'Postęp'**
  String get progressTitle;

  /// No description provided for @progressOf.
  ///
  /// In pl, this message translates to:
  /// **'Postęp: {name}'**
  String progressOf(String name);

  /// No description provided for @progressEmpty.
  ///
  /// In pl, this message translates to:
  /// **'Tu pojawi się postęp. Na razie jest tu cicho. Tak cicho, jak w domu, kiedy dzieci coś kombinują.'**
  String get progressEmpty;

  /// No description provided for @progressStreak.
  ///
  /// In pl, this message translates to:
  /// **'dni z rzędu'**
  String get progressStreak;

  /// No description provided for @progressDays.
  ///
  /// In pl, this message translates to:
  /// **'dni z zabawą'**
  String get progressDays;

  /// No description provided for @progressMinutes.
  ///
  /// In pl, this message translates to:
  /// **'minut słuchania'**
  String get progressMinutes;

  /// No description provided for @progressCorrect.
  ///
  /// In pl, this message translates to:
  /// **'dobre odpowiedzi'**
  String get progressCorrect;

  /// No description provided for @progressSkills.
  ///
  /// In pl, this message translates to:
  /// **'Umiejętności'**
  String get progressSkills;

  /// No description provided for @progressSkillsFooter.
  ///
  /// In pl, this message translates to:
  /// **'Ile razy dziecko ćwiczyło daną umiejętność. Procent pokazujemy tam, gdzie zabawa sprawdza odpowiedzi.'**
  String get progressSkillsFooter;

  /// No description provided for @progressTimes.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =1{1 raz} few{{count} razy} many{{count} razy} other{{count} razy}}'**
  String progressTimes(int count);

  /// No description provided for @progressAdvice.
  ///
  /// In pl, this message translates to:
  /// **'Podpowiedzi'**
  String get progressAdvice;

  /// No description provided for @progressSettings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia planu'**
  String get progressSettings;

  /// No description provided for @progressEditProfile.
  ///
  /// In pl, this message translates to:
  /// **'Wiek, cele i czas'**
  String get progressEditProfile;

  /// No description provided for @progressProfileSummary.
  ///
  /// In pl, this message translates to:
  /// **'{age, plural, =1{1 rok} few{{age} lata} many{{age} lat} other{{age} lat}} · {minutes} min dziennie'**
  String progressProfileSummary(int age, int minutes);

  /// No description provided for @progressReminders.
  ///
  /// In pl, this message translates to:
  /// **'Przypomnienia'**
  String get progressReminders;

  /// No description provided for @progressRemindersAt.
  ///
  /// In pl, this message translates to:
  /// **'Codziennie o {time}. Dotknij, aby wyłączyć.'**
  String progressRemindersAt(String time);

  /// No description provided for @progressRemindersOff.
  ///
  /// In pl, this message translates to:
  /// **'Wyłączone. Dotknij, aby włączyć.'**
  String get progressRemindersOff;

  /// No description provided for @progressRemoveChild.
  ///
  /// In pl, this message translates to:
  /// **'Usuń profil dziecka'**
  String get progressRemoveChild;

  /// No description provided for @progressRemoveBody.
  ///
  /// In pl, this message translates to:
  /// **'Usuniemy profil i postęp tego dziecka z telefonu. Zakupy zostają.'**
  String get progressRemoveBody;

  /// No description provided for @adviceExcelling.
  ///
  /// In pl, this message translates to:
  /// **'{skill}: świetnie idzie! Czas na coś trudniejszego.'**
  String adviceExcelling(String skill);

  /// No description provided for @adviceExcellingPack.
  ///
  /// In pl, this message translates to:
  /// **'{skill}: świetnie idzie! Spróbujcie pakietu {pack}.'**
  String adviceExcellingPack(String skill, String pack);

  /// No description provided for @adviceNeedsPractice.
  ///
  /// In pl, this message translates to:
  /// **'{skill}: warto poćwiczyć. Powtarzajcie ulubione zabawy.'**
  String adviceNeedsPractice(String skill);

  /// No description provided for @adviceNeedsPracticePack.
  ///
  /// In pl, this message translates to:
  /// **'{skill}: warto poćwiczyć. Pomoże pakiet {pack}.'**
  String adviceNeedsPracticePack(String skill, String pack);

  /// No description provided for @adviceUntouched.
  ///
  /// In pl, this message translates to:
  /// **'{skill}: to Wasz cel, a jeszcze go nie ćwiczyliście.'**
  String adviceUntouched(String skill);

  /// No description provided for @adviceUntouchedPack.
  ///
  /// In pl, this message translates to:
  /// **'{skill}: to Wasz cel. Najwięcej takich zabaw ma pakiet {pack}.'**
  String adviceUntouchedPack(String skill, String pack);

  /// No description provided for @adviceComeBack.
  ///
  /// In pl, this message translates to:
  /// **'Kilka dni przerwy? Zdarza się najlepszym. Wystarczy 5 minut dziś, żeby wrócić do rytmu.'**
  String get adviceComeBack;

  /// No description provided for @adviceLevelUp.
  ///
  /// In pl, this message translates to:
  /// **'Regularność na medal! Można dodać kilka minut dziennie.'**
  String get adviceLevelUp;

  /// No description provided for @paywallCarTrial.
  ///
  /// In pl, this message translates to:
  /// **'Mamo, tato… daleko jeszcze? A może 7 dni za darmo, zanim dojedziemy?'**
  String get paywallCarTrial;

  /// No description provided for @paywallCar.
  ///
  /// In pl, this message translates to:
  /// **'Mamo, tato… daleko jeszcze? Z zabawami będzie bliżej!'**
  String get paywallCar;

  /// No description provided for @onboardingDailyTitle.
  ///
  /// In pl, this message translates to:
  /// **'Po trochu, codziennie'**
  String get onboardingDailyTitle;

  /// No description provided for @onboardingDailyBody.
  ///
  /// In pl, this message translates to:
  /// **'Kiddo rozłoży zabawy na dni: kilka minut dziennie wystarczy, żeby ćwiczyć słuchanie, mowę i wyobraźnię. Bez przytłaczania.'**
  String get onboardingDailyBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
