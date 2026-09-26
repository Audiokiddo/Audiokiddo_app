/// Offline access policy (ARCHITECTURE §8).
abstract final class LeasePolicy {
  /// Longest time paid downloads keep working without contacting the server.
  static const maxOffline = Duration(days: 30);

  /// Extra time after a subscription period ends, covering renewals that are late to sync.
  static const renewalSlack = Duration(days: 3);

  /// How long files of expired content stay on disk before automatic removal.
  static const keepFilesAfterExpiry = Duration(days: 14);

  /// Moving the clock back further than this forces an online refresh.
  static const clockRollbackTolerance = Duration(hours: 24);
}

/// Computes `valid_until` for a lease issued at [issuedAt] (server side and tests).
DateTime leaseValidUntil({required DateTime issuedAt, DateTime? paidUntil}) {
  final cap = issuedAt.add(LeasePolicy.maxOffline);
  if (paidUntil == null) return cap; // one-time purchases: only the offline cap applies
  final withSlack = paidUntil.add(LeasePolicy.renewalSlack);
  return withSlack.isBefore(cap) ? withSlack : cap;
}

enum LeaseState {
  /// Paid downloads may play.
  valid,

  /// No lease yet (never verified online). Paid content stays locked.
  missing,

  /// Lease ran out; the parent needs to connect once.
  expired,

  /// Device clock went backwards beyond tolerance; needs an online refresh.
  clockRolledBack,
}

/// Evaluates the locally stored lease.
///
/// [lastSeenAt] is the latest time this device has ever observed; it defends
/// against moving the clock back to stretch an expired lease.
LeaseState evaluateLease({
  required DateTime now,
  required DateTime? validUntil,
  required DateTime? lastSeenAt,
}) {
  if (lastSeenAt != null && now.isBefore(lastSeenAt.subtract(LeasePolicy.clockRollbackTolerance))) {
    return LeaseState.clockRolledBack;
  }
  if (validUntil == null) return LeaseState.missing;
  return now.isBefore(validUntil) ? LeaseState.valid : LeaseState.expired;
}

/// Whether files of content that lost access at [accessLostAt] should now be deleted.
bool shouldDeleteExpiredFiles({required DateTime now, required DateTime accessLostAt}) =>
    !now.isBefore(accessLostAt.add(LeasePolicy.keepFilesAfterExpiry));
