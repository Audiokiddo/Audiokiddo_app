import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/content_cover.dart';
import '../family/child_quiz.dart';
import '../family/family.dart';
import '../insights/events.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../reminders/reminder_offer.dart';
import 'microphone_offer.dart';
import 'welcome_controller.dart';

/// The free plays a family gets at the start: one from each pack.
List<ContentItem> welcomeGifts(Catalog catalog) => [
  for (final pack in catalog.packs) ?catalog.items.where((i) => i.packId == pack.id && i.isFree).firstOrNull,
];

/// After the family's first sign-in: a little fanfare with the free plays, the short quiz
/// about the child (the age matches the plays) and reminders. Then Szop’en's tour on Start.
/// The look is automatic (light by day, dark from 20:00), so it is not asked.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Stage { fanfare, quiz, microphone, reminders }

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  _Stage _stage = _Stage.fanfare;

  Future<void> _complete() async {
    final first = ref.read(familyProvider).value?.children.firstOrNull;
    if (first != null) await ref.read(kidsModeProvider).setPreferredAge(first.age);
    ref.read(eventSinkProvider).track(AppEvent.welcomeDone);
    await ref.read(welcomeProvider).complete();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: switch (_stage) {
      _Stage.fanfare => _Fanfare(onNext: () => setState(() => _stage = _Stage.quiz)),
      // Always the child's age (plays are matched to it); a known child is just confirmed.
      _Stage.quiz => ChildQuiz(
        editing: ref.read(familyProvider).value?.active,
        allowSkip: false,
        onDone: () => setState(() => _stage = _Stage.microphone),
      ),
      _Stage.microphone => MicrophoneOffer(onDone: () => setState(() => _stage = _Stage.reminders)),
      _Stage.reminders => ReminderOffer(onDone: _complete),
    },
  );
}

class _Fanfare extends ConsumerWidget {
  const _Fanfare({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final gifts = catalog == null ? const <ContentItem>[] : welcomeGifts(catalog);
    final count = gifts.isEmpty ? 3 : gifts.length;
    const ink = Color(0xFF211C35);
    return Scaffold(
      backgroundColor: AkBrand.sun,
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _Confetti())),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: .3, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) => Transform.scale(scale: v, child: child),
                    child: const SzopSticker(SzopPose.klaszcze, height: 150),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ta-da! Witajcie w AudioKiddo',
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Na dobry początek odbierasz $count darmowe audiozabawy, po jednej z każdego pakietu. '
                  'Są Wasze na zawsze.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: ink),
                ),
                const SizedBox(height: 20),
                for (final item in gifts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          ContentCover(item: item, pack: catalog!.pack(item.packId ?? ''), size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Pakiet ${catalog.pack(item.packId ?? '')?.title ?? ''}',
                                  style: text.bodySmall?.copyWith(color: ink),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.card_giftcard_rounded, color: AkBrand.orange),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: onNext,
                  icon: const Icon(Icons.redeem_rounded),
                  label: const Text('Odbieram!'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper confetti falling once over the fanfare (none when the system asks for less motion).
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  final _pieces = List.generate(48, (i) {
    final r = math.Random(i * 7 + 3);
    return (x: r.nextDouble(), delay: r.nextDouble() * .35, spin: r.nextDouble() * 6, color: i % 4);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false) && !_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_c.value, _pieces)),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.pieces);

  final double t;
  final List<({double x, double delay, double spin, int color})> pieces;
  static const _colors = [AkBrand.teal, AkBrand.orange, AkBrand.lavenderDeep, Colors.white];

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    for (final p in pieces) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local == 0 || local == 1) continue;
      final y = -20 + local * (size.height + 40);
      final x = p.x * size.width + math.sin(local * 8 + p.spin) * 18;
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(local * p.spin * 2)
        ..drawRect(const Rect.fromLTWH(-4, -7, 8, 14), Paint()..color = _colors[p.color])
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
