import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../l10n/app_localizations.dart';
import '../family/family.dart';
import '../family/plan_texts.dart';
import '../lord/lord_lines.dart';

/// What the home-screen widget shows under the part of the day: the active child's week.
@immutable
class HomeWidgetData {
  const HomeWidgetData({required this.line, required this.notes, required this.todayDone});

  /// "Zosia · dzień 3 · 2 z 7 nut" or "Zosia: dzisiejsza nuta zebrana".
  final String line;

  /// Notes collected this week, 0–7 (dots on the widget).
  final int notes;
  final bool todayDone;

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetData && other.line == line && other.notes == notes && other.todayDone == todayDone;

  @override
  int get hashCode => Object.hash(line, notes, todayDone);
}

/// Notes of the current week, as on the melody staff in the Plan tab.
int weekNotes({required int currentDay, required int completedDays}) {
  final week = (currentDay - 1) ~/ 7;
  return (completedDays - week * 7).clamp(0, 7);
}

final homeWidgetDataProvider = Provider<HomeWidgetData?>((ref) {
  final family = ref.watch(familyProvider).value;
  final child = family?.active;
  if (family == null || child == null) return null;
  final position = ref.watch(planPositionProvider(child.id));
  if (position == null) return null;
  final l10n = lookupAppLocalizations(const Locale('pl'));
  final name = childLabel(l10n, child, family.children.indexOf(child));
  final notes = weekNotes(currentDay: position.currentDay, completedDays: position.completedDays);
  return HomeWidgetData(
    line: position.todayDone ? l10n.widgetDone(name) : l10n.widgetProgress(name, position.currentDay, notes),
    notes: notes,
    todayDone: position.todayDone,
  );
});

/// Lord's widget line for each part of the day, a different one every day.
Map<String, String> widgetJokes(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return {
    'joke_morning': lordLine(LordPool.widgetMorning, dayOfYear),
    'joke_midday': lordLine(LordPool.widgetMidday, dayOfYear),
    'joke_afternoon': lordLine(LordPool.widgetAfternoon, dayOfYear),
    'joke_evening': lordLine(LordPool.widgetEvening, dayOfYear),
  };
}

/// Writes widget data where the widgets read it (iOS App Group, Android shared preferences).
abstract interface class HomeWidgetSink {
  Future<void> push(HomeWidgetData? data);
}

class PlatformHomeWidgetSink implements HomeWidgetSink {
  const PlatformHomeWidgetSink();

  /// Shared with the iOS widget extension (both targets carry this App Group). A personal
  /// test build on a phone passes its own (tool/phone_build.sh).
  static const appGroup = String.fromEnvironment('AK_APP_GROUP', defaultValue: 'group.pl.audiokiddo.app');

  @override
  Future<void> push(HomeWidgetData? data) async {
    try {
      await HomeWidget.setAppGroupId(appGroup);
      // Strings only: both platforms read them back without type juggling. Empty = no child.
      await HomeWidget.saveWidgetData<String>('line', data?.line ?? '');
      await HomeWidget.saveWidgetData<String>('notes', data == null ? '' : '${data.notes}');
      await HomeWidget.saveWidgetData<String>('done', data?.todayDone ?? false ? '1' : '');
      for (final MapEntry(:key, :value) in widgetJokes(DateTime.now()).entries) {
        await HomeWidget.saveWidgetData<String>(key, value);
      }
      await HomeWidget.updateWidget(
        iOSName: 'AudioKiddoWidget',
        qualifiedAndroidName: 'pl.audiokiddo.app.DayPartWidget',
      );
    } on MissingPluginException {
      // Tests and platforms without widgets.
    } on PlatformException catch (e) {
      debugPrint('home widget: $e');
    }
  }
}

final homeWidgetSinkProvider = Provider<HomeWidgetSink>((ref) => const PlatformHomeWidgetSink());
