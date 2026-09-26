import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Tests override this with an in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
