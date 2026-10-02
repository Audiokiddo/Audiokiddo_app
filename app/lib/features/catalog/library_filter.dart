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
  });

  factory LibraryFilter.fromQuery(Map<String, String> query) => LibraryFilter(
    ageFrom: int.tryParse(query['wiek_od'] ?? ''),
    category: PlayCategory.values.where((c) => c.name == query['kategoria']).firstOrNull,
    maxMinutes: int.tryParse(query['minuty'] ?? ''),
    kind: _enumFromWire(query['typ'], ContentKind.values),
    packId: query['pakiet'],
    age: int.tryParse(query['wiek'] ?? ''),
    situation: _enumFromWire(query['sytuacja'], Situation.values),
  );

  final PlayCategory? category;
  final int? maxMinutes;
  final ContentKind? kind;
  final String? packId;

  /// Child's age: shows everything suitable from this age down.
  final int? age;
  final int? ageFrom;
  final Situation? situation;

  bool get isEmpty =>
      kind == null &&
      packId == null &&
      age == null &&
      situation == null &&
      category == null &&
      maxMinutes == null;

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
  }) => LibraryFilter(
    category: category == null ? this.category : category(),
    maxMinutes: maxMinutes == null ? this.maxMinutes : maxMinutes(),
    kind: kind == null ? this.kind : kind(),
    packId: packId == null ? this.packId : packId(),
    age: age == null ? this.age : age(),
    ageFrom: ageFrom == null ? this.ageFrom : ageFrom(),
    situation: situation == null ? this.situation : situation(),
  );

  List<ContentItem> apply(Iterable<ContentItem> items) => items
      .where(
        (i) =>
            (category == null || category!.matches(i)) &&
            (maxMinutes == null || i.durationSec <= maxMinutes! * 60) &&
            (kind == null || i.kind == kind) &&
            (packId == null || i.packId == packId) &&
            (age == null || (i.ageMin <= age! && (i.ageMax == null || i.ageMax! >= (ageFrom ?? age!)))) &&
            (situation == null || i.situations.contains(situation)),
      )
      .toList();
}

T? _enumFromWire<T extends Enum>(String? raw, List<T> values) =>
    raw == null ? null : values.where((v) => wireName(v) == raw).firstOrNull;
