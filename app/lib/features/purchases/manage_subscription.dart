import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../insights/events.dart';
import '../parental_gate/parental_gate.dart';
import 'shop.dart';

/// Why parents leave, one tap (docs/ANEKS-ANALITYCZNY.md: the most valuable answer we can get).
enum CancelReason {
  price('price', 'Za drogo'),
  notUsing('not_using', 'Dziecko już nie korzysta'),
  tooFewNew('few_new', 'Za mało nowych zabaw'),
  technical('technical', 'Coś nie działało'),
  changingPlan('changing_plan', 'Tylko zmieniam plan'),
  other('other', 'Inny powód');

  const CancelReason(this.wire, this.label);

  final String wire;
  final String label;
}

/// What we answer before the store's settings open, so a parent leaving over something we can
/// fix hears about it once (no pressure, the button to the store stays right there).
String? cancelReasonReply(CancelReason reason) => switch (reason) {
  CancelReason.price => 'Plan roczny wychodzi 19,99 zł miesięcznie. Zmienisz go w tych samych ustawieniach.',
  CancelReason.tooFewNew =>
    'Nowe zabawy dochodzą regularnie, a zapowiedzi widać na Starcie w „Wkrótce w AudioKiddo”.',
  CancelReason.technical => 'Przykro nam. Napisz na kontakt@audiokiddo.pl, naprawimy to jak najszybciej.',
  _ => null,
};

/// "Zarządzaj subskrypcją": the parental gate, one optional question, then the store's page.
Future<void> manageSubscription(BuildContext context, WidgetRef ref) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  final reason = await showModalBottomSheet<CancelReason>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Text('Zanim przejdziesz do ustawień', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Jeśli myślisz o rezygnacji, powiedz nam dlaczego. Jedno dotknięcie, bez ankiety.'),
          const SizedBox(height: 8),
          for (final r in CancelReason.values)
            ListTile(contentPadding: EdgeInsets.zero, title: Text(r.label), onTap: () => Navigator.pop(context, r)),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pomiń i przejdź do ustawień')),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (reason != null) {
    ref.read(eventSinkProvider).track(AppEvent.cancelReason, props: {'reason': reason.wire});
    final reply = cancelReasonReply(reason);
    if (reply != null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dziękujemy'),
          content: Text(reply),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Zostaję')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Przejdź do ustawień')),
          ],
        ),
      );
      if (go != true || !context.mounted) return;
    }
  }
  await openExternal(manageSubscriptionsUrl);
}
