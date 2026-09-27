import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../access/access_controller.dart';
import '../catalog/catalog_providers.dart';
import 'account_service.dart';

/// Parent account: sign in with a one-time e-mail code, see what the account unlocks,
/// sign out, delete the account. Parent zone only — reached through the parental gate.
///
/// Apple 3.1.3(b): no mention of buying outside the app, only of access the parent already has.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(accountUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: SafeArea(child: user == null ? const _SignIn() : _SignedIn(user: user)),
    );
  }
}

String accountErrorText(AppLocalizations l10n, AccountError error) => switch (error) {
  AccountError.invalidEmail => l10n.accountErrorInvalidEmail,
  AccountError.tooManyRequests => l10n.accountErrorTooMany,
  AccountError.wrongCode => l10n.accountErrorWrongCode,
  AccountError.offline => l10n.accountErrorOffline,
  AccountError.server => l10n.accountErrorServer,
};

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _SignIn extends ConsumerStatefulWidget {
  const _SignIn();

  @override
  ConsumerState<_SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<_SignIn> {
  static const resendAfter = 60;

  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  bool _busy = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
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
    final email = _email.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      setState(() => _error = AppLocalizations.of(context).accountErrorInvalidEmail);
      return;
    }
    await _run(() async {
      await ref.read(accountServiceProvider).sendCode(email);
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
    await account.verifyCode(_sentTo!, _code.text);
    // Shop purchases made with this e-mail are assigned now; a failure here is not fatal,
    // the parent can retry from the account screen.
    try {
      await account.syncWebPurchases();
    } on AccountException {
      // ignored, see above
    }
    await ref.read(accessProvider.notifier).refresh();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sentTo = _sentTo;
    return ListView(
      padding: const EdgeInsets.all(AkSpace.m),
      children: [
        Text(l10n.accountIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AkSpace.l),
        if (sentTo == null) ...[
          TextField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendCode(),
            decoration: InputDecoration(labelText: l10n.accountEmailLabel, errorText: _error),
          ),
          const SizedBox(height: AkSpace.m),
          FilledButton(onPressed: _busy ? null : _sendCode, child: Text(l10n.accountSendCode)),
        ] else ...[
          Text(l10n.accountCodeSent(sentTo), style: theme.textTheme.bodyLarge),
          const SizedBox(height: AkSpace.m),
          TextField(
            controller: _code,
            enabled: !_busy,
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
          const SizedBox(height: AkSpace.s),
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
        if (_busy) ...[const SizedBox(height: AkSpace.m), const Center(child: CircularProgressIndicator())],
      ],
    );
  }
}

class _SignedIn extends ConsumerStatefulWidget {
  const _SignedIn({required this.user});

  final AccountUser user;

  @override
  ConsumerState<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends ConsumerState<_SignedIn> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on AccountException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(accountErrorText(l10n, e.error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() {
    final l10n = AppLocalizations.of(context);
    return _run(() async {
      await ref.read(accountServiceProvider).syncWebPurchases();
      await ref.read(accessProvider.notifier).refresh();
    }, done: l10n.accountRefreshed);
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.accountSignOut, l10n.accountSignOutBody, l10n.accountSignOut)) return;
    await _run(() async {
      await ref.read(accountServiceProvider).signOut();
      await ref.read(accessProvider.notifier).refresh();
    });
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirm(l10n.accountDeleteTitle, l10n.accountDeleteBody, l10n.accountDelete)) return;
    await _run(() async {
      await ref.read(accountServiceProvider).deleteAccount();
      await ref.read(accessProvider.notifier).refresh();
    }, done: l10n.accountDeleted);
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(AppLocalizations.of(dialog).cancel),
            ),
            FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalog = ref.watch(catalogProvider).value;
    final now = DateTime.now();
    final active = [
      for (final e in ref.watch(accessProvider).value?.entitlements ?? const <Entitlement>[])
        if (e.isActiveAt(now) && e.source != EntitlementSource.manual) e,
    ];
    return ListView(
      padding: const EdgeInsets.all(AkSpace.m),
      children: [
        Text(
          l10n.accountSignedInAs,
          style: theme.textTheme.bodyMedium?.copyWith(color: context.palette.inkMuted),
        ),
        Text(widget.user.email, style: theme.textTheme.titleLarge),
        const SizedBox(height: AkSpace.l),
        Text(l10n.accountAccess, style: theme.textTheme.titleMedium),
        const SizedBox(height: AkSpace.s),
        if (active.isEmpty)
          Text(l10n.accountNoAccess, style: theme.textTheme.bodyMedium)
        else
          for (final e in active)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_rounded),
              title: Text(_scopeTitle(l10n, e.scope, catalog)),
              subtitle: e.validUntil == null
                  ? null
                  : Text(l10n.accountValidUntil(DateFormat('d.MM.yyyy').format(e.validUntil!.toLocal()))),
            ),
        const SizedBox(height: AkSpace.m),
        OutlinedButton.icon(
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.accountRefresh),
        ),
        const SizedBox(height: AkSpace.s),
        OutlinedButton.icon(
          onPressed: _busy ? null : _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: Text(l10n.accountSignOut),
        ),
        const SizedBox(height: AkSpace.xl),
        TextButton(
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: Text(l10n.accountDelete),
        ),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  static String _scopeTitle(AppLocalizations l10n, String scope, Catalog? catalog) {
    if (scope == Scopes.allContent) return l10n.accountAllContent;
    if (scope.startsWith('pack:')) {
      final id = scope.substring(5);
      final pack = catalog?.pack(id);
      return l10n.accountPack(pack?.title ?? id);
    }
    if (scope.startsWith('item:')) return catalog?.item(scope.substring(5))?.title ?? scope;
    return scope;
  }
}
