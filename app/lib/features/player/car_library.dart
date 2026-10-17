import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access/access_controller.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_art.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart';
import '../personal/personal_repository.dart';
import 'playback_controller.dart';
import 'player_providers.dart';

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
      if (i.kind != ContentKind.interactiveGame && i.audio.isNotEmpty && canPlay(i) && (age == null || i.ageMin <= age))
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

/// One row on the CarPlay screen: a play (tap plays it) or a pack (tap opens its plays).
class CarRow {
  const CarRow({required this.id, required this.title, this.detail, this.item, this.children, this.progress});

  final String id;
  final String title;
  final String? detail;

  /// The play behind the row (its cover is looked up when the tabs are sent), null for a pack.
  final ContentItem? item;
  final List<CarRow>? children;

  /// How far the family got (0–1), shown as a bar on the row.
  final double? progress;
}

/// A tab on the CarPlay screen: a title, an SF Symbol and sections of rows.
class CarTab {
  const CarTab(this.title, this.symbol, this.sections);

  final String title;
  final String symbol;
  final List<(String?, List<CarRow>)> sections;

  bool get isEmpty => sections.every((s) => s.$2.isEmpty);
}

String _minutes(ContentItem i) => '${(i.durationSec / 60).ceil()} min';

CarRow _row(ContentItem i, {String? detail, double? progress}) =>
    CarRow(id: i.id, title: i.title, detail: detail ?? _minutes(i), item: i, progress: progress);

/// The CarPlay tabs (at most four, CarPlay's limit for audio apps): the trip shelf, what the
/// family listened to lately (with how far), the packs (each opens its plays) and more (songs,
/// bedtime, downloaded). Only what this family may play. Pure, so it is testable.
List<CarTab> carPlayTabs(
  Catalog catalog, {
  required bool Function(ContentItem) canPlay,
  Set<String> downloaded = const {},
  int? age,
  List<String> recent = const [],
  Map<String, ({int positionMs, int durationMs, bool completed})> progress = const {},
}) {
  final shelves = carShelves(catalog, canPlay: canPlay, downloaded: downloaded, age: age);
  final listenable = {for (final list in shelves.values) ...list};
  bool fits(ContentItem i) =>
      i.kind != ContentKind.interactiveGame && i.audio.isNotEmpty && canPlay(i) && (age == null || i.ageMin <= age);
  final lately = <CarRow>[
    for (final id in recent)
      if (catalog.item(id) case final i? when fits(i))
        switch (progress[id]) {
          final p? when p.completed => _row(i, detail: 'Wysłuchane · ${_minutes(i)}', progress: 1),
          final p? when p.durationMs > 0 && p.positionMs > 0 => _row(
            i,
            detail: 'Zostało ${((p.durationMs - p.positionMs).clamp(0, p.durationMs) / 60000).ceil()} min',
            progress: (p.positionMs / p.durationMs).clamp(0.0, 1.0),
          ),
          _ => _row(i),
        },
  ];
  final packs = <CarRow>[
    for (final pack in catalog.packs)
      if ([
        for (final i in catalog.items)
          if (i.packId == pack.id && fits(i)) i,
      ] case final plays when plays.isNotEmpty)
        CarRow(
          id: 'pack:${pack.id}',
          title: pack.title,
          detail: plays.length == 1 ? '1 zabawa' : '${plays.length} zabaw',
          item: plays.first,
          children: [for (final i in plays) _row(i)],
        ),
  ];
  final loose = [
    for (final i in catalog.items)
      if (i.packId == null && fits(i) && i.kind != ContentKind.song) _row(i),
  ];
  return [
    CarTab('Na drogę', 'car.fill', [(null, [for (final i in shelves[CarShelf.trip]!) _row(i)])]),
    CarTab('Ostatnie', 'clock.fill', [(null, lately)]),
    CarTab('Pakiety', 'square.stack.fill', [(null, packs), ('Na start', loose)]),
    CarTab('Więcej', 'music.note.list', [
      ('Piosenki', [for (final i in shelves[CarShelf.songs]!) _row(i)]),
      ('Na dobranoc', [for (final i in shelves[CarShelf.bedtime]!) _row(i)]),
      ('Pobrane', [for (final i in shelves[CarShelf.downloaded]!) _row(i)]),
    ]),
  ].where((t) => !t.isEmpty || listenable.isEmpty).toList();
}

/// Answers Android Auto's browse and play requests from the app's providers.
class CarLibrary {
  CarLibrary(this._container);

  final ProviderContainer _container;

  /// In the car the plays are for everyone: with siblings, the youngest child's age.
  int? _youngest() {
    final children = _container.read(familyProvider).value?.children ?? const [];
    return children.isEmpty ? null : children.map((c) => c.age).reduce((a, b) => a < b ? a : b);
  }

  Future<Map<CarShelf, List<ContentItem>>> _shelves() async {
    final catalog = await _container.read(catalogProvider.future);
    final downloaded = {...?_container.read(downloadSummaryProvider).value?.itemIds};
    final age = _youngest();
    return carShelves(catalog, canPlay: (i) => _container.read(canPlayProvider(i)), downloaded: downloaded, age: age);
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

  /// The CarPlay screen as plain data for ios/Runner/SceneDelegate.swift: the tabs, which play
  /// is on and whether it loops. Covers go as local files (CarPlay shows only local pictures).
  Future<Map<String, Object?>> carPlayLibrary() async {
    final catalog = await _container.read(catalogProvider.future);
    final downloaded = {...?_container.read(downloadSummaryProvider).value?.itemIds};
    final age = _youngest();
    final recent = await _container.read(recentProvider.future).catchError((Object _) => const <String>[]);
    final repo = _container.read(personalRepositoryProvider);
    final progress = {
      for (final id in recent)
        if (await repo.progress(id) case final p?)
          id: (positionMs: p.positionMs, durationMs: p.durationMs, completed: p.completed),
    };
    final tabs = carPlayTabs(
      catalog,
      canPlay: (i) => _container.read(canPlayProvider(i)),
      downloaded: downloaded,
      age: age,
      recent: recent,
      progress: progress,
    );
    final handler = _container.read(audioHandlerProvider);
    return {
      'tabs': [
        for (final tab in tabs)
          {
            'title': tab.title,
            'symbol': tab.symbol,
            'sections': [
              for (final (title, rows) in tab.sections)
                if (rows.isNotEmpty) {'title': title, 'rows': [for (final r in rows) await _rowData(r)]},
            ],
          },
      ],
      'playing': handler.mediaItem.value?.id,
      'looping': handler.looping,
    };
  }

  Future<Map<String, Object?>> _rowData(CarRow row) async => {
    'id': row.id,
    'title': row.title,
    'detail': row.detail,
    'progress': row.progress,
    'image': switch (row.item == null ? null : await coverArtUri(row.item!)) {
      final uri? when uri.scheme == 'file' => uri.toFilePath(),
      _ => null,
    },
    if (row.children != null) 'rows': [for (final c in row.children!) await _rowData(c)],
  };

  /// The loop button on CarPlay's Now Playing screen.
  Future<bool> toggleLoop() async {
    final handler = _container.read(audioHandlerProvider);
    await handler.setLooping(!handler.looping);
    return handler.looping;
  }

  Future<void> play(String itemId) async {
    final catalog = await _container.read(catalogProvider.future);
    final item = catalog.item(itemId);
    if (item == null || !_container.read(canPlayProvider(item))) return;
    await _container.read(playbackControllerProvider).start(item, album: 'AudioKiddo');
  }
}

/// Calls [reload] (at most every two seconds) when CarPlay's lists may have changed: the
/// catalog, what the family may play, downloads, the active child, the play that is on or the
/// loop. Without a car nobody listens on the other side, so the call costs nothing.
void watchCarPlayChanges(ProviderContainer container, void Function() reload) {
  Timer? pending;
  void soon() {
    pending?.cancel();
    pending = Timer(const Duration(seconds: 2), reload);
  }

  container
    ..listen(catalogProvider, (_, _) => soon())
    ..listen(accessProvider, (_, _) => soon())
    ..listen(downloadSummaryProvider, (_, _) => soon())
    ..listen(familyProvider, (_, _) => soon())
    ..listen(recentProvider, (_, _) => soon());
  final handler = container.read(audioHandlerProvider);
  handler.mediaItem.map((m) => m?.id).distinct().listen((_) => soon());
  handler.playbackState.map((s) => s.repeatMode).distinct().listen((_) => soon());
}
