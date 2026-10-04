import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/database.dart';
import '../storage/storage_providers.dart';

/// Light, dark or as the phone. Light by default: the app is designed light first, and a
/// phone in dark mode should not make the whole app dark without the parent choosing it.
class Appearance extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<ThemeMode> build() async => switch (await _db.readValue(_key)) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode);
    await _db.writeValue(_key, mode.name);
  }
}

final appearanceProvider = AsyncNotifierProvider<Appearance, ThemeMode>(Appearance.new);
