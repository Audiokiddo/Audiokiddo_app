import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/database.dart';

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
  newsAlertsOn('news_alerts_on');

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

class SupabaseEventSink implements EventSink {
  SupabaseEventSink(this._client, this._db, {this.appVersion});

  final SupabaseClient _client;
  final AppDatabase _db;
  final String? appVersion;
  static const _installKey = 'install_id';
  Future<String>? _install;

  /// A random id for this install, made once on the phone; says nothing about the family.
  Future<String> _installId() => _install ??= () async {
    final saved = await _db.readValue(_installKey);
    if (saved != null) return saved;
    final r = math.Random.secure();
    String hex(int n) => List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
    final id = '${hex(8)}-${hex(4)}-4${hex(3)}-${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
    await _db.writeValue(_installKey, id);
    return id;
  }();

  /// Whether this is the first launch on this phone (no install id yet).
  Future<bool> isFirstOpen() async => await _db.readValue(_installKey) == null;

  @override
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}}) {
    unawaited(() async {
      try {
        await _client.from('app_events').insert({
          'install_id': await _installId(),
          'user_id': _client.auth.currentUser?.id,
          'event': event.wire,
          'item_id': ?itemId,
          'props': props,
          'app_version': ?appVersion,
          'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
        });
      } on Object catch (e) {
        debugPrint('events: ${event.wire} not sent ($e)');
      }
    }());
  }
}

final eventSinkProvider = Provider<EventSink>((ref) => const NoEventSink());

/// Sends app_open (and first_open on a new install) once per launch.
Future<void> trackLaunch(EventSink sink) async {
  if (sink is SupabaseEventSink && await sink.isFirstOpen()) sink.track(AppEvent.firstOpen);
  sink.track(AppEvent.appOpen);
}

/// Shortcut for widgets and controllers.
extension TrackRef on Ref {
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}}) =>
      read(eventSinkProvider).track(event, itemId: itemId, props: props);
}
