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
  String get kindInteractiveGame => 'Gry';

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
  String get unlockComingSoon => 'Zakupy i subskrypcja pojawią się w kolejnym etapie prac.';

  @override
  String get devToneBanner =>
      'Wersja robocza: odtwarzany jest dźwięk testowy. Prawdziwe nagrania pojawią się po dostarczeniu plików.';

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
}
