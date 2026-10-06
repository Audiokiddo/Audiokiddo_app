import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/player/car_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = parseCatalog(jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>)
      .catalog;

  test('car shelves hold only listening the family may play', () {
    final shelves = carShelves(catalog, canPlay: (i) => i.isFree);
    for (final items in shelves.values) {
      expect(items.every((i) => i.isFree && i.kind != ContentKind.interactiveGame), isTrue);
    }
    expect(shelves[CarShelf.downloaded], isEmpty);
  });

  test('downloaded items come first on the trip shelf', () {
    final trip = carShelves(catalog, canPlay: (_) => true)[CarShelf.trip]!;
    expect(trip, isNotEmpty);
    final last = trip.last;
    final sorted = carShelves(catalog, canPlay: (_) => true, downloaded: {last.id})[CarShelf.trip]!;
    expect(sorted.first.id, last.id);
  });

  test('age limits what the car shows', () {
    final young = carShelves(catalog, canPlay: (_) => true, age: 3);
    for (final items in young.values) {
      expect(items.every((i) => i.ageMin <= 3), isTrue);
    }
  });
}
