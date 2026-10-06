import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/home_screen.dart' show AudioKiddoLogo;
import '../purchases/shop.dart';
import 'account_service.dart';
import 'sign_in.dart';

/// The only screen without a signed-in parent. Step one asks only for the e-mail; then a
/// known account gets its password field (a forgotten password: a code from the e-mail) and
/// a new address gets the registration (password, consent, a code confirms the e-mail).
/// The router opens the app as soon as the account is signed in.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Step { email, password, code, register, unknown }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  _Step _step = _Step.email;
  bool _checking = false;
  String? _error;

  static final _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final email = _email.text.trim();
    if (!_pattern.hasMatch(email)) {
      setState(() => _error = 'Wpisz poprawny adres e-mail.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final exists = await ref.read(accountServiceProvider).accountExists(email);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _step = switch (exists) {
        true => _Step.password,
        false => _Step.register,
        null => _Step.unknown,
      };
    });
  }

  void _back() => setState(() {
    _step = _Step.email;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final email = _email.text.trim();
    final emailChip = Row(
      children: [
        const Icon(Icons.mail_outline_rounded, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(email, overflow: TextOverflow.ellipsis, style: text.titleSmall),
        ),
        TextButton(onPressed: _back, child: const Text('Zmień')),
      ],
    );
    return PopScope(
      // Back from a later step returns to the e-mail; from the e-mail there is nowhere to go.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step != _Step.email) _back();
      },
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
                  Center(
                    child: SzopSticker(
                      _step == _Step.register ? SzopPose.zadowolony : SzopPose.prosi,
                      height: 96,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...switch (_step) {
                    _Step.email => [
                      Text(
                        'Zaloguj się lub załóż konto',
                        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Podaj e-mail rodzica. Sprawdzimy, czy masz już konto.',
                        style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _email,
                        enabled: !_checking,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _next(),
                        decoration: InputDecoration(labelText: 'E-mail', errorText: _error),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _checking ? null : _next,
                        child: _checking
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Dalej'),
                      ),
                      const SizedBox(height: 24),
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
                    _Step.password => [
                      emailChip,
                      const SizedBox(height: 8),
                      PasswordSignInForm(
                        key: const ValueKey('password'),
                        email: email,
                        onForgot: () => setState(() => _step = _Step.code),
                      ),
                    ],
                    _Step.code => [
                      emailChip,
                      const SizedBox(height: 8),
                      EmailSignInForm(
                        key: const ValueKey('code'),
                        email: email,
                        autofocus: false,
                        title: 'Zaloguj się kodem',
                        body: 'Wyślemy kod logowania na ten adres. Potem ustawisz nowe hasło w Więcej → Konto i zakupy.',
                        sendLabel: 'Wyślij kod',
                      ),
                      TextButton(
                        onPressed: () => setState(() => _step = _Step.password),
                        child: const Text('Wróć do logowania hasłem'),
                      ),
                    ],
                    _Step.register => [
                      emailChip,
                      const SizedBox(height: 8),
                      EmailSignInForm(
                        key: const ValueKey('register'),
                        email: email,
                        autofocus: false,
                        title: 'Załóż konto rodzica',
                        body:
                            'Tego adresu jeszcze nie znamy. Ustaw hasło, a wyślemy kod, który potwierdzi e-mail. '
                            'Zakupy z audiokiddo.pl na ten adres pojawią się same.',
                        sendLabel: 'Załóż konto',
                        consent: _consent,
                        offerPassword: true,
                      ),
                    ],
                    _Step.unknown => [
                      emailChip,
                      const SizedBox(height: 8),
                      Text(
                        'Nie udało się sprawdzić konta (brak internetu?). Wybierz sam:',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() => _step = _Step.password),
                        child: const Text('Mam konto: zaloguj hasłem'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _step = _Step.register),
                        child: const Text('Nie mam konta: załóż'),
                      ),
                    ],
                  },
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
