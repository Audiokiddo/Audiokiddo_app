import 'dart:async';
import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../account/account_service.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../catalog/catalog_providers.dart';
import '../downloads/download_providers.dart';

/// What this device currently knows about the family's access, persisted locally so
/// downloaded content keeps working offline within the lease (ARCHITECTURE §8).
class AccessState {
  const AccessState({this.entitlements = const [], this.leaseValidUntil, this.lastSeenAt});

  final List<Entitlement> entitlements;
  final DateTime? leaseValidUntil;

  /// Latest time the device has observed; guards against moving the clock back.
  final DateTime? lastSeenAt;

  Map<String, Object?> toJson() => {
    'entitlements': [
      for (final e in entitlements)
        {
          'scope': e.scope,
          'status': e.status.name,
          'source': e.source.name,
          'valid_until': e.validUntil?.toIso8601String(),
        },
    ],
    'lease_valid_until': leaseValidUntil?.toIso8601String(),
    'last_seen_at': lastSeenAt?.toIso8601String(),
  };

  factory AccessState.fromJson(Map<String, Object?> json) => AccessState(
    entitlements: [
      for (final e in (json['entitlements'] as List? ?? const []).cast<Map<String, Object?>>())
        Entitlement(
          scope: e['scope']! as String,
          status: EntitlementStatus.values.byName(e['status']! as String),
          source: EntitlementSource.values.byName(e['source']! as String),
          validUntil: _date(e['valid_until']),
        ),
    ],
    leaseValidUntil: _date(json['lease_valid_until']),
    lastSeenAt: _date(json['last_seen_at']),
  );

  static DateTime? _date(Object? v) => v is String ? DateTime.parse(v) : null;
}

/// Where verified entitlements come from. Etap 3: the server (store purchases, WooCommerce).
abstract interface class EntitlementBackend {
  /// Returns the current entitlements, or throws when offline.
  Future<List<Entitlement>> fetch();
}

/// Development source: the mode is picked on the developer screen, nothing is purchased.
enum DevAccessMode {
  none('Brak zakupów'),
  subscription('Subskrypcja'),
  packWyobraznia('Pakiet Wyobraźnia'),
  packDetektyw('Pakiet Detektyw'),
  allPacks('Wszystkie pakiety');

  const DevAccessMode(this.label);

  final String label;
}

class DevEntitlementBackend implements EntitlementBackend {
  DevEntitlementBackend(this._db);

  static const _key = 'dev_access_mode';
  final AppDatabase _db;

  Future<DevAccessMode> mode() async =>
      DevAccessMode.values.asNameMap()[await _db.readValue(_key)] ?? DevAccessMode.none;

  Future<void> setMode(DevAccessMode mode) => _db.writeValue(_key, mode.name);

  static const _purchasesKey = 'dev_purchases';

  /// Development store purchases (see DevPurchaseVerifier).
  Future<void> addPurchase(List<String> scopes, {DateTime? validUntil}) async {
    final current = await _purchases();
    await _db.writeValue(
      _purchasesKey,
      jsonEncode([
        ...current,
        for (final s in scopes) {'scope': s, 'valid_until': validUntil?.toIso8601String()},
      ]),
    );
  }

  Future<void> clearPurchases() => _db.deleteValue(_purchasesKey);

  Future<List<Map<String, Object?>>> _purchases() async {
    final raw = await _db.readValue(_purchasesKey);
    return raw == null ? [] : (jsonDecode(raw) as List).cast<Map<String, Object?>>();
  }

  @override
  Future<List<Entitlement>> fetch() async {
    Entitlement e(String scope, {DateTime? until}) => Entitlement(
      scope: scope,
      status: EntitlementStatus.active,
      source: EntitlementSource.manual,
      validUntil: until,
    );
    final purchased = [
      for (final p in await _purchases())
        e(
          p['scope']! as String,
          until: p['valid_until'] == null ? null : DateTime.parse(p['valid_until']! as String),
        ),
    ];
    return [
      ...purchased,
      ...switch (await mode()) {
        DevAccessMode.none => const [],
        DevAccessMode.subscription => [
          e(Scopes.allContent, until: DateTime.now().add(const Duration(days: 30))),
        ],
        DevAccessMode.packWyobraznia => [e(Scopes.pack('wyobraznia'))],
        DevAccessMode.packDetektyw => [e(Scopes.pack('detektyw'))],
        DevAccessMode.allPacks => [
          for (final id in ['wyobraznia', 'slowa-i-wiedza', 'detektyw']) e(Scopes.pack(id)),
        ],
      },
    ];
  }
}

/// Entitlements of the signed-in parent from the server (empty when signed out).
class AccountEntitlementBackend implements EntitlementBackend {
  AccountEntitlementBackend(this._account);

  final AccountService _account;

  @override
  Future<List<Entitlement>> fetch() => _account.entitlements();
}

/// Debug builds: developer-screen purchases on top of the server's entitlements.
class CombinedEntitlementBackend implements EntitlementBackend {
  CombinedEntitlementBackend(this._backends);

  final List<EntitlementBackend> _backends;

  @override
  Future<List<Entitlement>> fetch() async => [for (final b in _backends) ...await b.fetch()];
}

/// Debug builds only; null in release.
final devEntitlementBackendProvider = Provider<DevEntitlementBackend?>(
  (ref) => kDebugMode ? DevEntitlementBackend(ref.watch(databaseProvider)) : null,
);

final entitlementBackendProvider = Provider<EntitlementBackend>((ref) {
  final server = AccountEntitlementBackend(ref.watch(accountServiceProvider));
  final dev = ref.watch(devEntitlementBackendProvider);
  return dev == null ? server : CombinedEntitlementBackend([dev, server]);
});

class AccessController extends AsyncNotifier<AccessState> {
  static const _key = 'access_state';

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<AccessState> build() async {
    final raw = await _db.readValue(_key);
    final stored = raw == null
        ? const AccessState()
        : AccessState.fromJson(jsonDecode(raw) as Map<String, Object?>);
    unawaited(Future.microtask(refresh));
    // Signing in, out or into another account changes what the device may play.
    ref.listen(accountUserProvider, (previous, next) {
      if (previous?.value?.id != next.value?.id) unawaited(refresh());
    });
    return stored;
  }

  /// Fetches entitlements online and renews the lease. Offline, the stored state stays.
  Future<void> refresh() async {
    final now = DateTime.now();
    List<Entitlement> entitlements;
    try {
      entitlements = await ref.read(entitlementBackendProvider).fetch();
    } on Exception {
      return; // offline: keep the lease we have
    }
    if (!ref.mounted) return;
    final paidUntil = entitlements
        .where((e) => e.isActiveAt(now))
        .map((e) => e.validUntil)
        .fold<DateTime?>(
          null,
          (latest, d) => d == null || (latest != null && latest.isAfter(d)) ? latest : d,
        );
    final hasOneTime = entitlements.any((e) => e.isActiveAt(now) && e.validUntil == null);
    await _saveAndPrune(
      AccessState(
        entitlements: entitlements,
        leaseValidUntil: entitlements.isEmpty
            ? null
            : leaseValidUntil(issuedAt: now, paidUntil: hasOneTime ? null : paidUntil),
        lastSeenAt: _later(state.value?.lastSeenAt, now),
      ),
    );
  }

  /// Saves the server's answer, then removes downloads the family may no longer play (a
  /// cancelled subscription, an ended trial): paid files must not stay playable on the phone.
  Future<void> _saveAndPrune(AccessState next) async {
    await _save(next);
    if (!ref.mounted) return;
    // In the background: the refresh never waits for file work.
    unawaited(
      pruneLockedDownloads(ref).catchError((Object e) => debugPrint('access: downloads not pruned ($e)')),
    );
  }

  /// Developer screen: pretend the device was offline for longer than the lease.
  Future<void> expireLeaseForTesting() async {
    final current = state.value ?? const AccessState();
    await _save(
      AccessState(
        entitlements: current.entitlements,
        leaseValidUntil: DateTime.now().subtract(const Duration(minutes: 1)),
        lastSeenAt: current.lastSeenAt,
      ),
    );
  }

  Future<void> _save(AccessState next) async {
    final db = _db;
    await db.writeValue(_key, jsonEncode(next.toJson()));
    if (ref.mounted) state = AsyncData(next);
  }

  static DateTime _later(DateTime? a, DateTime b) => a != null && a.isAfter(b) ? a : b;
}

final accessProvider = AsyncNotifierProvider<AccessController, AccessState>(AccessController.new);

/// Removes downloaded plays the family cannot play any more. Free plays always stay.
Future<void> pruneLockedDownloads(Ref ref) async {
  final catalog = await ref.read(catalogProvider.future);
  final manager = ref.read(downloadManagerProvider);
  final summary = await manager.watchSummary().first;
  for (final id in summary.itemIds) {
    final item = catalog.item(id);
    if (item == null || item.isFree) continue;
    if (!ref.read(canPlayProvider(item))) await manager.remove(item);
  }
}
