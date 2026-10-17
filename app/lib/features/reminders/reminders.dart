import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';

/// One reminder to show at [at] (local time).
class ReminderSlot {
  const ReminderSlot({required this.id, required this.at, required this.title, required this.body});

  final int id;
  final DateTime at;
  final String title;
  final String body;
}

/// Shows the parent's daily reminders. Local only: nothing is sent from a server.
abstract interface class ReminderScheduler {
  /// Asks the system for permission (call after the parent chose to turn reminders on).
  Future<bool> requestPermission();

  /// Replaces the daily reminders (ids below 1000); other notifications stay.
  Future<void> replaceAll(List<ReminderSlot> slots);

  /// One notification of its own (ids from 1000), replacing any with the same id.
  Future<void> schedule(ReminderSlot slot);

  Future<void> cancel(int id);

  Future<void> cancelAll();
}

class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_szop'),
        // No prompt at start-up: permission is asked only when the parent turns reminders on.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Szop’en in a different pose for each notification: beside the text on Android, as the
  /// picture on iOS. The status-bar icon is his white outline (Android draws it single-colour).
  Future<NotificationDetails> _details(
    int id, {
    required String channel,
    required String name,
    required String description,
  }) async {
    final pose = szopPoseFor(id);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        name,
        channelDescription: description,
        importance: Importance.defaultImportance,
        icon: 'ic_stat_szop',
        color: const Color(0xFF3AAFB0),
        largeIcon: DrawableResourceAndroidBitmap('notif_szop_$pose'),
      ),
      iOS: DarwinNotificationDetails(attachments: [?await _iosPicture(id, pose)]),
    );
  }

  /// iOS moves an attachment into its own store, so each notification gets a fresh copy.
  Future<DarwinNotificationAttachment?> _iosPicture(int id, String pose) async {
    if (!Platform.isIOS) return null;
    try {
      final data = await rootBundle.load('assets/szop/$pose.png');
      final file = File(p.join((await getTemporaryDirectory()).path, 'szop_note_${id}_$pose.png'));
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      return DarwinNotificationAttachment(file.path);
    } on Object {
      // A reminder without the picture is still a reminder.
      return null;
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
  }

  @override
  Future<void> replaceAll(List<ReminderSlot> slots) async {
    await _init();
    for (final pending in await _plugin.pendingNotificationRequests()) {
      if (pending.id < 1000) await _plugin.cancel(id: pending.id);
    }
    for (final slot in slots) {
      await _plugin.zonedSchedule(
        id: slot.id,
        scheduledDate: tz.TZDateTime.from(slot.at, tz.local),
        notificationDetails: await _details(
          slot.id,
          channel: 'daily_play',
          name: 'Codzienna zabawa',
          description: 'Przypomnienie o dzisiejszej porcji zabaw',
        ),
        // Inexact is fine for a friendly nudge and needs no special alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: slot.title,
        body: slot.body,
      );
    }
  }

  @override
  Future<void> schedule(ReminderSlot slot) async {
    await _init();
    if (!slot.at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: slot.id,
      scheduledDate: tz.TZDateTime.from(slot.at, tz.local),
      notificationDetails: await _details(
        slot.id,
        channel: 'access_news',
        name: 'Dostęp i nowości',
        description: 'Koniec dostępu i nowe zabawy, tylko gdy je włączysz',
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: slot.title,
      body: slot.body,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }
}

/// Szop’en poses for notifications (`assets/szop/<pose>.png`, Android drawable `notif_szop_<pose>`).
const szopNotificationPoses = ['zadowolony', 'klaszcze', 'zdziwiony', 'chytry', 'prosi', 'nasluchuje'];

/// The pose for notification [id]: consecutive reminders show different poses.
String szopPoseFor(int id) => szopNotificationPoses[id % szopNotificationPoses.length];

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.hour = 18, this.minute = 0});

  final bool enabled;
  final int hour;
  final int minute;
}

/// Texts are passed in (localised in the UI layer): (title, body) pairs used in turn.
typedef ReminderTexts = List<(String, String)>;

/// Daily reminder at the parent's hour for the next week, rescheduled whenever the app
/// opens (and skipping today once today's portion is done). Humour included, guilt not.
class RemindersController extends AsyncNotifier<ReminderSettings> {
  static const _key = 'reminders';
  static const days = 7;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<ReminderSettings> build() async {
    final raw = await ref.watch(databaseProvider).readValue(_key);
    if (raw == null) return const ReminderSettings();
    final [enabled, hour, minute] = raw.split(':');
    return ReminderSettings(enabled: enabled == '1', hour: int.parse(hour), minute: int.parse(minute));
  }

  Future<void> _store(ReminderSettings s) async {
    await _db.writeValue(_key, '${s.enabled ? 1 : 0}:${s.hour}:${s.minute}');
    state = AsyncData(s);
  }

  /// Returns false when the system refused (the parent can change it in Settings).
  Future<bool> enable({required int hour, required int minute, required ReminderTexts texts}) async {
    final granted = await ref.read(reminderSchedulerProvider).requestPermission();
    await _store(ReminderSettings(enabled: granted, hour: hour, minute: minute));
    if (granted) {
      await reschedule(texts: texts);
      await _aboutUsOnce(hour: hour, minute: minute, now: DateTime.now());
    }
    return granted;
  }

  /// Once, a few days in: who makes AudioKiddo (instead of a thank-you screen at the start).
  Future<void> _aboutUsOnce({required int hour, required int minute, required DateTime now}) async {
    if (await _db.readValue(_aboutUsKey) != null) return;
    await ref.read(reminderSchedulerProvider).schedule(aboutUsSlot(hour: hour, minute: minute, now: now));
    await _db.writeValue(_aboutUsKey, now.toIso8601String());
  }

  static const _aboutUsKey = 'about_us_note';

  Future<void> disable() async {
    final s = state.value ?? const ReminderSettings();
    await ref.read(reminderSchedulerProvider).cancelAll();
    await _store(ReminderSettings(hour: s.hour, minute: s.minute));
  }

  Future<void> reschedule({required ReminderTexts texts, bool todayDone = false, DateTime? now}) async {
    final s = state.value ?? await future;
    if (!s.enabled || texts.isEmpty) return;
    final at = now ?? DateTime.now();
    await ref.read(reminderSchedulerProvider).replaceAll(reminderSlots(s, texts, now: at, todayDone: todayDone));
    // Only for parents who turned reminders on: the weekend road is the moment that sells.
    await ref.read(reminderSchedulerProvider).schedule(tripReminderSlot(now: at));
  }
}

/// The note about Nela and Dawid, [aboutUsAfterDays] after reminders were turned on, at their hour.
const aboutUsAfterDays = 4;
const aboutUsId = 1003;

ReminderSlot aboutUsSlot({required int hour, required int minute, required DateTime now}) => ReminderSlot(
  id: aboutUsId,
  at: DateTime(now.year, now.month, now.day + aboutUsAfterDays, hour, minute),
  title: 'Ciekawostka od Szop’ena',
  body:
      'AudioKiddo robią Nela i Dawid, para z Polski. Sami piszą zabawy i podkładają głosy. '
      'Więcej o nich: Więcej → O nas.',
);

const tripReminderId = 1004;

/// Friday 15:30 (this week's, or next if it has passed): a weekend in the car is the moment
/// families need plays that last (research 2026-10-12, segment "Trasa").
ReminderSlot tripReminderSlot({required DateTime now}) {
  var day = DateTime(now.year, now.month, now.day + (DateTime.friday - now.weekday) % 7, 15, 30);
  if (!day.isAfter(now)) day = DateTime(day.year, day.month, day.day + 7, 15, 30);
  return ReminderSlot(
    id: tripReminderId,
    at: day,
    title: 'Weekend w aucie?',
    body: 'Pobierz zabawy na drogę, zanim zniknie zasięg. Start → W podróży.',
  );
}

/// The next [RemindersController.days] reminders; texts rotate by date so they vary.
List<ReminderSlot> reminderSlots(
  ReminderSettings s,
  ReminderTexts texts, {
  required DateTime now,
  bool todayDone = false,
}) {
  final slots = <ReminderSlot>[];
  for (var d = 0; slots.length < RemindersController.days && d < RemindersController.days + 2; d++) {
    final at = DateTime(now.year, now.month, now.day + d, s.hour, s.minute);
    if (!at.isAfter(now) || (d == 0 && todayDone)) continue;
    final dayNumber = at.difference(DateTime(2026)).inDays;
    final (title, body) = texts[dayNumber % texts.length];
    slots.add(ReminderSlot(id: 100 + slots.length, at: at, title: title, body: body));
  }
  return slots;
}

final remindersProvider = AsyncNotifierProvider<RemindersController, ReminderSettings>(
  RemindersController.new,
);
