import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_service.dart';

/// Whether the app may be used: only with a signed-in parent account (owners' decision).
/// Follows the account service, so signing out anywhere sends the app to the sign-in screen
/// and signing in lets it back. Tests run without the requirement.
class SessionGate extends ChangeNotifier {
  SessionGate(this._service, {this.required = false}) : _signedIn = _service.current != null {
    _subscription = _service.changes.listen((user) {
      final signedIn = user != null;
      if (signedIn == _signedIn) return;
      _signedIn = signedIn;
      notifyListeners();
    });
  }

  final AccountService _service;

  /// Off in tests and in builds without accounts.
  final bool required;
  bool _signedIn;
  StreamSubscription<AccountUser?>? _subscription;

  /// The sign-in screen has to be shown before anything else.
  bool get locked => required && !_signedIn;

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// Overridden in `main` with the requirement on; tests get a gate that never locks.
final sessionGateProvider = Provider<SessionGate>((ref) {
  final gate = SessionGate(ref.watch(accountServiceProvider));
  ref.onDispose(gate.dispose);
  return gate;
});
