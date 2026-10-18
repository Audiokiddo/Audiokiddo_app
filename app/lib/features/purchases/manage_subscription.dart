import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../insights/events.dart';
import '../parental_gate/parental_gate.dart';

/// Why parents leave, one tap (docs/ANEKS-ANALITYCZNY.md: the most valuable answer we can get).
enum CancelReason {
  price('price', 'Za drogo'),
  notUsing('not_using', 'Dziecko już nie korzysta'),
  tooFewNew('few_new', 'Za mało nowych zabaw'),
  technical('technical', 'Coś nie działało'),
  mistake('mistake', 'Kupione przez pomyłkę'),
  other('other', 'Inny powód');

  const CancelReason(this.wire, this.label);

  final String wire;
  final String label;
}

/// What we answer before the cancellation goes on, so a parent leaving over something we can
/// fix hears about it once (no pressure, the way on stays right there).
String? cancelReasonReply(CancelReason reason) => switch (reason) {
  CancelReason.price => 'Plan roczny wychodzi 22,50 zł miesięcznie. Zmienisz go w tych samych ustawieniach.',
  CancelReason.tooFewNew =>
    'Co tydzień dochodzą 2 nowe zabawy, a zapowiedzi widać na Starcie w „Wkrótce w audiokiddo”.',
  CancelReason.technical => 'Przykro nam. Napisz na kontakt@audiokiddo.pl, naprawimy to jak najszybciej.',
  _ => null,
};

/// "Dlaczego chcesz zrezygnować?": one tap from a short list. Null when the parent closes it.
Future<CancelReason?> askCancelReason(BuildContext context) => showModalBottomSheet<CancelReason>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        Text(
          'Dlaczego chcesz zrezygnować?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text('Jedno dotknięcie. Dzięki temu wiemy, co poprawić.'),
        const SizedBox(height: 8),
        for (final r in CancelReason.values)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(r.label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pop(context, r),
          ),
      ],
    ),
  ),
);

void recordCancelReason(WidgetRef ref, CancelReason reason) =>
    ref.read(eventSinkProvider).track(AppEvent.cancelReason, props: {'reason': reason.wire});

/// "Zarządzaj subskrypcją": the parental gate, then the subscription screen (/subskrypcja).
Future<void> manageSubscription(BuildContext context, WidgetRef ref) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  await context.push('/subskrypcja');
}
