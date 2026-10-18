import 'dart:io' show Platform;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/grouped_list.dart';
import '../access/access_controller.dart';
import '../alerts/alerts.dart' show dayAndMonth;
import '../catalog/catalog_providers.dart' show clockProvider;
import '../insights/events.dart';
import 'manage_subscription.dart';
import 'purchase_controller.dart';
import 'shop.dart';

/// The family's subscription as the app knows it: the all_content entitlement that ends last.
Entitlement? currentSubscription(List<Entitlement> entitlements, DateTime now) {
  final subs = [
    for (final e in entitlements)
      if (e.scope == Scopes.allContent && e.validUntil != null && e.isActiveAt(now)) e,
  ]..sort((a, b) => b.validUntil!.compareTo(a.validUntil!));
  return subs.firstOrNull;
}

/// Only store subscriptions are cancelled in the store; codes, credit and gifts simply end.
bool cancellableInStore(Entitlement e) =>
    e.source == EntitlementSource.appStore || e.source == EntitlementSource.googlePlay;

String _sourceName(EntitlementSource s) => switch (s) {
  EntitlementSource.appStore => 'App Store',
  EntitlementSource.googlePlay => 'Google Play',
  EntitlementSource.woocommerce => 'audiokiddo.pl',
  EntitlementSource.manual => 'Kod, prezent albo środki za polecenia',
};

/// "Jak możemy pomóc?": the subscription with its date, restoring purchases, changing the plan
/// and cancelling. Cancelling asks why first (one tap), then confirms with the date access ends,
/// and only then opens the store's page, where the cancellation itself happens.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenPurchaseMessages(context, ref);
    final now = ref.watch(clockProvider)();
    final entitlements = ref.watch(accessProvider).value?.entitlements ?? const <Entitlement>[];
    final sub = currentSubscription(entitlements, now);
    final busy = ref.watch(purchaseControllerProvider).busyProductId == 'restore';
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Jak możemy pomóc?')),
      body: ListView(
        padding: const EdgeInsets.only(top: AkSpace.s, bottom: AkSpace.xl),
        children: [
          GroupedSection(
            children: [
              if (sub == null)
                const GroupedRow(
                  title: 'Nie masz teraz abonamentu',
                  subtitle: 'Darmowe zabawy działają bez niego. Abonament otwiera wszystko.',
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AkSpace.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Abonament audiokiddo',
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Badge(sub.status == EntitlementStatus.grace ? 'Problem z płatnością' : 'Aktywny'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cancellableInStore(sub)
                            ? 'Opłacony do ${dayAndMonth(sub.validUntil!.toLocal())} ${sub.validUntil!.toLocal().year}. '
                                  'Potem odnawia się sam, dopóki go nie anulujesz.'
                            : 'Ważny do ${dayAndMonth(sub.validUntil!.toLocal())} ${sub.validUntil!.toLocal().year}. '
                                  'Nie odnawia się sam.',
                        style: text.bodyMedium,
                      ),
                      Text(
                        _sourceName(sub.source),
                        style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          GroupedSection(
            children: [
              GroupedRow(
                icon: Icons.restore_rounded,
                iconColor: AkBrand.tealDeep,
                title: 'Przywróć poprzednie zakupy',
                trailing: busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator()) : null,
                onTap: busy ? null : () => ref.read(purchaseControllerProvider.notifier).restore(),
              ),
              GroupedRow(
                icon: Icons.swap_horiz_rounded,
                iconColor: const Color(0xFF2F6FDB),
                title: 'Zmień plan',
                subtitle: 'Miesięczny albo roczny (taniej o 25%)',
                chevron: true,
                onTap: () => sub != null && cancellableInStore(sub)
                    ? openExternal(manageSubscriptionsUrl)
                    : context.go('/sklep'),
              ),
              if (sub != null && cancellableInStore(sub))
                GroupedRow(
                  icon: Icons.cancel_outlined,
                  iconColor: const Color(0xFFC0392B),
                  title: 'Anuluj subskrypcję',
                  chevron: true,
                  onTap: () => cancelSubscriptionFlow(context, ref, sub),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(10)),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w700),
    ),
  );
}

/// Why → (what we can fix) → confirm with the end date → the store's page. Every step has a
/// way back, and "Zostaw subskrypcję" is as easy as cancelling (no dark patterns).
Future<void> cancelSubscriptionFlow(BuildContext context, WidgetRef ref, Entitlement sub) async {
  final reason = await askCancelReason(context);
  if (reason == null || !context.mounted) return;
  recordCancelReason(ref, reason);
  final reply = cancelReasonReply(reason);
  if (reply != null) {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dziękujemy za odpowiedź'),
        content: Text(reply),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Zostaję')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Dalej')),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
  }
  // A break instead of goodbye: holidays, a sick month, a child who wants a rest.
  if (reason != CancelReason.mistake && reason != CancelReason.technical) {
    final paused = await offerPause(context, ref, reason);
    if (paused || !context.mounted) return;
  }
  final until = sub.validUntil!.toLocal();
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Potwierdź anulowanie', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Jeśli anulujesz, wszystkie zabawy zostaną otwarte do ${dayAndMonth(until)}. '
                'Potem zostaną darmowe zabawy, a profile i postępy dzieci poczekają na Was.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Anulowanie kończysz w ustawieniach ${Platform.isIOS ? 'App Store' : 'Google Play'}, '
                'tam też zawsze możesz je cofnąć.',
                style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Zostaw subskrypcję'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Anuluj subskrypcję'),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (confirmed == true) await openExternal(manageSubscriptionsUrl);
}

/// Google Play lets the family pause the subscription for 1–3 months (and resume early); the
/// App Store has no pause, so there the sheet says plainly what stays when they cancel and come
/// back. True when the parent went to pause (the cancellation stops there).
Future<bool> offerPause(BuildContext context, WidgetRef ref, CancelReason reason) async {
  final android = Platform.isAndroid;
  final choice = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                android ? 'Może przerwa zamiast rezygnacji?' : 'Przerwa? Wszystko na Was poczeka',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                android
                    ? 'W Google Play wstrzymasz abonament na 1, 2 albo 3 miesiące. Nic nie płacisz, '
                          'a potem wszystko wraca samo. Wrócić możesz też wcześniej.'
                    : 'Profile dzieci, postępy, ulubione i naklejki zostają w aplikacji. '
                          'Gdy wrócicie, zaczniecie tam, gdzie skończyliście.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 18),
              if (android) ...[
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Wstrzymaj na 1–3 miesiące'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Dalej do anulowania'),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (choice != true) return false;
  ref.read(eventSinkProvider).track(AppEvent.cancelReason, props: {'reason': reason.wire, 'choice': 'pause'});
  await openExternal(Uri.parse('https://play.google.com/store/account/subscriptions?package=pl.audiokiddo.app'));
  return true;
}
