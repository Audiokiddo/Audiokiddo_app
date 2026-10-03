import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_art.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart';
import 'playback_controller.dart';

/// Folders on the car screen (Android Auto), in this order.
enum CarShelf {
  trip('car:trip', 'Na drogę'),
  downloaded('car:downloaded', 'Pobrane'),
  songs('car:songs', 'Piosenki'),
  bedtime('car:bedtime', 'Na dobranoc');

  const CarShelf(this.id, this.title);

  final String id;
  final String title;
}

/// What each folder holds: only what this family may play, only listening (no games that
/// need the phone), travel and downloaded items first. Pure, so it is testable.
Map<CarShelf, List<ContentItem>> carShelves(
  Catalog catalog, {
  required bool Function(ContentItem) canPlay,
  Set<String> downloaded = const {},
  int? age,
}) {
  final listenable = [
    for (final i in catalog.items)
      if (i.kind != ContentKind.interactiveGame &&
          i.audio.isNotEmpty &&
          canPlay(i) &&
          (age == null || i.ageMin <= age))
        i,
  ];
  int downloadedFirst(ContentItem a, ContentItem b) =>
      (downloaded.contains(b.id) ? 1 : 0) - (downloaded.contains(a.id) ? 1 : 0);
  return {
    CarShelf.trip: [
      for (final i in listenable)
        if (i.situations.contains(Situation.podroz) && i.kind != ContentKind.song) i,
    ]..sort(downloadedFirst),
    CarShelf.downloaded: [
      for (final i in listenable)
        if (downloaded.contains(i.id)) i,
    ],
    CarShelf.songs: [
      for (final i in listenable)
        if (i.kind == ContentKind.song) i,
    ]..sort(downloadedFirst),
    CarShelf.bedtime: [
      for (final i in listenable)
        if (i.situations.contains(Situation.przedSnem)) i,
    ],
  };
}

/// Answers Android Auto's browse and play requests from the app's providers.
class CarLibrary {
  CarLibrary(this._container);

  final ProviderContainer _container;

  Future<Map<CarShelf, List<ContentItem>>> _shelves() async {
    final catalog = await _container.read(catalogProvider.future);
    final downloaded = {...?_container.read(downloadSummaryProvider).value?.itemIds};
    final age = _container.read(familyProvider).value?.active?.age;
    return carShelves(
      catalog,
      canPlay: (i) => _container.read(canPlayProvider(i)),
      downloaded: downloaded,
      age: age,
    );
  }

  Future<List<MediaItem>> children(String parentId) async {
    final shelves = await _shelves();
    if (parentId == AudioService.browsableRootId) {
      return [
        for (final shelf in CarShelf.values)
          if (shelves[shelf]!.isNotEmpty) MediaItem(id: shelf.id, title: shelf.title, playable: false),
      ];
    }
    final shelf = CarShelf.values.where((s) => s.id == parentId).firstOrNull;
    if (shelf == null) return const [];
    return [
      for (final item in shelves[shelf]!)
        MediaItem(
          id: item.id,
          title: item.title,
          album: 'AudioKiddo',
          artUri: await coverArtUri(item),
          duration: Duration(seconds: item.durationSec),
          playable: true,
        ),
    ];
  }

  Future<void> play(String itemId) async {
    final catalog = await _container.read(catalogProvider.future);
    final item = catalog.item(itemId);
    if (item == null || !_container.read(canPlayProvider(item))) return;
    await _container.read(playbackControllerProvider).start(item, album: 'AudioKiddo');
  }
}
