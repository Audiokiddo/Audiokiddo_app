import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../kids_mode/kids_mode_controller.dart';
import 'gate_challenge.dart';

/// Shared across the app so closing and reopening the gate does not reset the lockout.
final _attempts = GateAttempts();

/// Tests only: makes the challenge predictable.
@visibleForTesting
GateChallenge Function()? debugGateChallengeFactory;

/// Whether the parent area asks too. Off: the parent area is opened only by a signed-in
/// parent and the child uses kids mode, so the question appears only when leaving kids
/// mode (parents found it tiresome everywhere else). If App Review (Kids Category,
/// guideline 1.3) asks for a gate before purchases and links, set this to true.
const askInParentArea = false;

/// Asks for an adult before leaving kids mode (and, with [askInParentArea], before
/// purchases, links, sharing and settings; ARCHITECTURE §12). This is NOT age verification
/// or parental consent.
Future<bool> showParentalGate(BuildContext context) async {
  if (!askInParentArea && !ProviderScope.containerOf(context, listen: false).read(kidsModeProvider).active) {
    return true;
  }
  final passed = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<bool>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ParentalGateScreen()));
  return passed ?? false;
}

class ParentalGateScreen extends StatefulWidget {
  const ParentalGateScreen({super.key, this.challengeFactory});

  /// Tests inject a deterministic challenge.
  final GateChallenge Function()? challengeFactory;

  @override
  State<ParentalGateScreen> createState() => _ParentalGateScreenState();
}

class _ParentalGateScreenState extends State<ParentalGateScreen> {
  late GateChallenge _challenge = _next();
  bool _wrong = false;
  Timer? _ticker;

  GateChallenge _next() =>
      widget.challengeFactory?.call() ?? debugGateChallengeFactory?.call() ?? GateChallenge.random();

  @override
  void initState() {
    super.initState();
    _startTickerIfLocked();
  }

  void _startTickerIfLocked() {
    _ticker?.cancel();
    if (!_attempts.isLocked) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_attempts.isLocked) t.cancel();
      setState(() {});
    });
  }

  void _answer(int value) {
    if (_challenge.check(value)) {
      _attempts.recordSuccess();
      Navigator.pop(context, true);
      return;
    }
    _attempts.recordFailure();
    setState(() {
      _wrong = true;
      _challenge = _next();
    });
    _startTickerIfLocked();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final locked = _attempts.isLocked;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.cancel,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AkSpace.l),
          children: [
            Icon(Icons.family_restroom_rounded, size: 56, color: context.palette.primary),
            const SizedBox(height: AkSpace.m),
            Text(l10n.gateTitle, style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AkSpace.s),
            Text(l10n.gateForChild, style: text.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: AkSpace.xl),
            if (locked)
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.gateLocked(_attempts.remainingLock.inSeconds + 1),
                  style: text.titleMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Text(l10n.gateForParent, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AkSpace.s),
              Text(_challenge.targetWords, style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AkSpace.l),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AkSpace.m,
                crossAxisSpacing: AkSpace.m,
                childAspectRatio: 2,
                children: [
                  for (final option in _challenge.options)
                    OutlinedButton(
                      onPressed: () => _answer(option),
                      child: Text('$option', style: text.headlineSmall),
                    ),
                ],
              ),
              if (_wrong) ...[
                const SizedBox(height: AkSpace.m),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.gateWrong,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
