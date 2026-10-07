import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/library_filter.dart';
import 'package:flutter_test/flutter_test.dart';

ContentItem item(String id, {String? pack, int age = 3, List<Situation> situations = const []}) =>
    ContentItem(
      id: id,
      kind: ContentKind.audioGame,
      packId: pack,
      title: id,
      parentDescription: '',
      ageMin: age,
      durationSec: 60,
      access: ContentAccess.paid,
      audio: const [],
      situations: situations,
    );

void main() {
  test('query round trip', () {
    const filter = LibraryFilter(
      kind: ContentKind.song,
      packId: 'detektyw',
      age: 6,
      situation: Situation.przedSnem,
    );
    final parsed = LibraryFilter.fromQuery(Uri.parse(filter.toLocation()).queryParameters);
    expect(parsed.toQuery(), filter.toQuery());
    expect(filter.toQuery()['sytuacja'], 'przed_snem');
  });

  test('empty filter links to the plain library', () {
    expect(const LibraryFilter().toLocation(), '/biblioteka');
  });

  test('unknown query values are ignored', () {
    expect(LibraryFilter.fromQuery({'typ': 'xyz', 'wiek': 'abc'}).isEmpty, isTrue);
  });

  test('age shows everything suitable up to that age', () {
    final items = [item('a', age: 3), item('b', age: 6)];
    expect(const LibraryFilter(age: 3).apply(items).map((i) => i.id), ['a']);
    expect(const LibraryFilter(age: 6).apply(items).map((i) => i.id), ['a', 'b']);
  });

  test('filters combine', () {
    final items = [
      item('a', pack: 'wyobraznia', situations: [Situation.podroz]),
      item('b', pack: 'wyobraznia'),
      item('c', pack: 'detektyw', situations: [Situation.podroz]),
    ];
    final result = const LibraryFilter(packId: 'wyobraznia', situation: Situation.podroz).apply(items);
    expect(result.map((i) => i.id), ['a']);
  });
}
