import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/grouped_list.dart';
import '../../l10n/app_localizations.dart';
import '../access/access_controller.dart';
import '../catalog/catalog_providers.dart';
import 'account_service.dart';
import 'sign_in.dart';
import '../player/player_providers.dart';
import 'session_gate.dart';

/// Parent account, laid out like iOS Settings: sign in with Apple, Google or an e-mail code;
/// see what the account unlocks; sign out; delete the account. Parent zone only — reached
/// through the parental gate.
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
      body: SafeArea(child: user == null ? const _SignedOut() : _SignedIn(user: user)),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AkSpace.l),
      children: [
        ExcludeSemantics(
          child: Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.palette.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.person_rounded, size: 44, color: context.palette.onPrimary),
            ),
          ),
        ),
        const SizedBox(height: AkSpace.m),
        Text(
          l10n.accountSignedOutTitle,
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AkSpace.s),
        Text(
          l10n.accountIntro,
          style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AkSpace.l),
        const SignInOptions(),
        const SizedBox(height: AkSpace.l),
        Text(
          l10n.signInFooter,
          style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
          textAlign: TextAlign.center,
        ),
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
      try {
        await ref.read(audioHandlerProvider).endSession();
      } on Object {
        // Nothing playing (or no player in this build): signing out goes on.
      }
      await ref.read(accountServiceProvider).signOut();
      await ref.read(accessProvider.notifier).refresh();
      // Back to the sign-in screen: the router follows the gate.
      await ref.read(sessionGateProvider).markSignedOut();
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
    final catalog = ref.watch(catalogProvider).value;
    final now = DateTime.now();
    final active = [
      for (final e in ref.watch(accessProvider).value?.entitlements ?? const <Entitlement>[])
        if (e.isActiveAt(now) && e.source != EntitlementSource.manual) e,
    ];
    return ListView(
      padding: const EdgeInsets.only(top: AkSpace.s),
      children: [
        GroupedSection(
          header: l10n.accountSectionAccount,
          children: [
            GroupedRow(
              icon: Icons.person_rounded,
              title: widget.user.email,
              subtitle: l10n.accountSignedInAs,
            ),
          ],
        ),
        GroupedSection(
          header: l10n.accountAccess,
          footer: l10n.accountAccessFooter,
          children: [
            if (active.isEmpty)
              GroupedRow(title: l10n.accountNoAccess)
            else
              for (final e in active)
                GroupedRow(
                  icon: Icons.check_rounded,
                  iconColor: const Color(0xFF2E9D57),
                  title: _scopeTitle(l10n, e.scope, catalog),
                  subtitle: e.validUntil == null
                      ? null
                      : l10n.accountValidUntil(DateFormat('d.MM.yyyy').format(e.validUntil!.toLocal())),
                ),
            GroupedRow(
              icon: Icons.refresh_rounded,
              iconColor: const Color(0xFF2F6FDB),
              title: l10n.accountRefresh,
              onTap: _busy ? null : _refresh,
            ),
            GroupedRow(
              icon: Icons.redeem_rounded,
              iconColor: const Color(0xFF8A5CC9),
              title: 'Kod albo numer zamówienia',
              chevron: true,
              onTap: _busy ? null : () => context.push('/dostep'),
            ),
          ],
        ),
        GroupedSection(
          children: [
            GroupedRow(title: l10n.accountSignOut, onTap: _busy ? null : _signOut, destructive: true),
          ],
        ),
        GroupedSection(
          footer: l10n.accountDeleteFooter,
          children: [GroupedRow(title: l10n.accountDelete, onTap: _busy ? null : _delete, destructive: true)],
        ),
        if (_busy) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  static String _scopeTitle(AppLocalizations l10n, String scope, Catalog? catalog) {
    if (scope == Scopes.allContent) return l10n.accountAllContent;
    if (scope.startsWith('pack:')) {
      final id = scope.substring(5);
      return l10n.accountPack(catalog?.pack(id)?.title ?? id);
    }
    if (scope.startsWith('item:')) return catalog?.item(scope.substring(5))?.title ?? scope;
    return scope;
  }
}
