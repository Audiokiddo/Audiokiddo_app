import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/widgets/item_art.dart';
import 'package:audiokiddo/features/discovery/reference_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = parseCatalog(
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
  ).catalog;
  final files = Directory('assets/covers').listSync().whereType<File>().where((f) => f.path.endsWith('.jpg'));

  test('every pack has a guide and every Detektyw play has its case file', () {
    for (final pack in catalog.packs) {
      expect(pack.guide?.path, 'pdf/${pack.id}/przewodnik.pdf', reason: pack.id);
    }
    for (final item in catalog.itemsInPack('detektyw')) {
      expect(item.pdf.single.path, 'pdf/detektyw/${item.id}.pdf');
      expect(item.pdf.single.bytes, greaterThan(500 * 1024), reason: '${item.id} is a real case file');
    }
  });

  test('every cover file belongs to a play and is a square of the agreed size', () async {
    expect(files, isNotEmpty);
    for (final file in files) {
      final id = file.uri.pathSegments.last.replaceAll('.jpg', '');
      expect(catalog.item(id), isNotNull, reason: '${file.path} has no play in the catalog');
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final frame = (await codec.getNextFrame()).image;
      expect((frame.width, frame.height), (900, 900), reason: id);
      expect(file.lengthSync(), lessThan(250 * 1024), reason: '$id is too heavy for a list');
    }
  });

  testWidgets('a play with a cover shows the picture, one without shows the drawn scene', (tester) async {
    final withCover = catalog.item('znikajace-dzwonki')!;
    final without = catalog.item('mikstura')!;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Column(
            children: [
              SizedBox.square(dimension: 120, child: ItemArt(item: withCover)),
              SizedBox.square(dimension: 120, child: ItemArt(item: without)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ArtScene), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as ResizeImage).width,
      lessThanOrEqualTo(900),
      reason: 'decoded no bigger than needed',
    );
  });

  test('cover art for the lock screen never breaks playback: no cover means no art, no error', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final without = catalog.item('mikstura')!;
    expect(await coverArtUri(without), isNull);
    // With a cover the platform may be unable to write a file (tests): still no exception.
    await coverArtUri(catalog.item('znikajace-dzwonki')!);
  });

  testWidgets('a pack with several covers shows them as a mosaic', (tester) async {
    final detective = catalog.itemsInPack('detektyw');
    expect(
      detective.where((i) => File('assets/covers/${i.id}.jpg').existsSync()).length,
      greaterThanOrEqualTo(4),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Column(
            children: [
              for (final i in detective)
                Consumer(builder: (context, ref, _) => Text('${i.id}:${ref.watch(hasCoverProvider(i))}')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('zlodziej-naszyjnika:true'), findsOneWidget);
    expect(find.text('znikajace-dzwonki:true'), findsOneWidget);
  });
}
