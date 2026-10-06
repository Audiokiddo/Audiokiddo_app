import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../account/account_service.dart';
import '../parental_gate/parental_gate.dart';
import '../insights/events.dart';

/// Friend's reward and parent's reward, said the same way everywhere.
const referralFriendGift = '14 dni całej biblioteki za darmo';
const referralParentGift = 'miesiąc całej biblioteki gratis';

final referralInfoProvider = FutureProvider.autoDispose<ReferralInfo>(
  (ref) => ref.watch(accountServiceProvider).referralInfo(),
);

/// "Poleć znajomym": the parent's code to share; the friend gets 14 days, the parent a month
/// after the friend's first purchase.
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  String _message(String code) =>
      'Mam dla Ciebie $referralFriendGift w AudioKiddo: audiozabawy, w których dziecko jest bohaterem. '
      'Pobierz aplikację i wpisz kod $code (Sklep → Odbierz dostęp → Mam kod). https://audiokiddo.pl';

  Future<void> _share(BuildContext context, WidgetRef ref, String code) async {
    ref.read(eventSinkProvider).track(AppEvent.referralShare);
    final origin = context.findRenderObject() as RenderBox?;
    // Sharing leaves the app, so it asks for an adult (Kids Category).
    if (!await showParentalGate(context) || !context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        text: _message(code),
        subject: 'Prezent od AudioKiddo',
        sharePositionOrigin: origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size,
      ),
    );
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
            body: '$referralFriendGift po wpisaniu Twojego kodu.',
          ),
          _Benefit(
            icon: Icons.celebration_rounded,
            title: 'Ty dostajesz',
            body: '$referralParentGift, gdy znajomy kupi abonament lub pakiet. Za każdego znajomego, do 12 miesięcy.',
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
                  info.friends == 0
                      ? 'Nikt jeszcze nie użył Twojego kodu.'
                      : 'Kod użyło: ${info.friends}. Zdobyte miesiące gratis: ${info.rewards}.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
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
                        'Znajomy: $referralFriendGift. Ty: $referralParentGift.',
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
