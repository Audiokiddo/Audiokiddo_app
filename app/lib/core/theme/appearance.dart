import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/database.dart';
import '../storage/storage_providers.dart';

/// Light, dark or automatic. Automatic ([ThemeMode.system] here) is the default: light by
/// day, dark in the evening from [eveningFrom] until [morningFrom], whatever the phone says.
class Appearance extends AsyncNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<ThemeMode> build() async => switch (await _db.readValue(_key)) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    _ => ref.read(appearanceDefaultProvider),
  };

  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode);
    await _db.writeValue(_key, mode.name);
  }
}

final appearanceProvider = AsyncNotifierProvider<Appearance, ThemeMode>(Appearance.new);

/// What a family that never chose gets (tests pin it to light).
final appearanceDefaultProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

const eveningFrom = 20;
const morningFrom = 6;

/// Automatic mode is dark from 20:00 to 6:00.
bool isEvening(DateTime now) => now.hour >= eveningFrom || now.hour < morningFrom;

/// The mode the app shows now for the stored [mode].
ThemeMode effectiveThemeMode(ThemeMode mode, DateTime now) =>
    mode == ThemeMode.system ? (isEvening(now) ? ThemeMode.dark : ThemeMode.light) : mode;

/// When automatic mode changes next (20:00 or 6:00).
DateTime nextAppearanceChange(DateTime now) {
  final evening = DateTime(now.year, now.month, now.day, eveningFrom);
  final morning = DateTime(now.year, now.month, now.day, morningFrom);
  if (now.isBefore(morning)) return morning;
  if (now.isBefore(evening)) return evening;
  return morning.add(const Duration(days: 1));
}
