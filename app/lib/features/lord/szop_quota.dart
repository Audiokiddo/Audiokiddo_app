import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../catalog/catalog_providers.dart' show clockProvider;

/// How many times a day Szop’en may speak up by himself outside a play: the greeting when the
/// app opens and his line on Start. Funny once, tiring the fifth time (parent review,
/// 2026-10-18). A tap on him always answers; plays and their comments do not count.
const szopDailyLimit = 2;

const _key = 'szop_said_today';

class SzopQuota {
  SzopQuota(this._ref);

  final Ref _ref;

  /// True, and counted, when he may still speak today.
  Future<bool> take() async {
    final db = _ref.read(databaseProvider);
    final now = _ref.read(clockProvider)();
    final today = '${now.year}-${now.month}-${now.day}';
    final saved = (await db.readValue(_key))?.split('|');
    final said = saved != null && saved.length == 2 && saved[0] == today ? int.tryParse(saved[1]) ?? 0 : 0;
    if (said >= szopDailyLimit) return false;
    await db.writeValue(_key, '$today|${said + 1}');
    return true;
  }
}

final szopQuotaProvider = Provider<SzopQuota>(SzopQuota.new);
