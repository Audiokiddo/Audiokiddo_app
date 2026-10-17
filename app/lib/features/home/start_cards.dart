import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';

/// The cards on Start that a parent can close for good when they do not use them.
const startCardLabels = <String, String>{
  'moment': 'Teraz: podpowiedź na tę porę dnia',
  'peace': 'Twój tydzień: minuty spokoju',
  'favorite': 'Ulubiona zabawa dziecka',
  'dinner': 'Obiad bez wołania',
  'premiere': 'Odliczanie do nowej zabawy',
};

/// Which of the optional Start cards the parent closed (kept on the phone).
class HiddenStartCards extends AsyncNotifier<Set<String>> {
  static const _key = 'start_hidden_cards';

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<Set<String>> build() async {
    final raw = await _db.readValue(_key) ?? '';
    return {
      for (final id in raw.split(','))
        if (startCardLabels.containsKey(id)) id,
    };
  }

  Future<void> set(String id, {required bool hidden}) async {
    final now = {...?state.value};
    hidden ? now.add(id) : now.remove(id);
    state = AsyncData(now);
    await _db.writeValue(_key, now.join(','));
  }
}

final hiddenStartCardsProvider = AsyncNotifierProvider<HiddenStartCards, Set<String>>(HiddenStartCards.new);

/// True while the card [id] is closed (and while the choice is still loading, so a closed
/// card never flashes up at launch).
bool startCardClosed(WidgetRef ref, String id) {
  final hidden = ref.watch(hiddenStartCardsProvider);
  return hidden.isLoading || (hidden.value?.contains(id) ?? false);
}

/// The small "×" at the corner of an optional Start card.
class StartCardClose extends ConsumerWidget {
  const StartCardClose({super.key, required this.id, this.color});

  final String id;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Ukryj tę kartę',
    visualDensity: VisualDensity.compact,
    iconSize: 20,
    onPressed: () {
      final notifier = ref.read(hiddenStartCardsProvider.notifier);
      unawaited(notifier.set(id, hidden: true));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Ukryto: ${startCardLabels[id]}. Przywrócisz ją w Więcej → Ustawienia i zgody.'),
            action: SnackBarAction(
              label: 'Cofnij',
              onPressed: () => unawaited(notifier.set(id, hidden: false)),
            ),
          ),
        );
    },
    icon: Icon(Icons.close_rounded, color: color),
  );
}

/// In Więcej: which optional cards Start shows.
class StartCardsSwitches extends ConsumerWidget {
  const StartCardsSwitches({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hiddenStartCardsProvider).value ?? const <String>{};
    return Column(
      children: [
        for (final entry in startCardLabels.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value),
            value: !hidden.contains(entry.key),
            onChanged: (on) => ref.read(hiddenStartCardsProvider.notifier).set(entry.key, hidden: !on),
          ),
      ],
    );
  }
}

/// "Kontynuuj słuchanie" closed with its cross: the play it showed (it comes back with the
/// next unfinished play).
class ClosedContinue extends AsyncNotifier<String?> {
  static const _key = 'start_continue_closed';

  @override
  Future<String?> build() => ref.read(databaseProvider).readValue(_key);

  Future<void> close(String itemId) async {
    state = AsyncData(itemId);
    await ref.read(databaseProvider).writeValue(_key, itemId);
  }
}

final closedContinueProvider = AsyncNotifierProvider<ClosedContinue, String?>(ClosedContinue.new);
