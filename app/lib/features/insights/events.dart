import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart' show DateUtils, Widget, BuildContext;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/database.dart';
import '../personal/personal_repository.dart';

/// What we count, first-party only (Kids Category: no third-party analytics). Mirrors the
/// check in the app_events table.
enum AppEvent {
  firstOpen('first_open'),
  appOpen('app_open'),
  onboardingDone('onboarding_done'),
  playStart('play_start'),
  playComplete('play_complete'),
  paywallView('paywall_view'),
  purchaseStart('purchase_start'),
  purchaseDone('purchase_done'),
  referralOpen('referral_open'),
  referralShare('referral_share'),
  promoView('promo_view'),
  promoTap('promo_tap'),
  downloadPack('download_pack'),
  reminderOn('reminder_on'),
  newsAlertsOn('news_alerts_on'),
  welcomeDone('welcome_done'),
  tourDone('tour_done'),
  quickPick('quick_pick'),
  // Analytics annex (docs/ANEKS-ANALITYCZNY.md).
  gameViewed('game_viewed'),
  playExit('play_exit'),
  checkoutFailed('checkout_failed'),
  favoriteAdded('favorite_added'),
  favoriteRemoved('favorite_removed'),
  searchPerformed('search_performed'),
  sourceAnswered('source_answered'),
  cancelReason('cancel_reason');

  const AppEvent(this.wire);
  final String wire;
}

/// Sends events to our own database. Never blocks the app and never throws: a lost event
/// matters less than a smooth play.
abstract interface class EventSink {
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}});
}

/// Tests and builds without a server.
class NoEventSink implements EventSink {
  const NoEventSink();

  @override
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}}) {}
}

/// Sent with every event (docs/ANEKS-ANALITYCZNY.md, global parameters). Nothing about the
/// child but an age band; nothing that names the family.
class EventContext {
  const EventContext({this.ageGroup, this.plan, this.source});

  /// '3-5', '5-7' or '7-9' (see [ageGroupOf]).
  final String? ageGroup;

  /// 'free', 'subscription' or 'package_only' (monthly or yearly is known on the server).
  final String? plan;

  /// Where the family heard of us, as the parent answered (see [AcquisitionSource]).
  final String? source;
}

/// The age band used in the statistics: 3–4 → 3-5, 5–6 → 5-7, 7 and more → 7-9.
String? ageGroupOf(int? age) => switch (age) {
  null => null,
  < 5 => '3-5',
  < 7 => '5-7',
  _ => '7-9',
};

/// A random id, the same shape as Postgres uuids.
String randomUuid() {
  final r = math.Random.secure();
  String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

class SupabaseEventSink implements EventSink {
  SupabaseEventSink(this._client, this._db, {this.appVersion, this.country});

  final SupabaseClient _client;
  final AppDatabase _db;
  final String? appVersion;

  /// Variants of the running A/B tests, sent with the offer and purchase events.
  Map<String, String> abTests = const {};
  static const _abEvents = {AppEvent.paywallView, AppEvent.purchaseStart, AppEvent.purchaseDone};

  /// The market from the phone's region ("PL"), not the person.
  final String? country;

  /// One launch of the app; ties a play to what happened before and after it.
  final String sessionId = randomUuid();

  /// Filled in by the app once providers exist (age band, plan, source).
  EventContext Function()? context;
  static const _installKey = 'install_id';
  Future<String>? _install;

  /// A random id for this install, made once on the phone; says nothing about the family.
  Future<String> _installId() => _install ??= () async {
    final saved = await _db.readValue(_installKey);
    if (saved != null) return saved;
    final id = randomUuid();
    await _db.writeValue(_installKey, id);
    return id;
  }();

  /// The install id, shared with the error log.
  Future<String> installId() => _installId();

  /// Whether this is the first launch on this phone (no install id yet).
  Future<bool> isFirstOpen() async => await _db.readValue(_installKey) == null;

  @override
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}}) {
    // Read now, not after the await: the context belongs to the moment of the event.
    EventContext? c;
    try {
      c = context?.call();
    } on Object {
      c = null;
    }
    unawaited(() async {
      try {
        await _client.from('app_events').insert({
          'install_id': await _installId(),
          'user_id': _client.auth.currentUser?.id,
          'event': event.wire,
          'item_id': ?itemId,
          'props': abTests.isNotEmpty && _abEvents.contains(event) ? {...props, 'ab': abTests} : props,
          'app_version': ?appVersion,
          'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
          'session_id': sessionId,
          'age_group': ?c?.ageGroup,
          'plan': ?c?.plan,
          'source': ?c?.source,
          'country': ?country,
        });
      } on Object catch (e) {
        debugPrint('events: ${event.wire} not sent ($e)');
      }
    }());
  }
}

final eventSinkProvider = Provider<EventSink>((ref) => const NoEventSink());

/// Sends app_open (and first_open on a new install) once per launch, with how many days
/// passed since the last launch.
Future<void> trackLaunch(EventSink sink, AppDatabase db, {DateTime? now}) async {
  final today = now ?? DateTime.now();
  final first = sink is SupabaseEventSink && await sink.isFirstOpen();
  if (first) sink.track(AppEvent.firstOpen);
  final last = DateTime.tryParse(await db.readValue(_lastOpenKey) ?? '');
  await db.writeValue(_lastOpenKey, today.toIso8601String());
  sink.track(
    AppEvent.appOpen,
    props: {
      'first': first,
      if (last != null) 'days_since_last': DateUtils.dateOnly(today).difference(DateUtils.dateOnly(last)).inDays,
    },
  );
}

const _lastOpenKey = 'last_open';

/// How many times this phone has started a play, for play_number and is_first_game_ever.
class PlayCount {
  const PlayCount({required this.number, required this.firstEver, this.previous});

  /// 1 for the first play of this item on this phone, 2 for the second, …
  final int number;

  /// The first play of anything on this phone.
  final bool firstEver;

  /// When this item was started before, for the hours between plays.
  final DateTime? previous;

  Map<String, Object?> get props => {
    'play_number': number,
    if (firstEver) 'first_ever': true,
    if (previous != null) 'hours_since_previous': DateTime.now().difference(previous!).inHours,
  };
}

/// Counts a play start of [itemId] on this phone and returns the numbers for the event.
Future<PlayCount> countPlayStart(AppDatabase db, String itemId, {DateTime? now}) async {
  final at = now ?? DateTime.now();
  final saved = (await db.readValue('plays:$itemId'))?.split('|');
  final count = int.tryParse(saved?.first ?? '') ?? 0;
  final previous = saved != null && saved.length > 1 ? DateTime.tryParse(saved[1]) : null;
  final total = int.tryParse(await db.readValue('plays_total') ?? '') ?? 0;
  await db.writeValue('plays:$itemId', '${count + 1}|${at.toIso8601String()}');
  await db.writeValue('plays_total', '${total + 1}');
  return PlayCount(number: count + 1, firstEver: total == 0, previous: previous);
}

/// Shortcut for widgets and controllers.
extension TrackRef on Ref {
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}}) =>
      read(eventSinkProvider).track(event, itemId: itemId, props: props);
}

/// Favourites with the event (the parent's intent: "I want to remember this one").
Future<void> setFavoriteTracked(WidgetRef ref, String itemId, {required bool favorite}) async {
  await ref.read(personalRepositoryProvider).setFavorite(itemId, favorite: favorite);
  ref.read(eventSinkProvider).track(favorite ? AppEvent.favoriteAdded : AppEvent.favoriteRemoved, itemId: itemId);
}

/// Sends [event] once when it first appears (a screen view), not on every rebuild.
class TrackOnce extends ConsumerStatefulWidget {
  const TrackOnce({super.key, required this.event, this.itemId, this.props = const {}, required this.child});

  final AppEvent event;
  final String? itemId;
  final Map<String, Object?> props;
  final Widget child;

  @override
  ConsumerState<TrackOnce> createState() => _TrackOnceState();
}

class _TrackOnceState extends ConsumerState<TrackOnce> {
  @override
  void initState() {
    super.initState();
    ref.read(eventSinkProvider).track(widget.event, itemId: widget.itemId, props: widget.props);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The app a parent shared to, from the system share sheet ("net.whatsapp…" → "whatsapp").
String shareChannel(String raw) {
  final r = raw.toLowerCase();
  for (final (needle, channel) in const [
    ('whatsapp', 'whatsapp'),
    ('messenger', 'messenger'),
    ('orca', 'messenger'),
    ('facebook', 'facebook'),
    ('instagram', 'instagram'),
    ('activity.message', 'sms'),
    ('sms', 'sms'),
    ('mobilesms', 'sms'),
    ('mms', 'sms'),
    ('mail', 'email'),
    ('gm', 'email'),
    ('copy', 'link_copy'),
    ('clipboard', 'link_copy'),
  ]) {
    if (r.contains(needle)) return channel;
  }
  return r.isEmpty ? 'unknown' : 'other';
}
