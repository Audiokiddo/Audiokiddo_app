import 'dart:async';
import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/database.dart';
import 'catalog_providers.dart';

/// The catalog published from Studio, with the last good copy kept on the phone. The app
/// starts with the saved copy (or the bundled one) at once; the server copy is fetched in
/// the background and, when it differs, saved and announced through [onChanged]. So new plays
/// reach families without an app update, and a slow network never delays the start.
class RemoteCatalogSource implements CatalogSource {
  RemoteCatalogSource(this._client, this._db, {this.fallback = const BundledCatalogSource()});

  final SupabaseClient _client;
  final AppDatabase _db;
  final CatalogSource fallback;

  /// Called after a newer server copy was saved (main.dart reloads the catalog).
  void Function()? onChanged;

  static const _cacheKey = 'catalog_cache';
  static const timeout = Duration(seconds: 8);
  bool _refreshing = false;

  @override
  Future<Map<String, Object?>> load() async {
    final saved = await _db.readValue(_cacheKey);
    if (!_refreshing) {
      _refreshing = true;
      unawaited(_refresh(saved).whenComplete(() => _refreshing = false));
    }
    if (saved != null) {
      try {
        final manifest = jsonDecode(saved) as Map<String, Object?>;
        if (_usable(manifest)) return manifest;
      } on Object {
        // A broken saved copy falls through to the bundled one.
      }
    }
    return fallback.load();
  }

  Future<void> _refresh(String? saved) async {
    try {
      final data = await _client.rpc<dynamic>('published_catalog').timeout(timeout);
      final manifest = data is Map ? data['manifest'] : null;
      if (manifest is! Map<String, Object?> || !_usable(manifest)) return;
      final raw = jsonEncode(manifest);
      if (raw == saved) return;
      await _db.writeValue(_cacheKey, raw);
      onChanged?.call();
    } on Object catch (e) {
      debugPrint('catalog: server copy not fetched ($e)');
    }
  }

  /// A manifest is used only when the app's own parser accepts it with items in it.
  static bool _usable(Map<String, Object?> manifest) {
    try {
      return parseCatalog(manifest).catalog.items.isNotEmpty;
    } on Object {
      return false;
    }
  }
}
