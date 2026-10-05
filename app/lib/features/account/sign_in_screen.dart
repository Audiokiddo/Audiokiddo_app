import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/home_screen.dart' show AudioKiddoLogo;
import '../purchases/shop.dart';
import 'sign_in.dart';

/// The only screen without a signed-in parent: sign in, or create an account. AudioKiddo has
/// no passwords: every sign-in sends a one-time code to the e-mail, so there is nothing to
/// forget or reset. The router opens the app as soon as the account is signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _newAccount = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  const Center(child: AudioKiddoLogo(height: 44)),
                  const SizedBox(height: 16),
                  const Center(child: SzopSticker(SzopPose.prosi, height: 96)),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Zaloguj się'), icon: Icon(Icons.login_rounded)),
                      ButtonSegment(value: true, label: Text('Załóż konto'), icon: Icon(Icons.person_add_alt_1_rounded)),
                    ],
                    selected: {_newAccount},
                    onSelectionChanged: (s) => setState(() => _newAccount = s.single),
                  ),
                  const SizedBox(height: 16),
                  EmailSignInForm(
                    key: ValueKey(_newAccount),
                    autofocus: false,
                    title: _newAccount ? 'Załóż konto rodzica' : 'Zaloguj się',
                    body: _newAccount
                        ? 'Podaj e-mail, wyślemy na niego kod. Po jego wpisaniu konto będzie gotowe, a zakupy z audiokiddo.pl na ten adres pojawią się same.'
                        : 'Podaj e-mail, którego używasz w AudioKiddo. Wyślemy na niego kod logowania.',
                    sendLabel: _newAccount ? 'Załóż konto' : 'Wyślij kod',
                    consent: _newAccount ? _consent : null,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AkBrand.teal.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key_off_rounded, color: AkBrand.tealDeep),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bez haseł: za każdym razem wysyłamy nowy kod na e-mail, więc nie ma czego zapominać ani przypominać. '
                            'Nie ma kodu? Zajrzyj do spamu albo wyślij go ponownie.',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('albo', style: text.bodySmall),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SignInOptions(showEmail: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _consent(bool value, ValueChanged<bool> onChanged) {
    final text = Theme.of(context).textTheme;
    final link = TextStyle(color: AkBrand.tealDeep, decoration: TextDecoration.underline);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: text.bodySmall,
                children: [
                  const TextSpan(text: 'Jestem rodzicem lub opiekunem i akceptuję '),
                  TextSpan(
                    text: 'regulamin',
                    style: link,
                    recognizer: TapGestureRecognizer()..onTap = () => openWithGate(context, termsUrl),
                  ),
                  const TextSpan(text: ' oraz '),
                  TextSpan(
                    text: 'politykę prywatności',
                    style: link,
                    recognizer: TapGestureRecognizer()..onTap = () => openWithGate(context, privacyUrl),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
