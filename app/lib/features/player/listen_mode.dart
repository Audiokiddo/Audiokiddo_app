import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';

/// "Razem albo osobno" (research 2026-10-12, finding 10): parents want time together too, not
/// only a break. Both ways work; the app says what helps in each.
enum ListenMode { together, alone }

const _key = 'listen_mode';

class ListenModeController extends AsyncNotifier<ListenMode?> {
  @override
  Future<ListenMode?> build() async => switch (await ref.watch(databaseProvider).readValue(_key)) {
    'together' => ListenMode.together,
    'alone' => ListenMode.alone,
    _ => null,
  };

  Future<void> set(ListenMode mode) async {
    await ref.read(databaseProvider).writeValue(_key, mode.name);
    state = AsyncData(mode);
  }
}

final listenModeProvider = AsyncNotifierProvider<ListenModeController, ListenMode?>(ListenModeController.new);

/// Two questions for after a play heard together, picked by the play so they vary.
List<String> talkQuestions(ContentItem item) {
  const pool = [
    'O czym była ta zabawa?',
    'Co było najśmieszniejsze?',
    'Która odpowiedź była najtrudniejsza?',
    'Kogo albo co spotkaliście po drodze?',
    'Co zrobić inaczej następnym razem?',
    'Jak opowiesz to komuś w domu?',
  ];
  final start = item.id.codeUnits.fold(0, (a, b) => a + b) % pool.length;
  return [pool[start], pool[(start + 3) % pool.length]];
}

/// In the player while a play runs: listen together or let the child play alone, with one
/// line on what helps.
class ListenModeChooser extends ConsumerWidget {
  const ListenModeChooser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(listenModeProvider).value;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<ListenMode>(
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ListenMode.together, label: Text('Słuchamy razem')),
              ButtonSegment(value: ListenMode.alone, label: Text('Dziecko samo')),
            ],
            selected: {?mode},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) ref.read(listenModeProvider.notifier).set(s.first);
            },
          ),
          if (mode != null) ...[
            const SizedBox(height: 6),
            Text(
              mode == ListenMode.alone
                  ? 'Połóż telefon ekranem w dół. Zabawa idzie sama, nic nie trzeba dotykać.'
                  : 'Po zabawie podpowiemy dwa pytania do rozmowy.',
              style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// After a play heard together: two questions to talk about it.
class TalkAfterPlayCard extends ConsumerWidget {
  const TalkAfterPlayCard({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(listenModeProvider).value != ListenMode.together) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do rozmowy po zabawie', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final q in talkQuestions(item))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AkBrand.tealDeep),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q, style: text.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
