import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/player/car_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = parseCatalog(
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
  ).catalog;

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

  group('CarPlay tabs', () {
    test('four tabs at most, in order, only plays the family may play', () {
      final tabs = carPlayTabs(catalog, canPlay: (_) => true, recent: [catalog.items.first.id]);
      expect(tabs.length, lessThanOrEqualTo(4));
      expect(tabs.map((t) => t.title), containsAllInOrder(['Na drogę', 'Pakiety', 'Więcej']));
      final free = carPlayTabs(catalog, canPlay: (i) => i.isFree);
      for (final tab in free) {
        for (final (_, rows) in tab.sections) {
          for (final row in rows) {
            for (final r in [row, ...?row.children]) {
              if (r.item != null) expect(r.item!.isFree, isTrue, reason: r.title);
            }
          }
        }
      }
    });

    test('each pack opens its own plays; games that need the phone stay out', () {
      final packs = carPlayTabs(catalog, canPlay: (_) => true).firstWhere((t) => t.title == 'Pakiety');
      final rows = packs.sections.first.$2;
      expect(rows, isNotEmpty);
      for (final pack in rows) {
        expect(pack.children, isNotEmpty);
        final packId = pack.id.substring('pack:'.length);
        expect(pack.children!.every((c) => c.item!.packId == packId), isTrue);
        expect(pack.children!.any((c) => c.item!.kind == ContentKind.interactiveGame), isFalse);
      }
    });

    test('recent plays show how far the family got', () {
      final item = catalog.items.firstWhere((i) => i.audio.isNotEmpty && i.kind != ContentKind.interactiveGame);
      final tabs = carPlayTabs(
        catalog,
        canPlay: (_) => true,
        recent: [item.id],
        progress: {item.id: (positionMs: 60000, durationMs: 240000, completed: false)},
      );
      final row = tabs.firstWhere((t) => t.title == 'Ostatnie').sections.first.$2.single;
      expect(row.progress, closeTo(.25, .001));
      expect(row.detail, 'Zostało 3 min');
    });

    test('a tab with nothing in it is left out', () {
      final tabs = carPlayTabs(catalog, canPlay: (_) => true);
      expect(tabs.any((t) => t.title == 'Ostatnie'), isFalse);
    });
  });
}
