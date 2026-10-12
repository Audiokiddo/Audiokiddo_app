import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../access/access_controller.dart';
import '../account/account_service.dart';
import '../parental_gate/parental_gate.dart';
import '../insights/events.dart';

/// What each side gets (the friend and the parent who shared), said the same way everywhere.
final referralGift = '${formatZloty(referralCredit)} na zabawy w aplikacji';

final referralInfoProvider = FutureProvider.autoDispose<ReferralInfo>(
  (ref) => ref.watch(accountServiceProvider).referralInfo(),
);

final creditInfoProvider = FutureProvider.autoDispose<CreditInfo>(
  (ref) => ref.watch(accountServiceProvider).creditOffers(),
);

/// "Poleć znajomym": the parent's code to share. A friend who signs up and enters it gets
/// 30 zł to spend in the app, and so does the parent, for up to 3 friends a year. Below, the
/// parent's credit and what it buys.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  String _message(String code) =>
      'Mam dla Ciebie $referralGift AudioKiddo: audiozabawy, w których dziecko jest bohaterem. '
      'Pobierz aplikację, załóż konto i wpisz kod $code (Sklep → Odbierz dostęp → Mam kod). '
      'https://audiokiddo.pl';

  Future<void> _share(BuildContext context, WidgetRef ref, String code) async {
    final origin = context.findRenderObject() as RenderBox?;
    // Sharing leaves the app, so it asks for an adult (Kids Category).
    if (!await showParentalGate(context) || !context.mounted) return;
    final result = await SharePlus.instance.share(
      ShareParams(
        text: _message(code),
        subject: 'Prezent od AudioKiddo',
        sharePositionOrigin: origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size,
      ),
    );
    // Counted unless dismissed, with the app it went to when the system says (WhatsApp, Messenger…).
    if (result.status != ShareResultStatus.dismissed) {
      ref.read(eventSinkProvider).track(AppEvent.referralShare, props: {'channel': shareChannel(result.raw)});
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(referralInfoProvider);
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Scaffold(
      appBar: AppBar(title: const Text('Poleć znajomym')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const SzopSticker(SzopPose.klaszcze, height: 80),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Oboje zyskujecie. Szop’en dopilnuje rozliczeń.',
                    style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Benefit(
            icon: Icons.card_giftcard_rounded,
            title: 'Znajomy dostaje',
            body: '$referralGift, gdy pobierze AudioKiddo, założy konto i wpisze Twój kod.',
          ),
          _Benefit(
            icon: Icons.celebration_rounded,
            title: 'Ty dostajesz',
            body: '$referralGift za każdego takiego znajomego. Kod nagradza do $referralsPerYear osób w roku.',
          ),
          _Benefit(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Na co wydać',
            body: 'Miesiąc całej biblioteki, pakiet albo pojedyncze zabawy. Środki są tylko do użycia w aplikacji.',
          ),
          const SizedBox(height: 18),
          info.when(
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            ),
            error: (e, _) => Column(
              children: [
                Text(
                  e is AccountException && e.error == AccountError.offline
                      ? 'Bez internetu nie pokażemy Twojego kodu. Połącz się i spróbuj ponownie.'
                      : 'Polecenia ruszą lada dzień. Zajrzyj tu wkrótce.',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(referralInfoProvider),
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
            data: (info) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Twój kod', style: text.labelLarge, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                SelectableText(
                  info.code,
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _share(context, ref, info.code),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Wyślij znajomym'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: info.code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kod skopiowany.')));
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Kopiuj kod'),
                ),
                const SizedBox(height: 18),
                Text(
                  [
                    info.friends == 0 ? 'Nikt jeszcze nie użył Twojego kodu.' : 'Kod użyło: ${info.friends}.',
                    info.leftThisYear == 0
                        ? 'W tym roku kod nagrodził już $referralsPerYear osoby. Znów zadziała od stycznia.'
                        : 'W tym roku kod nagrodzi jeszcze: ${info.leftThisYear}.',
                  ].join(' '),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const CreditSection(),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => context.push('/dostep'),
            child: const Text('Masz kod od znajomego? Wpisz go tutaj'),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AkBrand.tealDeep, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text(body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Twoje środki": the referral credit and what it buys. Spending asks for an adult, then
/// for a confirmation, and opens the content at once.
class CreditSection extends ConsumerStatefulWidget {
  const CreditSection({super.key});

  @override
  ConsumerState<CreditSection> createState() => _CreditSectionState();
}

class _CreditSectionState extends ConsumerState<CreditSection> {
  bool _busy = false;

  Future<void> _spend(CreditOffer offer) async {
    if (!await showParentalGate(context) || !mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(offer.title),
        content: Text('Wykorzystać ${formatZloty(offer.price)} ze środków za polecenia?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Wykorzystaj')),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    String message;
    try {
      final result = await ref.read(accountServiceProvider).spendCredit(offer.scope);
      message = switch (result.status) {
        SpendStatus.ok =>
          offer.scope == 'all_content'
              ? 'Gotowe. Cała biblioteka otwarta na 30 dni więcej.'
              : 'Gotowe. „${offer.title}” jest już Wasze.',
        SpendStatus.insufficient => 'Za mało środków na „${offer.title}”.',
        SpendStatus.owned => 'Masz już „${offer.title}”.',
        SpendStatus.unknown => 'Tego nie da się teraz kupić za środki. Spróbuj ponownie później.',
      };
      if (result.status == SpendStatus.ok) await ref.read(accessProvider.notifier).refresh();
    } on AccountException catch (e) {
      message = e.error == AccountError.offline
          ? 'Bez internetu nie wykorzystasz środków. Połącz się i spróbuj ponownie.'
          : 'Coś poszło nie tak. Spróbuj ponownie za chwilę.';
    }
    ref
      ..invalidate(creditInfoProvider)
      ..invalidate(referralInfoProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final credit = ref.watch(creditInfoProvider).value;
    if (credit == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Twoje środki', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          credit.balance == 0
              ? 'Na razie 0 zł. Gdy znajomy wpisze Twój kod, dostaniesz ${formatZloty(referralCredit)}.'
              : 'Masz ${formatZloty(credit.balance)} do wykorzystania w aplikacji.',
          style: text.bodyMedium,
        ),
        if (credit.balance > 0)
          for (final offer in credit.offers)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(offer.title),
              subtitle: Text(formatZloty(offer.price)),
              trailing: offer.price <= credit.balance
                  ? FilledButton.tonal(
                      onPressed: _busy ? null : () => _spend(offer),
                      child: const Text('Wykorzystaj'),
                    )
                  : Text('brakuje ${formatZloty(offer.price - credit.balance)}', style: text.bodySmall),
            ),
      ],
    );
  }
}

/// A small card on Start: share AudioKiddo, both of you gain.
class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: const Color(0xFFDED0EF),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/polec'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                const SzopSticker(SzopPose.klaszcze, height: 56),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poleć znajomym',
                        style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Ty i znajomy: po $referralGift.',
                        style: text.bodySmall?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
