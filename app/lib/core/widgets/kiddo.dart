import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ambient_motion.dart';
import 'golden_painter.dart';
import 'szop.dart';
export 'golden_painter.dart' show GoldenOutfit, KiddoMood, goldenOutfitAt;

/// Szop’en for the screens built on the older Kiddo API (onboarding, games, kids mode, plan,
/// diplomas): the mood picks his pose from the current artwork.
class Kiddo extends ConsumerStatefulWidget {
  const Kiddo({
    super.key,
    this.size = 160,
    this.mood = KiddoMood.idle,
    this.wave = false,
    this.outfit,
    this.cheeky = false,
  });
  final double size;
  final KiddoMood mood;
  final bool wave, cheeky;
  final GoldenOutfit? outfit;
  @override
  ConsumerState<Kiddo> createState() => _KiddoState();
}

class _KiddoState extends ConsumerState<Kiddo> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(vsync: this, duration: const Duration(seconds: 5));
  bool _foreground = true;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) setState(_sync);
  }

  void _sync() {
    final enabled =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false) &&
        ref.read(ambientMotionProvider);
    _enabled = enabled;
    if (enabled && !_motion.isAnimating) _motion.repeat();
    if (!enabled && _motion.isAnimating) _motion.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ambientMotionProvider);
    _sync();
    // The current Szop’en artwork everywhere; the old drawn raccoon is retired.
    final pose = switch (widget.mood) {
      KiddoMood.sleepy => SzopPose.zmeczony,
      KiddoMood.listening => SzopPose.nasluchuje,
      KiddoMood.talking => widget.cheeky ? SzopPose.chytry : SzopPose.prosi,
      KiddoMood.happy => widget.wave ? SzopPose.klaszcze : SzopPose.zadowolony,
      KiddoMood.idle => widget.cheeky ? SzopPose.chytry : SzopPose.zadowolony,
    };
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.15,
        child: AnimatedBuilder(
          animation: _motion,
          // A gentle bob while the app is in front (off with reduced motion).
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _enabled ? 3 * math.sin(_motion.value * 2 * math.pi * 2) : 0),
            child: child,
          ),
          child: Center(child: SzopSticker(pose, height: widget.size * 1.1)),
        ),
      ),
    );
  }
}
