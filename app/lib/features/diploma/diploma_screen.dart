import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ambient_motion.dart';
import '../../core/widgets/kiddo.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/catalog_loader.dart';
import '../discovery/reference_widgets.dart';
import '../family/family.dart';
import '../parental_gate/parental_gate.dart';
import '../purchases/shop.dart';
import 'diploma.dart';

const _paper = Color(0xFFFFFBF2);
const _ink = Color(0xFF211C35);

/// The diploma for a finished pack: confetti, a fanfare, Szop'en's congratulations and a
/// secret reward to listen to. Made to be shown to the child; saving it passes the gate.
class DiplomaScreen extends ConsumerWidget {
  const DiplomaScreen({super.key, required this.packId});

  final String packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    backgroundColor: referencePurple,
    body: CatalogLoader(
      builder: (context, catalog) {
        final pack = catalog.pack(packId);
        final child = ref.watch(familyProvider).value?.active;
        if (pack == null || child == null) {
          return const Center(
            child: Text('Ten dyplom jeszcze nie czeka.', style: TextStyle(color: Colors.white)),
          );
        }
        return _DiplomaView(pack: pack, child: child, summary: PackSummary(pack, catalog));
      },
    ),
  );
}

class _DiplomaView extends ConsumerStatefulWidget {
  const _DiplomaView({required this.pack, required this.child, required this.summary});

  final Pack pack;
  final ChildProfile child;
  final PackSummary summary;

  @override
  ConsumerState<_DiplomaView> createState() => _DiplomaViewState();
}

class _DiplomaViewState extends ConsumerState<_DiplomaView> {
  final _card = GlobalKey();
  late final KiddoVoice _voice;
  DateTime? _day;
  bool _rewardPlaying = false;
  bool _rewardHeard = false;
  bool _saving = false;
  Timer? _congrats;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(kiddoVoiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final day = await awardDiploma(ref, widget.child.id, widget.pack.id);
      if (!mounted) return;
      setState(() => _day = day);
      _voice.effect('fanfare');
      _congrats = Timer(const Duration(milliseconds: 1600), () => unawaited(_voice.say('diploma')));
    });
  }

  @override
  void dispose() {
    _congrats?.cancel();
    unawaited(_voice.stop());
    super.dispose();
  }

  Future<void> _reward() async {
    _congrats?.cancel();
    await _voice.stop();
    setState(() => _rewardPlaying = true);
    await _voice.say(bonusLine(widget.pack.id));
    if (mounted) {
      setState(() {
        _rewardPlaying = false;
        _rewardHeard = true;
      });
    }
  }

  Future<void> _save() async {
    if (!await showParentalGate(context) || !mounted) return;
    final origin = context.findRenderObject() as RenderBox?;
    setState(() => _saving = true);
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(p.join((await getTemporaryDirectory()).path, 'dyplom-${widget.pack.id}.png'));
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'Dyplom AudioKiddo: pakiet ${widget.pack.title} ukończony.',
          sharePositionOrigin: origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = ref.watch(ambientMotionProvider) && !MediaQuery.disableAnimationsOf(context);
    final text = Theme.of(context).textTheme;
    return Stack(
      children: [
        Positioned.fill(child: _Confetti(animated: motion)),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Zamknij',
                  color: Colors.white,
                  onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: motion ? 0 : 1, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, t, child) => Transform.scale(
                  scale: .6 + .4 * t,
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                ),
                child: RepaintBoundary(
                  key: _card,
                  child: _DiplomaCard(
                    name: widget.child.name.isEmpty ? 'Mistrz słuchania' : widget.child.name,
                    pack: widget.pack,
                    skills: widget.summary.skills.take(3).toList(),
                    day: _day ?? ref.read(clockProvider)(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_rewardPlaying || _rewardHeard)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: referenceMint, borderRadius: BorderRadius.circular(18)),
                  child: Text(
                    bonusTranscript(widget.pack.id),
                    style: text.bodyLarge?.copyWith(color: _ink, fontWeight: FontWeight.w600),
                  ),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AkBrand.sun,
                  foregroundColor: _ink,
                  disabledBackgroundColor: AkBrand.sun.withValues(alpha: .55),
                  disabledForegroundColor: _ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _rewardPlaying ? null : _reward,
                icon: Icon(_rewardPlaying ? Icons.graphic_eq_rounded : Icons.redeem_rounded),
                label: Text(
                  _rewardPlaying
                      ? 'Szop’en mówi…'
                      : _rewardHeard
                      ? 'Posłuchaj nagrody jeszcze raz'
                      : 'Odbierz nagrodę: sekretna wiadomość',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Zachowaj albo wyślij dyplom'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                child: const Text('Gotowe'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DiplomaCard extends StatelessWidget {
  const _DiplomaCard({required this.name, required this.pack, required this.skills, required this.day});

  final String name;
  final Pack pack;
  final List<String> skills;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          border: Border.all(color: AkBrand.lavender, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const SizedBox(width: 92, height: 104, child: CustomPaint(painter: _RosettePainter())),
            const SizedBox(height: 6),
            Text(
              'DYPLOM',
              style: text.headlineSmall?.copyWith(color: _ink, fontWeight: FontWeight.w900, letterSpacing: 6),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                style: text.headlineMedium?.copyWith(color: AkBrand.tealDeep, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Text('za ukończenie pakietu', style: text.bodyMedium?.copyWith(color: _ink)),
            Text(
              pack.title,
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(color: _ink, fontWeight: FontWeight.w800),
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ćwiczone: ${skills.join(', ')}',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: _ink),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMMM y', 'pl').format(day),
                        style: text.bodySmall?.copyWith(color: _ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Szop’en von Ekran\nkolega na dyżurze',
                        style: text.bodySmall?.copyWith(color: _ink, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const Kiddo(size: 64, mood: KiddoMood.happy, wave: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A prize rosette: sun-yellow petals, a lavender heart with a star, two ribbons.
class _RosettePainter extends CustomPainter {
  const _RosettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.width / 2);
    final r = size.width / 2;
    final ribbon = Paint()..color = AkBrand.teal;
    for (final dx in [-.28, .28]) {
      final x = c.dx + dx * r;
      canvas.drawPath(
        Path()
          ..moveTo(x - r * .2, c.dy)
          ..lineTo(x + r * .2, c.dy)
          ..lineTo(x + r * .2, size.height)
          ..lineTo(x, size.height - r * .18)
          ..lineTo(x - r * .2, size.height)
          ..close(),
        ribbon,
      );
    }
    final petals = Paint()..color = AkBrand.sun;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * .62, r * .32, petals);
    }
    canvas.drawCircle(c, r * .62, Paint()..color = const Color(0xFFE9A800));
    canvas.drawCircle(c, r * .5, Paint()..color = AkBrand.lavender);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r * .32 : r * .14;
      final point = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? star.moveTo(point.dx, point.dy) : star.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Falling confetti behind the diploma; still when motion is reduced.
class _Confetti extends StatefulWidget {
  const _Confetti({required this.animated});

  final bool animated;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7));

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(painter: _ConfettiPainter(_controller), child: const SizedBox.expand()),
    ),
  );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;
  static const _colors = [AkBrand.sun, AkBrand.teal, AkBrand.lavender, Colors.white, AkBrand.coral];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = .6 + rnd.nextDouble() * .8;
      final start = rnd.nextDouble();
      final fall = (start + progress.value * speed) % 1.0;
      final y = -20 + fall * (size.height + 40);
      final sway = math.sin((fall * 6 + i) * math.pi) * 14;
      final spin = (fall * 8 + i) * math.pi;
      canvas
        ..save()
        ..translate(x + sway, y)
        ..rotate(spin)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 9, height: 5),
            const Radius.circular(1.5),
          ),
          Paint()..color = _colors[i % _colors.length].withValues(alpha: .85),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}

/// Start: a finished pack's diploma waits to be handed over (one card, no modal).
class PendingDiplomaCard extends ConsumerWidget {
  const PendingDiplomaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingDiplomaProvider);
    if (pending == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final name = pending.child.name.isEmpty ? 'Dziecko' : pending.child.name;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 40, color: _ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pakiet ${pending.pack.title} ukończony',
                    style: text.titleSmall?.copyWith(color: _ink, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$name: dyplom czeka na wręczenie, a w środku sekretna nagroda od Szop’ena.',
                    style: text.bodySmall?.copyWith(color: _ink),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => context.push('/dyplom/${pending.pack.id}'),
                    child: const Text('Wręcz dyplom'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
