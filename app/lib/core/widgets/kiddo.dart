import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ambient_motion.dart';
import 'golden_painter.dart';
import 'raccoon_painter.dart';
export 'golden_painter.dart' show GoldenOutfit, KiddoMood, goldenOutfitAt;

/// AudioKiddo raccoon. Keeps the existing Kiddo API so every established surface
/// uses the same raccoon, including onboarding, travel, bedtime and interactive games.
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
    final outfit =
        widget.outfit ??
        (widget.mood == KiddoMood.sleepy ? GoldenOutfit.pajamas : goldenOutfitAt(DateTime.now()));
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.15,
          child: AnimatedBuilder(
            animation: _motion,
            builder: (context, _) => CustomPaint(
              painter: RaccoonPainter(
                mood: widget.mood,
                outfit: outfit,
                phase: _enabled ? _motion.value : 0,
                animated: _enabled,
                wave: widget.wave,
                cheeky: widget.cheeky,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
