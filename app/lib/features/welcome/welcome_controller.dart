import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';

/// The welcome after a family's first sign-in (free plays, theme, the child, Szop’en's tour).
/// Its flag is family data, so a different account on the phone gets its own welcome.
class WelcomeController extends ChangeNotifier {
  WelcomeController(this._db, {bool done = true}) : _done = done; // ignore: prefer_initializing_formals

  static const key = 'welcome_done';
  final AppDatabase _db;
  bool _done;
  bool _tour = false;

  bool get done => _done;

  /// Szop’en's tour of the tabs waits on Start (right after the welcome, or asked for again).
  bool get tourPending => _tour;

  Future<void> load() async {
    _done = await _db.readValue(key) == 'true';
    notifyListeners();
  }

  Future<void> complete() async {
    await _db.writeValue(key, 'true');
    _done = true;
    _tour = true;
    notifyListeners();
  }

  void startTour() {
    _tour = true;
    notifyListeners();
  }

  void endTour() {
    _tour = false;
    notifyListeners();
  }
}

/// Done unless `main` loads the real state (tests and older flows skip the welcome).
final welcomeProvider = Provider<WelcomeController>((ref) {
  final controller = WelcomeController(ref.watch(databaseProvider));
  ref.onDispose(controller.dispose);
  return controller;
});
