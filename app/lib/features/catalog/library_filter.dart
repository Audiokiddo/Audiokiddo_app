import 'package:ak_core/ak_core.dart';

/// Library filters, stored in the URL so Home shortcuts can deep-link into the library.
class LibraryFilter {
  const LibraryFilter({this.kind, this.packId, this.age, this.situation});

  factory LibraryFilter.fromQuery(Map<String, String> query) => LibraryFilter(
    kind: _enumFromWire(query['typ'], ContentKind.values),
    packId: query['pakiet'],
    age: int.tryParse(query['wiek'] ?? ''),
    situation: _enumFromWire(query['sytuacja'], Situation.values),
  );

  final ContentKind? kind;
  final String? packId;

  /// Child's age: shows everything suitable from this age down.
  final int? age;
  final Situation? situation;

  bool get isEmpty => kind == null && packId == null && age == null && situation == null;

  /// Filters behind the "Filtry" button (all but the type row).
  int get extraCount => [packId, age, situation].where((f) => f != null).length;

  Map<String, String> toQuery() => {
    if (kind != null) 'typ': wireName(kind!),
    'pakiet': ?packId,
    if (age != null) 'wiek': '$age',
    if (situation != null) 'sytuacja': wireName(situation!),
  };

  String toLocation() => Uri(path: '/biblioteka', queryParameters: isEmpty ? null : toQuery()).toString();

  LibraryFilter copyWith({
    ContentKind? Function()? kind,
    String? Function()? packId,
    int? Function()? age,
    Situation? Function()? situation,
  }) => LibraryFilter(
    kind: kind == null ? this.kind : kind(),
    packId: packId == null ? this.packId : packId(),
    age: age == null ? this.age : age(),
    situation: situation == null ? this.situation : situation(),
  );

  List<ContentItem> apply(Iterable<ContentItem> items) => items
      .where(
        (i) =>
            (kind == null || i.kind == kind) &&
            (packId == null || i.packId == packId) &&
            (age == null || i.ageMin <= age!) &&
            (situation == null || i.situations.contains(situation)),
      )
      .toList();
}

T? _enumFromWire<T extends Enum>(String? raw, List<T> values) =>
    raw == null ? null : values.where((v) => wireName(v) == raw).firstOrNull;
