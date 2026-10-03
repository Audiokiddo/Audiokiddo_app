import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../discovery/reference_widgets.dart';

const _coversDir = 'assets/covers/';

Future<Set<String>>? _coverAssets;

/// Paths of the cover images bundled with the app, read once.
Future<Set<String>> bundledCovers() => _coverAssets ??= AssetManifest.loadFromAssetBundle(rootBundle).then(
  (manifest) => {
    for (final path in manifest.listAssets())
      if (path.startsWith(_coversDir)) path,
  },
);

/// Plays that have a real cover image bundled with the app (tool/import_covers.py).
final coverAssetsProvider = FutureProvider<Set<String>>((ref) => bundledCovers());

String coverAssetPath(String itemId) => '$_coversDir$itemId.jpg';

/// The cover of a whole pack (`assets/covers/pakiet-ID.jpg`).
String packCoverAssetPath(String packId) => '${_coversDir}pakiet-$packId.jpg';

/// Whether [packId] has its own cover image.
final hasPackCoverProvider = Provider.family<bool, String>(
  (ref, packId) => ref.watch(coverAssetsProvider).value?.contains(packCoverAssetPath(packId)) ?? false,
);

/// A bundled cover image, decoded no bigger than shown (a 56 px row does not hold 900 px).
class CoverImage extends StatelessWidget {
  const CoverImage({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final side = c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 200.0;
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          cacheWidth: (side * pixelRatio).round().clamp(64, 900),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
        );
      },
    );
  }
}

/// Whether [item] has a real cover (false until the manifest is read, so first frames show the
/// drawn placeholder and swap once).
final hasCoverProvider = Provider.family<bool, ContentItem>(
  (ref, item) => ref.watch(coverAssetsProvider).value?.contains(coverAssetPath(item.id)) ?? false,
);

/// The plays of [items] that have a cover, in the same order.
List<ContentItem> withCovers(WidgetRef ref, Iterable<ContentItem> items) => [
  for (final i in items)
    if (ref.watch(hasCoverProvider(i))) i,
];

/// A play's picture: its cover when there is one, otherwise the drawn scene of its category.
/// Fills its parent; covers are square, so the parent decides the shape (crops to fill).
class ItemArt extends ConsumerWidget {
  const ItemArt({super.key, required this.item, this.seed});

  final ContentItem item;
  final int? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasCoverProvider(item))) {
      return ArtScene(
        category: itemCategory(item),
        seed: seed ?? item.id.codeUnits.fold(0, (a, b) => a + b) % 5,
      );
    }
    return CoverImage(asset: coverAssetPath(item.id));
  }
}

/// A square cover (or placeholder) for headers: as wide as the screen allows, up to [maxWidth].
class ItemHeaderArt extends ConsumerWidget {
  const ItemHeaderArt({super.key, required this.item, this.maxWidth = 340, this.radius = 26, this.seed});

  final ContentItem item;
  final double maxWidth;
  final double radius;
  final int? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCover = ref.watch(hasCoverProvider(item));
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: hasCover ? maxWidth : double.infinity),
        child: AspectRatio(
          aspectRatio: hasCover ? 1 : 1.55,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ItemArt(item: item, seed: seed),
          ),
        ),
      ),
    );
  }
}

/// Lock-screen / Control Center / car artwork: the cover written once to a temporary file
/// (audio_service wants a file or a URL, not an asset). Null without a cover or when the
/// platform cannot write (tests).
Future<Uri?> coverArtUri(ContentItem item) async {
  try {
    // Asking the bundle for a file it does not have throws; playing must never depend on art.
    if (!(await bundledCovers()).contains(coverAssetPath(item.id))) return null;
    final data = await rootBundle.load(coverAssetPath(item.id));
    final file = File(p.join((await getTemporaryDirectory()).path, 'covers', '${item.id}.jpg'));
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
    return Uri.file(file.path);
  } on Object {
    return null;
  }
}
