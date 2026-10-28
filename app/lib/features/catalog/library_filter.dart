import 'package:ak_core/ak_core.dart';

import '../discovery/discovery_model.dart';

/// Library filters, stored in the URL so Home shortcuts can deep-link into the library.
class LibraryFilter {
  const LibraryFilter({
    this.kind,
    this.packId,
    this.age,
    this.situation,
    this.category,
    this.maxMinutes,
    this.ageFrom,
    this.noPrep = false,
    this.printable = false,
    this.available = false,
  });

  factory LibraryFilter.fromQuery(Map<String, String> query) => LibraryFilter(
    ageFrom: int.tryParse(query['wiek_od'] ?? ''),
    category: PlayCategory.values.where((c) => c.name == query['kategoria']).firstOrNull,
    maxMinutes: int.tryParse(query['minuty'] ?? ''),
    kind: _enumFromWire(query['typ'], ContentKind.values),
    packId: query['pakiet'],
    age: int.tryParse(query['wiek'] ?? ''),
    situation: _enumFromWire(query['sytuacja'], Situation.values),
    noPrep: query['bez_przygotowan'] == '1',
    printable: query['do_druku'] == '1',
    available: query['dostepne'] == '1',
  );

  final PlayCategory? category;
  final int? maxMinutes;
  final ContentKind? kind;
  final String? packId;

  /// Child's age: shows everything suitable from this age down.
  final int? age;
  final int? ageFrom;
  final Situation? situation;

  /// Nothing to get ready: no microphone, space, pencil or print-out.
  final bool noPrep;

  /// Comes with something to print (case files, worksheets).
  final bool printable;

  /// Only what the family can play now (see [apply]).
  final bool available;

  bool get isEmpty =>
      kind == null &&
      packId == null &&
      age == null &&
      situation == null &&
      category == null &&
      maxMinutes == null &&
      !noPrep &&
      !printable &&
      !available;

  /// Filters behind the "Filtry" button (all but the type row).
  int get extraCount => [packId, age, situation].where((f) => f != null).length;

  Map<String, String> toQuery() => {
    if (category != null) 'kategoria': category!.name,
    if (maxMinutes != null) 'minuty': '$maxMinutes',
    if (kind != null) 'typ': wireName(kind!),
    'pakiet': ?packId,
    if (age != null) 'wiek': '$age',
    if (ageFrom != null) 'wiek_od': '$ageFrom',
    if (situation != null) 'sytuacja': wireName(situation!),
    if (noPrep) 'bez_przygotowan': '1',
    if (printable) 'do_druku': '1',
    if (available) 'dostepne': '1',
  };

  String toLocation() => Uri(path: '/biblioteka', queryParameters: isEmpty ? null : toQuery()).toString();

  LibraryFilter copyWith({
    PlayCategory? Function()? category,
    int? Function()? maxMinutes,
    ContentKind? Function()? kind,
    String? Function()? packId,
    int? Function()? age,
    int? Function()? ageFrom,
    Situation? Function()? situation,
    bool? noPrep,
    bool? printable,
    bool? available,
  }) => LibraryFilter(
    category: category == null ? this.category : category(),
    maxMinutes: maxMinutes == null ? this.maxMinutes : maxMinutes(),
    kind: kind == null ? this.kind : kind(),
    packId: packId == null ? this.packId : packId(),
    age: age == null ? this.age : age(),
    ageFrom: ageFrom == null ? this.ageFrom : ageFrom(),
    situation: situation == null ? this.situation : situation(),
    noPrep: noPrep ?? this.noPrep,
    printable: printable ?? this.printable,
    available: available ?? this.available,
  );

  /// [canPlay] decides [available]; without it that filter is not applied.
  List<ContentItem> apply(Iterable<ContentItem> items, {bool Function(ContentItem)? canPlay}) => items
      .where(
        (i) =>
            (category == null || category!.matches(i)) &&
            (maxMinutes == null || i.durationSec <= maxMinutes! * 60) &&
            (kind == null || i.kind == kind) &&
            (packId == null || i.packId == packId) &&
            (age == null || (i.ageMin <= age! && (i.ageMax == null || i.ageMax! >= (ageFrom ?? age!)))) &&
            (situation == null || i.situations.contains(situation)) &&
            (!noPrep || i.requirements.isEmpty) &&
            (!printable || i.pdf.isNotEmpty || i.requirements.contains(Requirement.wydrukPdf)) &&
            (!available || canPlay == null || canPlay(i)),
      )
      .toList();
}

T? _enumFromWire<T extends Enum>(String? raw, List<T> values) =>
    raw == null ? null : values.where((v) => wireName(v) == raw).firstOrNull;
