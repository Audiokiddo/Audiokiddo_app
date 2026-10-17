import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../catalog/catalog_providers.dart';

/// How long until the play ends, large enough to read from across the room: the parent
/// knows whether there is time for the dishes. With [endsAt] also the clock time it ends.
class PlayCountdown extends StatelessWidget {
  const PlayCountdown({super.key, required this.remaining, this.color, this.showEnd = true, this.approximate = false});

  final Duration remaining;
  final Color? color;

  /// "koniec ok. 18:42" under the time (off while paused: the end moves).
  final bool showEnd;

  /// Games have no fixed length: "ok. 6 min" instead of a ticking clock.
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    final minutes = (remaining.inSeconds / 60).ceil();
    final value = approximate
        ? (minutes <= 1 ? 'Zaraz koniec' : 'ok. $minutes min')
        : formatClock(remaining);
    final end = DateTime.now().add(remaining);
    final endLabel = 'koniec ok. ${end.hour}:${end.minute.toString().padLeft(2, '0')}';
    return Semantics(
      label: approximate ? 'Do końca $value' : 'Do końca $value, $endLabel',
      excludeSemantics: true,
      child: Column(
        children: [
          Text('Do końca', style: text.labelLarge?.copyWith(color: ink.withValues(alpha: .7))),
          Text(
            value,
            style: text.displaySmall?.copyWith(
              color: ink,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (showEnd && !(approximate && minutes <= 1))
            Text(endLabel, style: text.bodyMedium?.copyWith(color: ink.withValues(alpha: .7))),
        ],
      ),
    );
  }
}

/// A game's countdown: its catalog length from the moment it started, ticking each second.
/// Games wait for answers, so the end is an estimate ("ok. 6 min").
class GameCountdown extends ConsumerStatefulWidget {
  const GameCountdown({super.key, required this.itemId, this.color});

  final String? itemId;
  final Color? color;

  @override
  ConsumerState<GameCountdown> createState() => _GameCountdownState();
}

class _GameCountdownState extends ConsumerState<GameCountdown> {
  final _started = DateTime.now();
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(catalogProvider).value?.item(widget.itemId ?? '');
    if (item == null || item.durationSec <= 0) return const SizedBox.shrink();
    final left = Duration(seconds: item.durationSec) - DateTime.now().difference(_started);
    return PlayCountdown(
      remaining: left.isNegative ? Duration.zero : left,
      color: widget.color,
      approximate: true,
    );
  }
}
