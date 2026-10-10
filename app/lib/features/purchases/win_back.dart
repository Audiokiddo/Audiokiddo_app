import 'package:ak_core/ak_core.dart';

// The win-back card itself is WinBackCard in winback.dart (Start and Shop).

/// When the family's subscription ended (and none is active now): the moment to invite them
/// back with what is new since. Null while subscribed or never subscribed.
DateTime? subscriptionEndedAt(List<Entitlement> entitlements, DateTime now) {
  final all = entitlements.where((e) => e.scope == Scopes.allContent).toList();
  if (all.any((e) => e.isActiveAt(now))) return null;
  final ended = [
    for (final e in all)
      if (e.validUntil case final until? when until.isBefore(now)) until,
  ]..sort();
  return ended.lastOrNull;
}

/// Plays released after [since] (the reason to come back).
List<ContentItem> newSince(Catalog catalog, DateTime since, DateTime now) => [
  for (final i in catalog.items)
    if (i.releasedOn case final r? when r.isAfter(since) && !r.isAfter(now)) i,
];
