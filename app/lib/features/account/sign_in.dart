import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../access/access_controller.dart';
import '../purchases/purchase_controller.dart';
import '../parental_gate/parental_gate.dart';
import 'account_data.dart';
import 'account_service.dart';

String accountErrorText(AppLocalizations l10n, AccountError error) => switch (error) {
  AccountError.invalidEmail => l10n.accountErrorInvalidEmail,
  AccountError.tooManyRequests => l10n.accountErrorTooMany,
  AccountError.wrongCode => l10n.accountErrorWrongCode,
  AccountError.wrongPassword => l10n.accountErrorWrongPassword,
  AccountError.weakPassword => l10n.accountErrorWeakPassword,
  AccountError.offline => l10n.accountErrorOffline,
  AccountError.server => l10n.accountErrorServer,
  AccountError.notConfigured => l10n.signInNotConfigured,
  AccountError.canceled => '',
  AccountError.noAccount => 'Nie ma konta z tym adresem e-mail. Jeśli je usunąłeś, załóż konto na nowo.',
  AccountError.accountExists => 'Konto z tym adresem już istnieje. Zaloguj się hasłem albo kodem.',
};

/// After any sign-in: assign shop purchases made with this e-mail (not fatal if it fails,
/// the account screen can retry) and recompute what the device may play.
Future<void> afterSignIn(WidgetRef ref) async {
  // Another account than last time: the previous family's data leaves the phone.
  final user = ref.read(accountServiceProvider).current;
  if (user != null) await claimFamilyDataFor(ref, user.id);
  try {
    await ref.read(accountServiceProvider).syncWebPurchases();
  } on AccountException {
    // retried from the account screen
  }
  await ref.read(accessProvider.notifier).refresh();
  // Store purchases made before signing in belong to an anonymous holder; restoring moves
  // them to this account (the verification runs as the purchases come back).
  unawaited(ref.read(purchaseControllerProvider.notifier).restoreQuietly());
}

/// "Continue with Apple / Google / e-mail", Apple-style: full-width, same height, Apple on
/// top (App Store guideline 4.8 wants it at least as prominent as Google).
class SignInOptions extends ConsumerStatefulWidget {
  const SignInOptions({super.key, this.askAdultFirst = false, this.showEmail = true});

  /// Onboarding: show the parental gate before the first sign-in attempt.
  final bool askAdultFirst;

  /// The e-mail button (off where the e-mail form is already on screen).
  final bool showEmail;

  @override
  ConsumerState<SignInOptions> createState() => _SignInOptionsState();
}

class _SignInOptionsState extends ConsumerState<SignInOptions> {
  bool _busy = false;
  bool _adultConfirmed = false;

  Future<bool> _adult() async {
    if (!widget.askAdultFirst || _adultConfirmed) return true;
    return _adultConfirmed = await showParentalGate(context);
  }

  Future<void> _run(Future<void> Function(AccountService) signIn) async {
    if (_busy || !await _adult() || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await signIn(ref.read(accountServiceProvider));
      await afterSignIn(ref);
    } on AccountException catch (e) {
      if (e.error != AccountError.canceled) {
        messenger.showSnackBar(SnackBar(content: Text(accountErrorText(l10n, e.error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _email() async {
    if (_busy || !await _adult() || !mounted) return;
    await showEmailSignInSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountServiceProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (account.appleAvailable) ...[
          _ProviderButton(
            label: l10n.signInApple,
            background: dark ? Colors.white : Colors.black,
            foreground: dark ? Colors.black : Colors.white,
            leading: Icon(Icons.apple, size: 24, color: dark ? Colors.black : Colors.white),
            onPressed: _busy ? null : () => _run((a) => a.signInWithApple()),
          ),
          const SizedBox(height: 12),
        ],
        _ProviderButton(
          label: l10n.signInGoogle,
          background: Colors.white,
          foreground: const Color(0xFF1F1F1F),
          border: const Color(0xFF747775),
          leading: const GoogleLogo(size: 20),
          onPressed: _busy ? null : () => _run((a) => a.signInWithGoogle()),
        ),
        if (widget.showEmail) ...[
          const SizedBox(height: 12),
          _ProviderButton(
            label: l10n.signInEmail,
            background: context.palette.primary,
            foreground: context.palette.onPrimary,
            leading: Icon(Icons.mail_rounded, size: 22, color: context.palette.onPrimary),
            onPressed: _busy ? null : _email,
          ),
        ],
        if (_busy) ...[const SizedBox(height: AkSpace.m), const Center(child: CircularProgressIndicator())],
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.leading,
    required this.onPressed,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Widget leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: background.withValues(alpha: 0.6),
      disabledForegroundColor: foreground.withValues(alpha: 0.6),
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: border == null ? BorderSide.none : BorderSide(color: border!),
      ),
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(child: leading),
        const SizedBox(width: 10),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

/// The four-colour Google "G" for the sign-in button (Google branding guidelines).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double rad(double deg) => deg * math.pi / 180;
    canvas.drawArc(rect, rad(-40), rad(85), false, arc(_blue));
    canvas.drawArc(rect, rad(45), rad(90), false, arc(_green));
    canvas.drawArc(rect, rad(135), rad(90), false, arc(_yellow));
    canvas.drawArc(rect, rad(225), rad(95), false, arc(_red));
    // The bar of the G.
    canvas.drawRect(
      Rect.fromLTRB(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width - stroke / 4,
        size.height / 2 + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> showEmailSignInSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (sheet) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
    child: EmailSignInForm(onSignedIn: () => Navigator.of(sheet).pop()),
  ),
);

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// E-mail → one-time code → signed in. Used in a sheet (onboarding, account screen).
class EmailSignInForm extends ConsumerStatefulWidget {
  const EmailSignInForm({
    super.key,
    this.onSignedIn,
    this.title,
    this.body,
    this.sendLabel,
    this.consent,
    this.autofocus = true,
    this.offerPassword = false,
  });

  final VoidCallback? onSignedIn;

  /// Replace the default "Logowanie e-mailem" texts (the sign-in screen's two tabs).
  final String? title;
  final String? body;
  final String? sendLabel;

  /// Shown above the send button; the code is sent only once it is ticked (new accounts).
  final Widget Function(bool value, ValueChanged<bool> onChanged)? consent;
  final bool autofocus;

  /// Registration: e-mail and a required password; the code only confirms the e-mail.
  final bool offerPassword;

  @override
  ConsumerState<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends ConsumerState<EmailSignInForm> {
  static const resendAfter = 60;

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  String? _sentTo;
  bool _busy = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;
  bool _consented = false;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = accountErrorText(AppLocalizations.of(context), e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    // In the order of the fields on screen: the password above, the consent below it.
    if (widget.offerPassword && _password.text.length < minPasswordLength) {
      setState(() => _error = AppLocalizations.of(context).accountErrorWeakPassword);
      return;
    }
    if (widget.consent != null && !_consented) {
      setState(() => _error = 'Zaznacz zgodę na regulamin i politykę prywatności.');
      return;
    }
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = AppLocalizations.of(context).accountErrorInvalidEmail);
      return;
    }
    await _run(() async {
      final account = ref.read(accountServiceProvider);
      if (widget.offerPassword) {
        // Registration: signed in at once, or a code confirms the e-mail first.
        if (!await account.signUp(email, _password.text)) {
          await afterSignIn(ref);
          widget.onSignedIn?.call();
          return;
        }
      } else {
        await account.sendCode(email);
      }
      _code.clear();
      setState(() => _sentTo = email);
      _startCooldown();
    });
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendIn = resendAfter);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _verify() => _run(() async {
    final account = ref.read(accountServiceProvider);
    if (widget.offerPassword) {
      await account.verifySignUp(_sentTo!, _code.text);
    } else {
      await account.verifyCode(_sentTo!, _code.text);
    }
    await afterSignIn(ref);
    widget.onSignedIn?.call();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sentTo = _sentTo;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
      children: [
        Text(
          widget.title ?? l10n.signInEmailTitle,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AkSpace.s),
        if (sentTo == null) ...[
          Text(
            widget.body ?? l10n.signInEmailBody,
            style: theme.textTheme.bodyMedium?.copyWith(color: context.palette.inkMuted),
          ),
          const SizedBox(height: AkSpace.m),
          TextField(
            controller: _email,
            enabled: !_busy,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendCode(),
            decoration: InputDecoration(labelText: l10n.accountEmailLabel, errorText: _error),
          ),
          if (widget.offerPassword) ...[
            const SizedBox(height: AkSpace.s),
            PasswordField(controller: _password, label: 'Hasło (min. 8 znaków)', enabled: !_busy),
          ],
          if (widget.consent case final consent?) ...[
            const SizedBox(height: AkSpace.s),
            consent(_consented, (v) => setState(() => _consented = v)),
          ],
          const SizedBox(height: AkSpace.m),
          FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: Text(widget.sendLabel ?? l10n.accountSendCode),
          ),
        ] else ...[
          Text(l10n.accountCodeSent(sentTo), style: theme.textTheme.bodyMedium),
          const SizedBox(height: AkSpace.m),
          TextField(
            controller: _code,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _verify(),
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6),
            decoration: InputDecoration(labelText: l10n.accountCodeLabel, errorText: _error),
          ),
          const SizedBox(height: AkSpace.m),
          FilledButton(onPressed: _busy ? null : _verify, child: Text(l10n.accountVerify)),
          TextButton(
            onPressed: _busy || _resendIn > 0 ? null : _sendCode,
            child: Text(_resendIn > 0 ? l10n.accountResendIn(_resendIn) : l10n.accountResend),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _sentTo = null;
                    _error = null;
                  }),
            child: Text(l10n.accountChangeEmail),
          ),
        ],
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(AkSpace.m),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// A password field with a show/hide button.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    enabled: widget.enabled,
    obscureText: _hidden,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: const [AutofillHints.password],
    onSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        tooltip: _hidden ? 'Pokaż hasło' : 'Ukryj hasło',
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(_hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded),
      ),
    ),
  );
}

/// E-mail and password. "Nie pamiętam hasła" hands over to the code sign-in ([onForgot]);
/// a new password is then set in the account screen.
class PasswordSignInForm extends ConsumerStatefulWidget {
  const PasswordSignInForm({super.key, required this.onForgot});

  final VoidCallback onForgot;

  @override
  ConsumerState<PasswordSignInForm> createState() => _PasswordSignInFormState();
}

class _PasswordSignInFormState extends ConsumerState<PasswordSignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      setState(() => _error = l10n.accountErrorInvalidEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountServiceProvider).signInWithPassword(_email.text, _password.text);
      await afterSignIn(ref);
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = accountErrorText(l10n, e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Zaloguj się hasłem',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AkSpace.m),
        TextField(
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          decoration: InputDecoration(labelText: l10n.accountEmailLabel),
        ),
        const SizedBox(height: AkSpace.s),
        PasswordField(controller: _password, label: 'Hasło', enabled: !_busy, onSubmitted: (_) => _signIn()),
        if (_error != null) ...[
          const SizedBox(height: AkSpace.s),
          Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: AkSpace.m),
        FilledButton(onPressed: _busy ? null : _signIn, child: const Text('Zaloguj')),
        TextButton(onPressed: _busy ? null : widget.onForgot, child: const Text('Nie pamiętam hasła')),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(AkSpace.m),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
