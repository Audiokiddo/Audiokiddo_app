import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Everything here stays on the device (ARCHITECTURE §6.2). No child data goes to the server.
class Favorites extends Table {
  TextColumn get itemId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}

class PlaybackProgress extends Table {
  TextColumn get itemId => text()();
  IntColumn get positionMs => integer()();
  IntColumn get durationMs => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId};
}

enum DownloadState { queued, running, verifying, ready, failed }

/// One row per downloaded file. Files are content-addressed: `<sha256>.<ext>`.
class Downloads extends Table {
  TextColumn get assetPath => text()();
  TextColumn get itemId => text()();
  TextColumn get sha256 => text()();
  IntColumn get bytes => integer()();
  TextColumn get fileName => text()();
  TextColumn get state => textEnum<DownloadState>()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {assetPath};
}

/// Small settings and state (offline lease, dev entitlement mode).
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Favorites, PlaybackProgress, Downloads, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'audiokiddo'));

  @override
  int get schemaVersion => 1;

  Future<String?> readValue(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writeValue(String key, String value) =>
      into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));

  Future<void> deleteValue(String key) => (delete(keyValues)..where((t) => t.key.equals(key))).go();

  /// Removes every value whose key starts with [prefix] (per-child and per-game entries).
  Future<void> deleteValuesStartingWith(String prefix) async {
    final keys = [
      for (final row in await select(keyValues).get())
        if (row.key.startsWith(prefix)) row.key,
    ];
    for (final key in keys) {
      await deleteValue(key);
    }
  }

  /// The family's own listening data: favourites and progress (downloads stay, they are
  /// governed by access).
  Future<void> clearListening() async {
    await delete(favorites).go();
    await delete(playbackProgress).go();
  }
}
