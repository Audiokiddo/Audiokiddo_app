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
  /// **'Gry'**
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

  /// No description provided for @unlockComingSoon.
  ///
  /// In pl, this message translates to:
  /// **'Zakupy i subskrypcja pojawią się w kolejnym etapie prac.'**
  String get unlockComingSoon;

  /// No description provided for @devToneBanner.
  ///
  /// In pl, this message translates to:
  /// **'Wersja robocza: odtwarzany jest dźwięk testowy. Prawdziwe nagrania pojawią się po dostarczeniu plików.'**
  String get devToneBanner;

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
