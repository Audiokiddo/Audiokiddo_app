import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// On a tab's own page (Biblioteka, Sklep, Więcej): a swipe from the left edge slides the page
/// away and goes to Start, the same as the swipe back on every other page. The system back
/// (Android) also goes to Start instead of closing the app.
class BackToStart extends StatefulWidget {
  const BackToStart({super.key, required this.enabled, required this.onBack, required this.child});

  final bool enabled;
  final VoidCallback onBack;
  final Widget child;

  @override
  State<BackToStart> createState() => _BackToStartState();
}

class _BackToStartState extends State<BackToStart> with SingleTickerProviderStateMixin {
  /// 0: in place, 1: slid all the way to the right.
  late final _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  double _width = 1;

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails d) => _slide.value = (_slide.value + d.primaryDelta! / _width).clamp(0, 1);

  Future<void> _end(DragEndDetails d) async {
    final fling = (d.primaryVelocity ?? 0) > 600;
    if (fling || _slide.value > .3) {
      await _slide.animateTo(1, curve: Curves.easeOut);
      widget.onBack();
      _slide.value = 0;
    } else {
      await _slide.animateBack(0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return PopScope(
      canPop: !widget.enabled,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.enabled) widget.onBack();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          return Stack(
            children: [
              // What the sliding page uncovers: the way to Start.
              Positioned.fill(
                child: ColoredBox(
                  color: palette.background,
                  child: AnimatedBuilder(
                    animation: _slide,
                    builder: (context, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: _slide.value * _width,
                        child: Opacity(
                          opacity: (_slide.value * 3).clamp(0, 1),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_rounded, color: palette.primary, size: 32),
                              Text(
                                'Start',
                                style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _slide,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_slide.value * _width, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: _slide.value == 0
                          ? null
                          : const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(-4, 0))],
                    ),
                    child: child,
                  ),
                ),
                child: widget.child,
              ),
              if (widget.enabled)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: _update,
                    onHorizontalDragEnd: _end,
                    onHorizontalDragCancel: () => _slide.animateBack(0),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
