import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../family/family.dart';
import '../player/bottom_dock.dart' show ResumeCard, resumeCardProvider;
import '../family/plan_texts.dart';
import '../lord/lord_lines.dart';

/// What the home-screen widget shows: the active child's week, today's play from the plan
/// (one tap starts it) and the unfinished play to pick up.
@immutable
class HomeWidgetData {
  const HomeWidgetData({
    this.line = '',
    this.notes = 0,
    this.todayDone = false,
    this.next,
    this.resume,
  });

  /// "Zosia · dzień 3 · 2 z 7 nut" or "Zosia: dzisiejsza nuta zebrana"; empty without a child.
  final String line;

  /// Notes collected this week, 0–7 (dots on the widget).
  final int notes;
  final bool todayDone;

  /// Today's play from the plan, not done yet.
  final WidgetLink? next;

  /// The last play, stopped halfway.
  final WidgetLink? resume;

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetData &&
      other.line == line &&
      other.notes == notes &&
      other.todayDone == todayDone &&
      other.next == next &&
      other.resume == resume;

  @override
  int get hashCode => Object.hash(line, notes, todayDone, next, resume);
}

/// A play on the widget: its title, a short detail ("6 min") and the app path it opens.
@immutable
class WidgetLink {
  const WidgetLink({required this.title, required this.detail, required this.path});

  final String title;
  final String detail;

  /// Opened as `audiokiddo://open<path>`.
  final String path;

  @override
  bool operator ==(Object other) =>
      other is WidgetLink && other.title == title && other.detail == detail && other.path == path;

  @override
  int get hashCode => Object.hash(title, detail, path);
}

String _minutes(ContentItem item) => '${(item.durationSec / 60).ceil().clamp(1, 999)} min';

/// The widget's start: the play opens and starts at once (`?graj=1`).
String widgetPlayPath(ContentItem item) => '/zabawa/${item.id}?graj=1';

/// Notes of the current week, as on the melody staff in the Plan tab.
int weekNotes({required int currentDay, required int completedDays}) {
  final week = (currentDay - 1) ~/ 7;
  return (completedDays - week * 7).clamp(0, 7);
}

final homeWidgetDataProvider = Provider<HomeWidgetData?>((ref) {
  final family = ref.watch(familyProvider).value;
  final catalog = ref.watch(catalogProvider).value;
  final resumeCard = ref.watch(resumeCardProvider);
  final resume = switch (resumeCard) {
    null => null,
    ResumeCard(loaded: true) => WidgetLink(title: resumeCard.title, detail: 'w odtwarzaczu', path: '/odtwarzacz'),
    ResumeCard(:final item?) => WidgetLink(title: item.title, detail: 'dokończ', path: widgetPlayPath(item)),
    _ => null,
  };
  final child = family?.active;
  final position = child == null ? null : ref.watch(planPositionProvider(child.id));
  if (family == null || child == null || position == null) {
    return resume == null ? null : HomeWidgetData(resume: resume);
  }
  WidgetLink? next;
  if (!position.todayDone && catalog != null) {
    final today = ref.watch(planProvider(child.id)).where((d) => d.day == position.currentDay).firstOrNull;
    for (final id in today?.itemIds ?? const <String>[]) {
      final item = catalog.item(id);
      if (item != null && item.id != resumeCard?.item?.id && ref.watch(canPlayProvider(item))) {
        next = WidgetLink(title: item.title, detail: _minutes(item), path: widgetPlayPath(item));
        break;
      }
    }
  }
  final l10n = lookupAppLocalizations(const Locale('pl'));
  final name = childLabel(l10n, child, family.children.indexOf(child));
  final notes = weekNotes(currentDay: position.currentDay, completedDays: position.completedDays);
  return HomeWidgetData(
    line: position.todayDone ? l10n.widgetDone(name) : l10n.widgetProgress(name, position.currentDay, notes),
    notes: notes,
    todayDone: position.todayDone,
    next: next,
    resume: resume,
  );
});

/// Szop’en's widget line for each part of the day, a different one every day.
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
      for (final (key, link) in [('next', data?.next), ('resume', data?.resume)]) {
        await HomeWidget.saveWidgetData<String>('${key}_title', link?.title ?? '');
        await HomeWidget.saveWidgetData<String>('${key}_detail', link?.detail ?? '');
        await HomeWidget.saveWidgetData<String>('${key}_path', link?.path ?? '');
      }
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
