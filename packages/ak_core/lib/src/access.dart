import 'content.dart';

enum EntitlementSource { appStore, googlePlay, woocommerce, manual }

/// Mirrors the server-side status; see ARCHITECTURE §6.1.
enum EntitlementStatus { active, grace, billingRetry, expired, revoked, refunded }

/// Scope strings: `all_content`, `pack:<packId>`, `item:<contentId>`.
abstract final class Scopes {
  static const allContent = 'all_content';
  static String pack(String packId) => 'pack:$packId';
  static String item(String contentId) => 'item:$contentId';
}

class Entitlement {
  const Entitlement({required this.scope, required this.status, required this.source, this.validUntil});

  final String scope;
  final EntitlementStatus status;
  final EntitlementSource source;

  /// End of the paid period for subscriptions; null for one-time purchases.
  final DateTime? validUntil;

  /// Billing retry without grace period means the store has stopped access.
  bool isActiveAt(DateTime now) {
    final statusGrantsAccess = status == EntitlementStatus.active || status == EntitlementStatus.grace;
    if (!statusGrantsAccess) return false;
    final until = validUntil;
    return until == null || now.isBefore(until);
  }
}

/// Decides what content the family can play. Pure logic; the offline lease is
/// checked separately by the caller (see `lease.dart`).
class AccessPolicy {
  const AccessPolicy(this.entitlements);

  final List<Entitlement> entitlements;

  Set<String> activeScopes(DateTime now) => {
    for (final e in entitlements)
      if (e.isActiveAt(now)) e.scope,
  };

  bool canPlay(ContentItem item, DateTime now) {
    if (item.isFree) return true;
    final scopes = activeScopes(now);
    return scopes.contains(Scopes.allContent) ||
        (item.packId != null && scopes.contains(Scopes.pack(item.packId!))) ||
        scopes.contains(Scopes.item(item.id));
  }

  bool hasSubscription(DateTime now) => activeScopes(now).contains(Scopes.allContent);
}
