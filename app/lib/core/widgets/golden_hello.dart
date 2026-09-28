import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/lord/lord_lines.dart';
import '../../features/lord/lord_widgets.dart';
import '../theme/tokens.dart';
import 'kiddo.dart';

/// A user-requested, silent encounter: never talks over an audio activity.
Future<void> showGoldenHello(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  // Above the tab bar, not inside the tab.
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _GoldenHello(),
);

/// Lord Von Ekran introduces himself to the parent: officer's coat, dry lines, no voice.
class _GoldenHello extends ConsumerStatefulWidget {
  const _GoldenHello();
  @override
  ConsumerState<_GoldenHello> createState() => _GoldenHelloState();
}

class _GoldenHelloState extends ConsumerState<_GoldenHello> {
  late String _line = ref.read(lordCursorProvider).next(LordPool.hello);
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Kiddo(size: 160, cheeky: true, wave: true, outfit: GoldenOutfit.official),
          Text(
            'Lord Von Ekran',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(_line, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _line = ref.read(lordCursorProvider).next(LordPool.hello)),
                child: const Text('Masz coś jeszcze?'),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Wybieram zabawę')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dotrzymuję towarzystwa. Nagrania mają pierwszeństwo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.inkMuted),
          ),
        ],
      ),
    ),
  );
}
