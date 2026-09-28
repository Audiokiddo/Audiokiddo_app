import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ambient_motion.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../games/microphone.dart';

enum IntroStage { volume, hello, password, granted }

/// The playful way in, narrated by Kiddo (inspired by the "voice verification" gag of
/// audio-first kids apps): turn the volume up → Kiddo says hello while the logo pops in →
/// say the magic word "Abrakadabra!" → access granted, confetti.
///
/// The magic word is heard through the microphone only when the parent already enabled it
/// for games; otherwise the child says it and touches the magic orb. Nothing is recorded.
class MagicIntro extends ConsumerStatefulWidget {
  const MagicIntro({super.key, this.stages = IntroStage.values, required this.onDone});

  final List<IntroStage> stages;
  final VoidCallback onDone;

  @override
  ConsumerState<MagicIntro> createState() => _MagicIntroState();
}

class _MagicIntroState extends ConsumerState<MagicIntro> {
  int _index = 0;
  int _generation = 0;
  bool _talking = false;
  bool _listeningByMic = false;
  final _levels = List<double>.filled(28, 0.05, growable: true);
  StreamSubscription<List<double>>? _mic;
  SoundDetector? _detector;
  Timer? _fakeWave;
  final _timers = <Timer>[];

  /// Like Future.delayed, but cancelled when the intro closes (never completes then).
  Future<void> _wait(Duration duration) {
    final completer = Completer<void>();
    _timers.add(Timer(duration, completer.complete));
    return completer.future;
  }

  IntroStage get _stage => widget.stages[_index];

  // Kept from initState: dispose() must not touch ref.
  late final KiddoVoice _voice;
  late final MicrophoneInput _micInput;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(kiddoVoiceProvider);
    _micInput = ref.read(microphoneInputProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  @override
  void dispose() {
    _generation++;
    _fakeWave?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    unawaited(_stopMic());
    unawaited(_voice.stop());
    super.dispose();
  }

  Future<void> _say(String line, int generation) async {
    if (!mounted || generation != _generation) return;
    setState(() => _talking = true);
    await _voice.say(line);
    if (mounted && generation == _generation) setState(() => _talking = false);
  }

  Future<void> _enter() async {
    final generation = ++_generation;
    bool current() => mounted && generation == _generation;
    switch (_stage) {
      case IntroStage.volume:
        await Future.wait([_say('volume', generation), _wait(const Duration(milliseconds: 3200))]);
        if (current()) _next();
      case IntroStage.hello:
        _voice.effect('whoosh');
        await _wait(const Duration(milliseconds: 700));
        await _say('hello', generation);
        await _wait(const Duration(milliseconds: 900));
        if (current()) _next();
      case IntroStage.password:
        _listeningByMic = await _startMic();
        if (!current()) return;
        if (!_listeningByMic) _startFakeWave();
        await _say(_listeningByMic ? 'password_voice' : 'password_tap', generation);
      case IntroStage.granted:
        await _stopMic();
        _voice.effect('chime');
        await _say('granted', generation);
        await _wait(const Duration(milliseconds: 900));
        if (current()) widget.onDone();
    }
  }

  void _next() {
    unawaited(_voice.stop());
    if (_index + 1 >= widget.stages.length) {
      _generation++;
      widget.onDone();
      return;
    }
    setState(() {
      _index++;
      _talking = false;
    });
    _enter();
  }

  /// Abrakadabra heard (or the orb touched).
  void _grant() {
    if (_stage != IntroStage.password) return;
    _fakeWave?.cancel();
    _next();
  }

  Future<bool> _startMic() async {
    try {
      if (!await ref.read(microphoneSettingsProvider.future)) return false;
      final samples = await _micInput.start();
      _detector = SoundDetector(sampleRate: micSampleRate);
      _mic = samples.listen(_onSamples, onError: (Object _) => _stopMic());
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> _stopMic() async {
    final mic = _mic;
    _mic = null;
    _detector = null;
    if (mic == null) return;
    await mic.cancel();
    await _micInput.stop();
  }

  void _onSamples(List<double> samples) {
    if (samples.isEmpty || !mounted) return;
    final rms = math.sqrt(samples.fold<double>(0, (sum, s) => sum + s * s) / samples.length);
    _push((rms * 9).clamp(0.05, 1.0));
    final detector = _detector?..add(samples);
    // Wait until the narrator finished, or Kiddo would unlock itself.
    if (detector != null && detector.voiceDetected && !_talking) _grant();
  }

  void _startFakeWave() {
    if (!ref.read(ambientMotionProvider)) return;
    final random = math.Random();
    _fakeWave = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;
      _push(_talking ? 0.25 + random.nextDouble() * 0.6 : 0.05 + random.nextDouble() * 0.12);
    });
  }

  void _push(double level) => setState(() {
    _levels
      ..removeAt(0)
      ..add(level);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = _stage == IntroStage.password;
    final background = switch (_stage) {
      IntroStage.volume => const [Color(0xFFFFF4D6), Color(0xFFFFE3B3)],
      IntroStage.hello => const [Color(0xFF7FD3D6), AkBrand.lavender],
      IntroStage.password => const [Color(0xFF0F1A17), Color(0xFF263B6B)],
      IntroStage.granted => const [AkBrand.sun, AkBrand.orange],
    };
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Impatient? Touch to move on (the magic word waits for the orb or the voice).
          onTap: _stage == IntroStage.volume || _stage == IntroStage.hello ? _next : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: background,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FloatingDoodles(
                    key: ValueKey(dark),
                    color: dark ? AkBrand.sun : AkBrand.ink,
                    opacity: dark ? 0.55 : 0.18,
                    count: dark ? 26 : 14,
                    seed: _index + 3,
                  ),
                ),
                if (_stage == IntroStage.granted) const Positioned.fill(child: ConfettiBurst()),
                // Full size, so every scene is centred (a loose Stack child hugs the left edge).
                Positioned.fill(
                  child: SafeArea(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.92, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_stage),
                        child: switch (_stage) {
                          IntroStage.volume => _VolumeScene(talking: _talking),
                          IntroStage.hello => _HelloScene(talking: _talking),
                          IntroStage.password => _PasswordScene(
                            talking: _talking,
                            byVoice: _listeningByMic,
                            levels: _levels,
                            onOrb: _grant,
                          ),
                          IntroStage.granted => _GrantedScene(talking: _talking),
                        },
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AkSpace.s),
                      child: TextButton(
                        onPressed: () {
                          _generation++;
                          widget.onDone();
                        },
                        style: TextButton.styleFrom(foregroundColor: dark ? Colors.white70 : AkBrand.ink),
                        child: Text(l10n.introSkip),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _title(BuildContext context, Color color) =>
    Theme.of(context).textTheme.displaySmall!
        .copyWith(fontWeight: FontWeight.w800, color: color, height: 1.1);

class _VolumeScene extends ConsumerStatefulWidget {
  const _VolumeScene({required this.talking});

  final bool talking;

  @override
  ConsumerState<_VolumeScene> createState() => _VolumeSceneState();
}

class _VolumeSceneState extends ConsumerState<_VolumeScene> with SingleTickerProviderStateMixin {
  late final _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (ref.read(ambientMotionProvider)) _press.repeat();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Spacer(),
        SizedBox(
          width: 300,
          height: 320,
          child: AnimatedBuilder(
            animation: _press,
            builder: (context, _) {
              // The finger taps the volume button twice per cycle; sound waves answer.
              final t = _press.value;
              final push = math.max(0.0, math.sin(t * math.pi * 4));
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Positioned(
                      right: 8 - i * 14.0,
                      child: Opacity(
                        opacity: (math.sin((t * 2 - i * 0.25) * math.pi * 2) * 0.5 + 0.5) * 0.8,
                        child: Icon(Icons.graphic_eq_rounded, size: 40 + i * 12.0, color: AkBrand.orange),
                      ),
                    ),
                  Container(
                    width: 150,
                    height: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3228),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(blurRadius: 24, color: Color(0x33000000), offset: Offset(0, 10)),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Kiddo(size: 96, mood: widget.talking ? KiddoMood.talking : KiddoMood.idle),
                    ),
                  ),
                  // Volume buttons on the left edge of the phone.
                  Positioned(
                    left: 75 - 4 - push * 2,
                    top: 90,
                    child: Container(width: 6, height: 38, color: AkBrand.orange),
                  ),
                  Positioned(
                    left: 75 - 4,
                    top: 136,
                    child: Container(width: 6, height: 38, color: const Color(0xFF4A3228)),
                  ),
                  Positioned(
                    left: 2 + push * 12,
                    top: 78,
                    child: Transform.rotate(
                      angle: math.pi / 2,
                      child: const Icon(Icons.pan_tool_alt_rounded, size: 64, color: AkBrand.lavenderDeep),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AkSpace.l),
        Text(l10n.introVolumeTitle, style: _title(context, AkBrand.ink), textAlign: TextAlign.center),
        const SizedBox(height: AkSpace.s),
        Text(
          l10n.introVolumeBody,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AkBrand.ink),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _HelloScene extends StatelessWidget {
  const _HelloScene({required this.talking});

  final bool talking;

  static const _letters = 'AUDIOKIDDO';
  static const _colors = [AkBrand.cocoa, AkBrand.terracotta];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Spacer(),
        // Kiddo drops in from above and lands with a bounce.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: -420, end: 0),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.bounceOut,
          builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
          child: Kiddo(size: 200, mood: talking ? KiddoMood.talking : KiddoMood.happy, wave: !talking),
        ),
        const SizedBox(height: AkSpace.l),
        Semantics(
          label: 'AudioKiddo',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, letter) in _letters.split('').indexed)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 900 + i * 110),
                  curve: Interval((600 + i * 110) / (900 + i * 110), 1, curve: Curves.elasticOut),
                  builder: (context, v, child) => Transform.rotate(
                    angle: (1 - v) * (i.isEven ? -0.6 : 0.6),
                    child: Transform.scale(scale: v, child: child),
                  ),
                  child: Text(
                    letter,
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w900, color: _colors[i % 2], letterSpacing: 1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AkSpace.s),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2400),
          curve: const Interval(0.75, 1),
          builder: (context, v, child) => Opacity(opacity: v, child: child),
          child: Text(
            l10n.onboardingHelloSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AkBrand.ink, letterSpacing: 2),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _PasswordScene extends ConsumerStatefulWidget {
  const _PasswordScene({
    required this.talking,
    required this.byVoice,
    required this.levels,
    required this.onOrb,
  });

  final bool talking;
  final bool byVoice;
  final List<double> levels;
  final VoidCallback onOrb;

  @override
  ConsumerState<_PasswordScene> createState() => _PasswordSceneState();
}

class _PasswordSceneState extends ConsumerState<_PasswordScene> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (ref.read(ambientMotionProvider)) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: AkSpace.xl * 2),
        Text(
          l10n.introPasswordTitle,
          style: text.headlineSmall?.copyWith(color: AkBrand.sun, letterSpacing: 3),
        ),
        const SizedBox(height: AkSpace.m),
        Text(l10n.introPasswordSay, style: text.titleLarge?.copyWith(color: Colors.white)),
        ShaderMask(
          shaderCallback: (rect) =>
              const LinearGradient(colors: [AkBrand.sun, AkBrand.orange, Color(0xFFFF6FB5), AkBrand.teal])
                  .createShader(rect),
          child: Text(l10n.introPasswordWord, style: _title(context, Colors.white).copyWith(fontSize: 44)),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: l10n.introPasswordOrb,
          child: GestureDetector(
            onTap: widget.onOrb,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final p = Curves.easeInOut.transform(_pulse.value);
                return Container(
                  width: 210 + p * 16,
                  height: 210 + p * 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFF3C4), AkBrand.sun, Color(0xFF7E57C2)],
                      stops: [0, 0.45, 1],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AkBrand.sun.withValues(alpha: 0.35 + p * 0.3),
                        blurRadius: 40 + p * 30,
                        spreadRadius: 4 + p * 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: Kiddo(size: 120, mood: widget.talking ? KiddoMood.talking : KiddoMood.listening),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 90,
          width: double.infinity,
          child: CustomPaint(painter: _WavePainter(widget.levels)),
        ),
        const SizedBox(height: AkSpace.s),
        Text(
          widget.byVoice ? l10n.introPasswordListening : l10n.introPasswordTap,
          style: text.titleMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: AkSpace.xl),
      ],
    );
  }
}

/// Mirrored bars, brightest in the middle, like a voice-print on a spy screen.
class _WavePainter extends CustomPainter {
  _WavePainter(this.levels);

  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    final n = levels.length;
    final gap = size.width / (n + 1);
    final mid = size.height / 2;
    for (var i = 0; i < n; i++) {
      final fromCentre = (i - n / 2).abs() / (n / 2);
      final h = levels[i] * size.height * (1 - fromCentre * 0.4);
      final x = gap * (i + 1);
      canvas.drawLine(
        Offset(x, mid - h / 2),
        Offset(x, mid + h / 2),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6FB5), AkBrand.sun, Color(0xFFFF6FB5)],
          ).createShader(Rect.fromLTWH(x - 2, mid - h / 2, 4, math.max(h, 1)))
          ..strokeWidth = gap * 0.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}

class _GrantedScene extends StatelessWidget {
  const _GrantedScene({required this.talking});

  final bool talking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.rotate(
            angle: (1 - v) * -0.8,
            child: Transform.scale(scale: v, child: child),
          ),
          child: const ExcludeSemantics(child: Icon(Icons.lock_open_rounded, size: 110, color: Colors.white)),
        ),
        const SizedBox(height: AkSpace.m),
        Text(l10n.introGranted, style: _title(context, Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: AkSpace.l),
        Kiddo(size: 170, mood: talking ? KiddoMood.talking : KiddoMood.happy),
        const Spacer(flex: 2),
      ],
    );
  }
}
