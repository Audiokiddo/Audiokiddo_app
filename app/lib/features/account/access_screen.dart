import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/backend/backend_config.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../access/access_controller.dart';
import '../catalog/catalog_providers.dart';
import 'sign_in.dart';
import 'account_service.dart';

/// "Gold" for the sentence after a successful claim: what the account got, by name.
String describeScopes(List<String> scopes, Catalog? catalog) {
  if (scopes.contains(Scopes.allContent)) return 'wszystkie pakiety';
  final names = <String>[
    for (final scope in scopes)
      if (scope.startsWith('pack:'))
        'pakiet ${catalog?.pack(scope.substring(5))?.title ?? scope.substring(5)}'
      else if (scope.startsWith('item:'))
        '„${catalog?.item(scope.substring(5))?.title ?? scope.substring(5)}”',
  ];
  return names.isEmpty ? 'dostęp' : names.join(', ');
}

/// What to tell the parent about [result]; [forOrder] picks the wording for an order number.
String claimMessage(ClaimResult result, {required bool forOrder, Catalog? catalog}) =>
    switch (result.status) {
      ClaimStatus.ok => 'Gotowe. Dodano: ${describeScopes(result.scopes, catalog)}.',
      ClaimStatus.already => 'Masz już ten dostęp na tym koncie.',
      ClaimStatus.notFound =>
        forOrder
            ? 'Nie znaleźliśmy zamówienia z tym numerem i adresem e-mail. Numer jest w mailu '
                  'z potwierdzeniem, a e-mail to ten, który podałeś w sklepie.'
            : 'Nie znamy takiego kodu. Sprawdź, czy wszystkie znaki się zgadzają.',
      ClaimStatus.expired => 'Ten kod już wygasł.',
      ClaimStatus.usedUp => 'Ten kod został już wykorzystany.',
      ClaimStatus.notPaid =>
        'To zamówienie nie jest opłacone albo zostało zwrócone, więc nie możemy go dodać.',
      ClaimStatus.taken =>
        'To zamówienie jest już przypisane do innego konta. Zaloguj się na to konto albo napisz do '
            'nas: kontakt@audiokiddo.pl.',
      ClaimStatus.nothing => 'W tym zamówieniu nie ma niczego, co można dodać do aplikacji.',
      ClaimStatus.rateLimited => 'Za dużo prób. Spróbuj ponownie za godzinę.',
      ClaimStatus.format =>
        forOrder
            ? 'Podaj numer zamówienia (same cyfry) i adres e-mail z zamówienia.'
            : 'Kod wygląda tak: AK-XXXX-XXXX.',
    };

/// Turns what a user types into capitals, so a code reads the same however it was typed.
class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Access the parent already has from elsewhere: signing in with the e-mail used in the shop
/// (automatic), an order number with its e-mail, or an access code (gift, tester).
/// Parent area; no mention of buying outside the app (App Store 3.1.3(b)).
class AccessScreen extends ConsumerStatefulWidget {
  const AccessScreen({super.key});

  @override
  ConsumerState<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends ConsumerState<AccessScreen> {
  final _code = TextEditingController();
  final _order = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  ({ClaimResult result, bool forOrder})? _last;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _order.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _run(Future<ClaimResult> Function(AccountService) action, {required bool forOrder}) async {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action(ref.read(accountServiceProvider));
      if (result.granted) {
        _code.clear();
        _order.clear();
        await ref.read(accessProvider.notifier).refresh();
      }
      if (mounted) setState(() => _last = (result: result, forOrder: forOrder));
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = accountErrorText(l10n, e.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final signedIn = ref.watch(accountUserProvider).value != null;
    final last = _last;
    return Scaffold(
      appBar: AppBar(title: const Text('Dostęp do pakietów')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Pakiety, które już masz z audiokiddo.pl albo od nas w prezencie, możesz dodać tu na kilka '
              'sposobów.',
              style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
            ),
            const SizedBox(height: 16),
            _Section(
              icon: Icons.mail_outline_rounded,
              title: 'Zaloguj się e-mailem',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signedIn
                        ? 'Jesteś zalogowany. Pakiety z zamówień na ten adres e-mail dodają się same.'
                        : 'Zaloguj się tym samym adresem e-mail, którego użyłeś w sklepie. Pakiety dodadzą się '
                              'same.',
                    style: text.bodyMedium,
                  ),
                  if (!signedIn)
                    TextButton(onPressed: () => context.push('/konto'), child: const Text('Zaloguj się')),
                ],
              ),
            ),
            _Section(
              icon: Icons.receipt_long_rounded,
              title: 'Mam numer zamówienia',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Przydaje się, gdy w sklepie podałeś inny adres e-mail niż ten, którego używasz tutaj.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _order,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9#]'))],
                    decoration: const InputDecoration(labelText: 'Numer zamówienia', hintText: 'np. 7421'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'E-mail z zamówienia'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run((a) => a.claimOrder(_order.text, _email.text), forOrder: true),
                    child: const Text('Dodaj zamówienie'),
                  ),
                ],
              ),
            ),
            if (BackendConfig.redeemCodes)
              _Section(
                icon: Icons.redeem_rounded,
                title: 'Mam kod',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kod z prezentu, od testerów albo z promocji.', style: text.bodyMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: [_UpperCase(), LengthLimitingTextInputFormatter(14)],
                      decoration: const InputDecoration(labelText: 'Kod', hintText: 'AK-XXXX-XXXX'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : () => _run((a) => a.redeemCode(_code.text), forOrder: false),
                      child: const Text('Odbierz dostęp'),
                    ),
                  ],
                ),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error case final error?)
              _Result(message: error, good: false)
            else if (last != null)
              _Result(
                message: claimMessage(last.result, forOrder: last.forOrder, catalog: catalog),
                good: last.result.granted,
                action: last.result.granted && !signedIn
                    ? TextButton(
                        onPressed: () => context.push('/konto'),
                        child: const Text('Zaloguj się, żeby dostęp nie zginął'),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AkBrand.tealDeep),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.message, required this.good, this.action});

  final String message;
  final bool good;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: good ? const Color(0xFFBCE8E3) : const Color(0xFFFFE3CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                good ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: const Color(0xFF211C35),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          ?action,
        ],
      ),
    ),
  );
}
