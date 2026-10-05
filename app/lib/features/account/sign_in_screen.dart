import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/home_screen.dart' show AudioKiddoLogo;
import 'session_gate.dart';
import 'sign_in.dart';

/// Shown after the parent signs out: sign in to get the family's plays and purchases back.
/// Continuing without an account stays possible (App Store 5.1.1), with free plays only.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  const Center(child: AudioKiddoLogo(height: 44)),
                  const SizedBox(height: 24),
                  const Center(child: SzopSticker(SzopPose.prosi, height: 120)),
                  const SizedBox(height: 16),
                  Text('Zaloguj się', style: text.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Po zalogowaniu wrócą Wasze zabawy, zakupy i abonament. Szop’en pilnuje, żeby nic nie zginęło.',
                    style: text.bodyLarge?.copyWith(color: context.palette.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const SignInOptions(askAdultFirst: true),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await ref.read(sessionGateProvider).clear();
                      if (context.mounted) context.go('/');
                    },
                    child: const Text('Kontynuuj bez konta (tylko darmowe zabawy)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
