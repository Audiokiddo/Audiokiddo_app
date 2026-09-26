import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';

@immutable
class KidsModeSettings {
  const KidsModeSettings({this.active = false, this.age = 3, this.onlyDownloaded = false});

  factory KidsModeSettings.fromJson(Map<String, Object?> json) => KidsModeSettings(
    active: json['active'] == true,
    age: (json['age'] as int?) ?? 3,
    onlyDownloaded: json['only_downloaded'] == true,
  );

  final bool active;

  /// The child's age group; kids mode shows content from this age down.
  final int age;

  /// For trips: show only content that plays without internet.
  final bool onlyDownloaded;

  Map<String, Object?> toJson() => {'active': active, 'age': age, 'only_downloaded': onlyDownloaded};
}

/// Kids mode state, loaded before the first frame so a restart never flashes the parent
/// zone (ARCHITECTURE §12). The router listens to it.
class KidsModeController extends ChangeNotifier {
  KidsModeController(this._db);

  static const _key = 'kids_mode';
  final AppDatabase _db;
  KidsModeSettings _settings = const KidsModeSettings();

  KidsModeSettings get settings => _settings;
  bool get active => _settings.active;

  Future<void> load() async {
    final raw = await _db.readValue(_key);
    if (raw != null) _settings = KidsModeSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    notifyListeners();
  }

  Future<void> enter({required int age, required bool onlyDownloaded}) =>
      _save(KidsModeSettings(active: true, age: age, onlyDownloaded: onlyDownloaded));

  /// Call only after the parental gate.
  Future<void> exit() =>
      _save(KidsModeSettings(age: _settings.age, onlyDownloaded: _settings.onlyDownloaded));

  Future<void> _save(KidsModeSettings next) async {
    await _db.writeValue(_key, jsonEncode(next.toJson()));
    _settings = next;
    notifyListeners();
  }
}

/// Overridden in `main` (and tests) with a loaded controller.
final kidsModeProvider = Provider<KidsModeController>(
  (ref) => throw UnimplementedError('kidsModeProvider must be overridden'),
);
