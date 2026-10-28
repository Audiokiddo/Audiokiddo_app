import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/szop.dart';
import 'acquisition.dart';

/// One optional question at the end of the welcome: where the family heard of us.
/// Without tracking SDKs this is how a channel is tied to families that stay and pay.
class SourceQuestion extends ConsumerWidget {
  const SourceQuestion({super.key, required this.onDone});

  final VoidCallback onDone;

  Future<void> _answer(WidgetRef ref, AcquisitionSource? source) async {
    await saveAcquisitionSource(ref, source);
    onDone();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Align(alignment: Alignment.centerLeft, child: SzopSticker(SzopPose.zdziwiony, height: 96)),
            const SizedBox(height: 16),
            Text('Skąd o nas wiecie?', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Jedno dotknięcie. Dzięki temu wiemy, gdzie mówić o AudioKiddo innym rodzicom.',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in AcquisitionSource.values)
                  ActionChip(
                    label: Text(s.label),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    onPressed: () => _answer(ref, s),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => _answer(ref, null), child: const Text('Pomiń')),
            ),
          ],
        ),
      ),
    );
  }
}
