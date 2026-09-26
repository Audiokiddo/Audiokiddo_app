import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';

/// Whether the first-run welcome was shown. Loaded before the first frame (like kids mode).
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._db, {this._done = false});

  static const _key = 'onboarding_done';
  final AppDatabase _db;
  bool _done;

  bool get done => _done;

  Future<void> load() async {
    _done = await _db.readValue(_key) == 'true';
    notifyListeners();
  }

  Future<void> complete() async {
    await _db.writeValue(_key, 'true');
    _done = true;
    notifyListeners();
  }
}

/// Overridden in `main` and tests.
final onboardingProvider = Provider<OnboardingController>(
  (ref) => throw UnimplementedError('onboardingProvider must be overridden'),
);
