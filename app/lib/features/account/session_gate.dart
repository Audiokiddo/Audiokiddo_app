import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';

/// After the parent signs out on purpose, the app shows the sign-in screen until they sign in
/// again or choose to continue without an account. Loaded before the first frame.
class SessionGate extends ChangeNotifier {
  SessionGate(this._db);

  static const _key = 'signed_out';
  final AppDatabase _db;
  bool _signedOut = false;

  bool get signedOut => _signedOut;

  Future<void> load() async {
    _signedOut = await _db.readValue(_key) == '1';
    notifyListeners();
  }

  Future<void> markSignedOut() => _set(true);

  /// Signed in again, or continuing without an account (free plays only).
  Future<void> clear() => _set(false);

  Future<void> _set(bool value) async {
    if (_signedOut == value) return;
    await _db.writeValue(_key, value ? '1' : '0');
    _signedOut = value;
    notifyListeners();
  }
}

/// Overridden in `main` with a loaded gate; tests get a fresh one (not signed out).
final sessionGateProvider = Provider<SessionGate>((ref) => SessionGate(ref.watch(databaseProvider)));
