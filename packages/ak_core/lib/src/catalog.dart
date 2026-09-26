import 'content.dart';
import 'json.dart';
import 'script/model.dart';
import 'script/validator.dart';

/// Supported `schema_version` of the catalog manifest.
const int catalogSchemaVersion = 1;

enum ShelfKind { featured, row, ageGroups, situations }

class Shelf {
  const Shelf({required this.id, required this.title, required this.kind, required this.itemIds});

  factory Shelf.fromJson(JsonReader r) => Shelf(
    id: r.string('id'),
    title: r.string('title'),
    kind: r.enumValue('kind', ShelfKind.values),
    itemIds: r.strings('item_ids'),
  );

  final String id;
  final String title;
  final ShelfKind kind;
  final List<String> itemIds;
}

class Catalog {
  const Catalog({required this.version, required this.packs, required this.items, required this.shelves});

  final int version;
  final List<Pack> packs;
  final List<ContentItem> items;

  /// Editorial shelves; ids of hidden or broken items are already removed.
  final List<Shelf> shelves;

  ContentItem? item(String id) => items.where((i) => i.id == id).firstOrNull;
  Pack? pack(String id) => packs.where((p) => p.id == id).firstOrNull;
  List<ContentItem> itemsInPack(String packId) => items.where((i) => i.packId == packId).toList();
}

/// A catalog item that was skipped, with the reason (logged, shown in Studio).
class SkippedItem {
  const SkippedItem(this.path, this.reason);

  final String path;
  final String reason;

  @override
  String toString() => '$path: $reason';
}

class CatalogParseResult {
  const CatalogParseResult(this.catalog, this.skipped);

  final Catalog catalog;
  final List<SkippedItem> skipped;
}

/// Parses a catalog manifest.
///
/// A broken manifest as a whole (wrong schema, missing lists) throws [FormatError] so the
/// caller keeps the last good catalog. A single broken or too-new item is skipped and
/// reported; the rest of the library keeps working.
CatalogParseResult parseCatalog(Map<String, Object?> json, {int engine = engineVersion}) {
  final root = JsonReader(json);
  final schema = root.integer('schema_version');
  if (schema != catalogSchemaVersion) {
    throw FormatError(r'$.schema_version', 'unsupported catalog schema $schema');
  }

  final skipped = <SkippedItem>[];

  final packs = <Pack>[];
  for (final (i, raw) in root.list('packs').indexed) {
    try {
      packs.add(
        Pack.fromJson(
          JsonReader.of(
            raw,
            r'$.packs'
            '[$i]',
          ),
        ),
      );
    } on FormatError catch (e) {
      skipped.add(SkippedItem(e.path, e.message));
    }
  }

  final items = <ContentItem>[];
  final seenIds = <String>{};
  for (final (i, raw) in root.list('items').indexed) {
    final path =
        r'$.items'
        '[$i]';
    try {
      final item = ContentItem.fromJson(JsonReader.of(raw, path));
      final problem = _itemProblem(item, packs, seenIds, engine);
      if (problem != null) {
        skipped.add(SkippedItem('$path (${item.id})', problem));
        continue;
      }
      seenIds.add(item.id);
      items.add(item);
    } on FormatError catch (e) {
      skipped.add(SkippedItem(e.path, e.message));
    }
  }

  final shelves = <Shelf>[];
  for (final (i, raw) in root.list('shelves').indexed) {
    try {
      final shelf = Shelf.fromJson(
        JsonReader.of(
          raw,
          r'$.shelves'
          '[$i]',
        ),
      );
      shelves.add(
        Shelf(
          id: shelf.id,
          title: shelf.title,
          kind: shelf.kind,
          itemIds: shelf.itemIds.where(seenIds.contains).toList(),
        ),
      );
    } on FormatError catch (e) {
      skipped.add(SkippedItem(e.path, e.message));
    }
  }

  return CatalogParseResult(
    Catalog(
      version: root.integer('version', min: 1),
      packs: List.unmodifiable(packs),
      items: List.unmodifiable(items),
      shelves: List.unmodifiable(shelves),
    ),
    skipped,
  );
}

String? _itemProblem(ContentItem item, List<Pack> packs, Set<String> seenIds, int engine) {
  if (seenIds.contains(item.id)) return 'duplicate id';
  if (item.packId != null && !packs.any((p) => p.id == item.packId)) {
    return 'unknown pack "${item.packId}"';
  }
  if (item.minEngineVersion > engine) return 'needs a newer app (engine ${item.minEngineVersion})';
  if (item.kind != ContentKind.interactiveGame && item.audio.isEmpty) return 'no audio file';
  final script = item.script;
  if (script != null) {
    final validation = validateScript(script, engine: engine);
    if (!validation.isValid) return 'invalid script: ${validation.errors.first}';
  }
  return null;
}
