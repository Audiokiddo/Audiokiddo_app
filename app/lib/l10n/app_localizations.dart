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
  /// **'Tu pojawią się zabawy, których słuchaliście.'**
  String get mineEmptyRecent;

  /// No description provided for @mineEmptyFavorites.
  ///
  /// In pl, this message translates to:
  /// **'Dotknij serca przy zabawie, aby dodać ją do ulubionych.'**
  String get mineEmptyFavorites;

  /// No description provided for @mineEmptyDownloads.
  ///
  /// In pl, this message translates to:
  /// **'Pobierz zabawy przed podróżą, żeby działały bez internetu.'**
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
  /// **'Akta sprawy do druku'**
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
  /// **'Włączasz zabawę i odkładasz telefon. Dziecko słucha, odpowiada na głos i wykonuje zadania. Nie trzeba patrzeć w ekran.'**
  String get onboardingHowListen;

  /// No description provided for @onboardingHowKids.
  ///
  /// In pl, this message translates to:
  /// **'Tryb dziecka pokazuje tylko duże okładki: bez zakupów, linków i ustawień. Wyjście z niego wymaga rodzica.'**
  String get onboardingHowKids;

  /// No description provided for @onboardingHowOffline.
  ///
  /// In pl, this message translates to:
  /// **'Pobrane zabawy działają bez internetu, na przykład w samochodzie.'**
  String get onboardingHowOffline;

  /// No description provided for @onboardingHowNoAds.
  ///
  /// In pl, this message translates to:
  /// **'Bez reklam i bez śledzenia.'**
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
