import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/database.dart';
import '../storage/storage_providers.dart';

/// Light, dark or automatic. Automatic ([ThemeMode.system] here) is the default: light by
/// day, dark in the evening from [eveningFrom] until [morningFrom], whatever the phone says.
class Appearance extends AsyncNotifier<ThemeMode> {
  // A new key (2026-10-14): every family starts again on Auto once; a later choice sticks.
  static const _key = 'theme_mode_2';

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

/// Automatic mode is dark from [evening] (minutes after midnight, 20:00 unless Mój dzień
/// says when bedtime is) to 6:00.
bool isEvening(DateTime now, {int evening = eveningFrom * 60}) =>
    now.hour * 60 + now.minute >= evening || now.hour < morningFrom;

/// The evening of a family whose bedtime is known: half an hour before it, between 18:00 and
/// 21:00 (parent review, 2026-10-18: the screen dims by itself before sleep).
int eveningFor(int? bedtime) => bedtime == null ? eveningFrom * 60 : (bedtime - 30).clamp(18 * 60, 21 * 60);

/// The mode the app shows now for the stored [mode].
ThemeMode effectiveThemeMode(ThemeMode mode, DateTime now, {int evening = eveningFrom * 60}) =>
    mode == ThemeMode.system ? (isEvening(now, evening: evening) ? ThemeMode.dark : ThemeMode.light) : mode;

/// When automatic mode changes next (the evening or 6:00).
DateTime nextAppearanceChange(DateTime now, {int evening = eveningFrom * 60}) {
  final evening0 = DateTime(now.year, now.month, now.day, evening ~/ 60, evening % 60);
  final morning = DateTime(now.year, now.month, now.day, morningFrom);
  if (now.isBefore(morning)) return morning;
  if (now.isBefore(evening0)) return evening0;
  return morning.add(const Duration(days: 1));
}
