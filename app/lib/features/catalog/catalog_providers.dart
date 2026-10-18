import 'dart:async';
import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access/access_controller.dart';

/// Source of the catalog manifest. Etap 1 reads the bundled mock; Etap 3 adds the
/// server manifest with the last good version cached on the device.
abstract interface class CatalogSource {
  Future<Map<String, Object?>> load();
}

class BundledCatalogSource implements CatalogSource {
  const BundledCatalogSource([this.assetPath = 'assets/mock/catalog.json']);

  final String assetPath;

  @override
  Future<Map<String, Object?>> load() async {
    // Decoded here: loadString hands files over 50 KB to a background isolate, which is
    // slower for a file this size and never runs inside widget tests.
    final bytes = await rootBundle.load(assetPath);
    return jsonDecode(utf8.decode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)))
        as Map<String, Object?>;
  }
}

final catalogSourceProvider = Provider<CatalogSource>((ref) => const BundledCatalogSource());

/// Everything in the manifest, plays announced for later included (the calendar of news).
final fullCatalogProvider = FutureProvider<Catalog>((ref) async {
  final result = parseCatalog(await ref.watch(catalogSourceProvider).load());
  for (final skipped in result.skipped) {
    debugPrint('catalog: skipped $skipped');
  }
  return result.catalog;
});

/// What families can use today: plays with a release date in the future wait in
/// [upcomingItemsProvider] until that day.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final full = await ref.watch(fullCatalogProvider.future);
  final today = ref.watch(calendarDayProvider);
  // A child's birthday opens the next recorded premiere early.
  final gift = ref.watch(earlyPremiereProvider);
  final released = [
    for (final i in full.items)
      // A planned premiere (no recording or script yet) is never playable, even after its
      // date: it stays a face-down card in Nowości until the play is published for real.
      if ((i.releasedOn == null || !i.releasedOn!.isAfter(today) || i.id == gift) && isReady(i)) i,
  ];
  if (released.length == full.items.length) return full;
  return Catalog(version: full.version, packs: full.packs, items: released, shelves: full.shelves);
});

/// A premiere opened before its date (the birthday gift, set from Start). Kept apart from the
/// family's data so the catalog does not depend on it.
class EarlyPremiere extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) {
    if (state != id) state = id;
  }
}

final earlyPremiereProvider = NotifierProvider<EarlyPremiere, String?>(EarlyPremiere.new);

/// A play that can be played: it has a recording or a game script (not a planned premiere).
bool isReady(ContentItem i) => i.audio.isNotEmpty || i.script != null;

/// Plays announced with a future release date, soonest first ("Wkrótce").
final upcomingItemsProvider = Provider<List<ContentItem>>((ref) {
  final full = ref.watch(fullCatalogProvider).value;
  final today = ref.watch(calendarDayProvider);
  if (full == null) return const [];
  return [
    for (final i in full.items)
      if (i.releasedOn != null && i.releasedOn!.isAfter(today)) i,
  ]..sort((a, b) => a.releasedOn!.compareTo(b.releasedOn!));
});

/// Entitlements known on this device (dev source until Etap 3 — see access_controller.dart).
final entitlementsProvider = Provider<List<Entitlement>>(
  (ref) => ref.watch(accessProvider).value?.entitlements ?? const [],
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Invalidate cached time decisions at expiry/midnight and notice wall-clock changes.
/// Resume and playback explicitly refresh this too: background timers can be suspended.
final currentTimeProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  var next = now.add(const Duration(minutes: 1));
  final midnight = DateTime(now.year, now.month, now.day + 1);
  if (midnight.isBefore(next)) next = midnight;
  final timer = Timer(next.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return now;
});

/// Access expiry is separate from the catalog clock: loading access may itself read
/// the catalog while pruning downloads. Keeping that dependency out avoids a cycle.
final accessTimeProvider = Provider<DateTime>((ref) {
  ref.watch(currentTimeProvider);
  final now = ref.watch(clockProvider)();
  DateTime? next;
  for (final e in ref.watch(entitlementsProvider)) {
    final end = e.validUntil;
    if (end != null && end.isAfter(now) && (next == null || end.isBefore(next))) next = end;
  }
  if (next != null) {
    final timer = Timer(next.difference(now), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return now;
});

/// Catalog filtering rebuilds only when the calendar date changes.
final calendarDayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(currentTimeProvider);
  return DateTime(now.year, now.month, now.day);
});

final accessPolicyProvider = Provider<AccessPolicy>((ref) => AccessPolicy(ref.watch(entitlementsProvider)));

/// Offline lease for paid content (ARCHITECTURE §8).
final leaseStateProvider = Provider<LeaseState>((ref) {
  final access = ref.watch(accessProvider).value;
  ref.watch(currentTimeProvider);
  final now = ref.watch(clockProvider)();
  final until = access?.leaseValidUntil;
  if (until != null && until.isAfter(now)) {
    final timer = Timer(until.difference(now), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return evaluateLease(now: now, validUntil: access?.leaseValidUntil, lastSeenAt: access?.lastSeenAt);
});

enum ItemAccess { playable, locked, needsRefresh }

/// "Dobranoc zawsze działa" (research 2026-10-12: a child left without the bedtime play after a
/// subscription lapsed is the worst review). When the whole library ended earlier today, the
/// bedtime plays keep playing until midnight. Refunds and revoked access get no grace.
bool bedtimeGrace(List<Entitlement> entitlements, ContentItem item, DateTime now) {
  if (!item.situations.contains(Situation.przedSnem)) return false;
  return entitlements.any((e) {
    final until = e.validUntil?.toLocal();
    return e.scope == Scopes.allContent &&
        until != null &&
        !until.isAfter(now) &&
        until.year == now.year &&
        until.month == now.month &&
        until.day == now.day &&
        const {
          EntitlementStatus.active,
          EntitlementStatus.grace,
          EntitlementStatus.expired,
        }.contains(e.status);
  });
}

/// Free content always plays; paid content needs an entitlement and a valid lease.
final itemAccessProvider = Provider.family<ItemAccess, ContentItem>((ref, item) {
  if (item.isFree) return ItemAccess.playable;
  final now = ref.watch(accessTimeProvider);
  if (!ref.watch(accessPolicyProvider).canPlay(item, now)) {
    return bedtimeGrace(ref.watch(entitlementsProvider), item, now) ? ItemAccess.playable : ItemAccess.locked;
  }
  return ref.watch(leaseStateProvider) == LeaseState.valid ? ItemAccess.playable : ItemAccess.needsRefresh;
});

final canPlayProvider = Provider.family<bool, ContentItem>(
  (ref, item) => ref.watch(itemAccessProvider(item)) == ItemAccess.playable,
);

/// A free play shows "ZA DARMO" on its cover, so a parent sees at once what costs nothing
/// (research 2026-10-12, finding 12). Subscribers have everything, so no label for them.
final showFreeBadgeProvider = Provider.family<bool, ContentItem>(
  (ref, item) =>
      item.isFree &&
      !ref
          .watch(accessPolicyProvider)
          .activeScopes(ref.watch(accessTimeProvider))
          .contains(Scopes.allContent),
);
