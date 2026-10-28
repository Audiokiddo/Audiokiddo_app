import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';

/// Where to resume an item: from the start when it was finished, barely started or
/// almost done; otherwise a few seconds before the saved point so the child re-hears
/// the last sentence.
Duration resumePosition(PlaybackProgressData? progress) {
  if (progress == null || progress.completed) return Duration.zero;
  final position = Duration(milliseconds: progress.positionMs);
  final duration = Duration(milliseconds: progress.durationMs);
  if (position < const Duration(seconds: 10)) return Duration.zero;
  if (duration > Duration.zero && duration - position < const Duration(seconds: 15)) return Duration.zero;
  return position - const Duration(seconds: 3);
}

/// Favourites, listening progress and history. Local only (ARCHITECTURE D5).
class PersonalRepository {
  PersonalRepository(this._db);

  final AppDatabase _db;

  Stream<Set<String>> watchFavorites() =>
      _db.select(_db.favorites).watch().map((rows) => {for (final r in rows) r.itemId});

  Stream<List<String>> watchFavoritesOrdered() => (_db.select(
    _db.favorites,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch().map((rows) => [for (final r in rows) r.itemId]);

  Future<void> setFavorite(String itemId, {required bool favorite}) async {
    if (favorite) {
      await _db
          .into(_db.favorites)
          .insertOnConflictUpdate(FavoritesCompanion.insert(itemId: itemId, createdAt: DateTime.now()));
    } else {
      await (_db.delete(_db.favorites)..where((t) => t.itemId.equals(itemId))).go();
    }
  }

  Stream<PlaybackProgressData?> watchProgress(String itemId) =>
      (_db.select(_db.playbackProgress)..where((t) => t.itemId.equals(itemId))).watchSingleOrNull();

  Future<PlaybackProgressData?> progress(String itemId) =>
      (_db.select(_db.playbackProgress)..where((t) => t.itemId.equals(itemId))).getSingleOrNull();

  /// Most recently played first.
  Stream<List<String>> watchRecent({int limit = 12}) =>
      (_db.select(_db.playbackProgress)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(limit))
          .watch()
          .map((rows) => [for (final r in rows) r.itemId]);

  Future<void> saveProgress(
    String itemId, {
    required Duration position,
    required Duration duration,
    bool completed = false,
  }) => _db
      .into(_db.playbackProgress)
      .insertOnConflictUpdate(
        PlaybackProgressCompanion.insert(
          itemId: itemId,
          positionMs: position.inMilliseconds,
          durationMs: duration.inMilliseconds,
          completed: Value(completed),
          updatedAt: DateTime.now(),
        ),
      );
}

final personalRepositoryProvider = Provider<PersonalRepository>(
  (ref) => PersonalRepository(ref.watch(databaseProvider)),
);

final favoritesProvider = StreamProvider<Set<String>>((ref) => ref.watch(personalRepositoryProvider).watchFavorites());

final favoritesOrderedProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(personalRepositoryProvider).watchFavoritesOrdered(),
);

final recentProvider = StreamProvider<List<String>>((ref) => ref.watch(personalRepositoryProvider).watchRecent());

final progressProvider = StreamProvider.family<PlaybackProgressData?, String>(
  (ref, itemId) => ref.watch(personalRepositoryProvider).watchProgress(itemId),
);
