import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/library_filter.dart';
import 'package:audiokiddo/features/player/szop_after_play.dart';
import 'package:flutter_test/flutter_test.dart';

Catalog loadCatalog() =>
    parseCatalog(jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>)
        .catalog;

void main() {
  final catalog = loadCatalog();

  test('only the Detektyw case files are printables (no films or other files since 2026-10-14)', () {
    final printable = const LibraryFilter(printable: true).apply(catalog.items);
    expect(printable, isNotEmpty);
    expect(printable.every((i) => i.packId == 'detektyw'), isTrue);
  });

  test('Szop’en after a play: a fitting tip often, never the same line twice in a row', () {
    final song = catalog.items.firstWhere(
      (i) => i.kind == ContentKind.song,
      orElse: () => catalog.items.first,
    );
    final random = math.Random(1);
    SzopLine? previous;
    for (var n = 0; n < 50; n++) {
      final line = pickSzopAfterPlay(song, random, previous: previous);
      expect(line, isNot(previous));
      expect(szopAfterPlayPool(song), contains(line));
      previous = line;
    }
  });

  test('library shortcuts: nothing to prepare, and printables', () {
    final noPrep = const LibraryFilter(noPrep: true).apply(catalog.items);
    expect(noPrep.every((i) => i.requirements.isEmpty), isTrue);
    final printable = const LibraryFilter(printable: true).apply(catalog.items);
    expect(printable, isNotEmpty);
    expect(
      printable.every((i) => i.pdf.isNotEmpty || i.requirements.contains(Requirement.wydrukPdf)),
      isTrue,
    );
    final parsed = LibraryFilter.fromQuery(
      Uri.parse(const LibraryFilter(noPrep: true, available: true).toLocation()).queryParameters,
    );
    expect(parsed.noPrep && parsed.available, isTrue);
  });
}
