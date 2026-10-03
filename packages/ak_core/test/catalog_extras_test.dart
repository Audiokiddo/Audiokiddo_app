import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

Map<String, Object?> catalogJson({
  Map<String, Object?> item = const {},
  Map<String, Object?> shelf = const {},
}) => {
  'schema_version': 1,
  'version': 1,
  'packs': [
    {'id': 'p', 'title': 'P', 'age_min': 3, 'color': 'teal', 'description': 'd', 'released': '2026-09-20'},
  ],
  'items': [
    {
      'id': 'a',
      'kind': 'audio_game',
      'pack_id': 'p',
      'title': 'A',
      'parent_description': 'x',
      'age_min': 3,
      'duration_sec': 300,
      'access': 'paid',
      'audio': [
        {'path': 'audio/p/a.m4a', 'bytes': 10, 'sha256': 'aa'},
      ],
      ...item,
    },
  ],
  'shelves': [
    {
      'id': 's',
      'title': 'S',
      'kind': 'row',
      'item_ids': ['a', 'gone'],
      ...shelf,
    },
  ],
};

void main() {
  test('release dates and previews are read; absent means none', () {
    final c = parseCatalog(
      catalogJson(
        item: {
          'released': '2026-09-27',
          'preview': {'path': 'previews/p/a.m4a', 'bytes': 5, 'sha256': 'bb'},
        },
      ),
    ).catalog;
    expect(c.items.single.releasedOn, DateTime(2026, 9, 27));
    expect(c.items.single.preview?.path, 'previews/p/a.m4a');
    expect(c.packs.single.releasedOn, DateTime(2026, 9, 20));
    final plain = parseCatalog(catalogJson()).catalog.items.single;
    expect(plain.releasedOn, isNull);
    expect(plain.preview, isNull);
  });

  test('a pack guide is optional and read like any asset', () {
    final json = catalogJson();
    (json['packs']! as List).cast<Map<String, Object?>>().single['guide'] = {
      'path': 'pdf/p/przewodnik.pdf',
      'bytes': 1000,
      'sha256': 'cc',
    };
    expect(parseCatalog(json).catalog.packs.single.guide?.path, 'pdf/p/przewodnik.pdf');
    expect(parseCatalog(catalogJson()).catalog.packs.single.guide, isNull);
  });

  test('a broken date skips the item, not the catalog', () {
    for (final bad in ['2026-02-30', '27.09.2026', '2026-9-7']) {
      final result = parseCatalog(catalogJson(item: {'released': bad}));
      expect(result.catalog.items, isEmpty, reason: bad);
      expect(result.skipped.single.reason, contains('YYYY-MM-DD'));
    }
  });

  test('new for 30 days after release, never before it', () {
    final released = DateTime(2026, 9, 27);
    expect(isNewAt(released, DateTime(2026, 9, 27)), isTrue);
    expect(isNewAt(released, DateTime(2026, 10, 26)), isTrue);
    expect(isNewAt(released, DateTime(2026, 10, 27)), isFalse);
    expect(isNewAt(released, DateTime(2026, 9, 26)), isFalse, reason: 'not out yet');
    expect(isNewAt(null, DateTime(2026, 9, 27)), isFalse);
  });

  test('seasonal shelves keep their window, also across New Year', () {
    final autumn = parseCatalog(
      catalogJson(shelf: {'subtitle': 'Ciepło', 'season_from': '10-01', 'season_to': '11-30'}),
    ).catalog.shelves.single;
    expect(autumn.subtitle, 'Ciepło');
    expect(autumn.itemIds, ['a'], reason: 'unknown items are still dropped');
    expect(autumn.inSeasonAt(DateTime(2026, 10, 1)), isTrue);
    expect(autumn.inSeasonAt(DateTime(2026, 11, 30)), isTrue);
    expect(autumn.inSeasonAt(DateTime(2026, 12, 1)), isFalse);

    final winter = Shelf(
      id: 'w',
      title: 'W',
      kind: ShelfKind.row,
      itemIds: const [],
      seasonFrom: '12-01',
      seasonTo: '02-28',
    );
    expect(winter.inSeasonAt(DateTime(2026, 12, 24)), isTrue);
    expect(winter.inSeasonAt(DateTime(2027, 1, 15)), isTrue);
    expect(winter.inSeasonAt(DateTime(2027, 3, 1)), isFalse);

    expect(parseCatalog(catalogJson()).catalog.shelves.single.inSeasonAt(DateTime(2026)), isTrue);
    expect(parseCatalog(catalogJson(shelf: {'season_from': '13-01'})).skipped, isNotEmpty);
  });
}
