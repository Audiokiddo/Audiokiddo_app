import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../family/family.dart';
import '../home/quick_pick.dart';
import '../pdf/pdf_screen.dart';

/// Szop’en's Adventure Map (decision 2026-10-15, instead of the development plan): every play
/// the child finishes is one step, and every [chestEvery] steps a chest opens with a reward the
/// child waits for: a secret from Szop’en (a recording) or a sheet of cards to print. Stickers
/// keep coming as before. Counted per child on the phone; nothing is sent.
const chestEvery = 3;

/// How many secrets (assets/audio/rewards/sekret-N.m4a, tool/reward_voice.py) and card sheets
/// (assets/rewards/karty-N.pdf, strona/druk/karty.py --app) there are.
const secretCount = 18;
const cardSheets = <String>[
  'Kiedy gotujesz obiad',
  'Kiedy jedziecie samochodem',
  'Kiedy pada deszcz',
  'Kiedy masz tylko 5 minut',
  'Kiedy trzeba się wyciszyć',
  'Kiedy rozpiera energia',
];

enum RewardKind { secret, cards }

/// What chest number [chest] (1, 2, 3…) holds: secrets and card sheets in turn (two secrets,
/// then a sheet), and round again when all were given.
({RewardKind kind, int number, String title}) rewardForChest(int chest) {
  final sheetsSoFar = chest ~/ 3;
  if (chest % 3 == 0) {
    final n = (sheetsSoFar - 1) % cardSheets.length;
    return (kind: RewardKind.cards, number: n + 1, title: 'Karty do druku: ${cardSheets[n].toLowerCase()}');
  }
  final secret = (chest - sheetsSoFar - 1) % secretCount + 1;
  return (kind: RewardKind.secret, number: secret, title: 'Sekret Szop’ena nr $secret');
}

String secretAsset(int number) => 'assets/audio/rewards/sekret-$number.m4a';
String cardsAsset(int number) => 'assets/rewards/karty-$number.pdf';

/// The active child's place on the map.
typedef AdventureProgress = ({String childName, int steps, int chests, int toNextChest});

AdventureProgress adventureOf(String childName, int finishedPlays) => (
  childName: childName,
  steps: finishedPlays,
  chests: finishedPlays ~/ chestEvery,
  toNextChest: chestEvery - finishedPlays % chestEvery,
);

final adventureProvider = Provider<AdventureProgress?>((ref) {
  final family = ref.watch(familyProvider).value;
  final child = family?.active;
  if (family == null || child == null) return null;
  final finished = family.resultsOf(child.id).where((r) => r.completed).length;
  return adventureOf(child.name, finished);
});

/// Opens what a chest holds: plays the secret, or shows the card sheet to print.
Future<void> openReward(BuildContext context, WidgetRef ref, int chest) async {
  final reward = rewardForChest(chest);
  switch (reward.kind) {
    case RewardKind.secret:
      await ref.read(kiddoVoiceProvider).sayAsset(secretAsset(reward.number));
    case RewardKind.cards:
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfScreen(
            asset: AssetRef(path: cardsAsset(reward.number), bytes: 1, sha256: ''),
            title: 'Karty Szop’ena: ${cardSheets[reward.number - 1]}',
          ),
        ),
      );
  }
}

/// After a finished play in the player: the chest it opened, or how many plays are left to the
/// next one ("Jeszcze 2 zabawy do skrzyni Szop’ena").
class ChestAfterPlayCard extends ConsumerWidget {
  const ChestAfterPlayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(adventureProvider);
    if (a == null || a.steps == 0) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final opened = a.steps % chestEvery == 0;
    final reward = opened ? rewardForChest(a.chests) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: opened ? AkBrand.sun : const Color(0xFFDBCCF0),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: opened ? () => openReward(context, ref, a.chests) : () => context.push('/plan'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(opened ? Icons.card_giftcard_rounded : Icons.redeem_rounded, size: 40, color: ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opened ? 'Skrzynia Szop’ena otwarta!' : 'Mapa przygód: krok ${a.steps}',
                        style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        opened
                            ? '${reward!.title}. Dotknij, żeby ${reward.kind == RewardKind.secret ? 'posłuchać' : 'otworzyć'}.'
                            : a.toNextChest == 1
                            ? 'Jeszcze 1 zabawa do skrzyni Szop’ena!'
                            : 'Jeszcze ${a.toNextChest} zabawy do skrzyni Szop’ena.',
                        style: text.bodyMedium?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
                Icon(opened ? Icons.play_circle_fill_rounded : Icons.chevron_right_rounded, color: ink, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Mapa przygód": the child's path of plays with chests every [chestEvery] steps. Opened
/// chests can be heard or printed again; the next ones show how far they are.
class AdventureMapScreen extends ConsumerWidget {
  const AdventureMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final family = ref.watch(familyProvider).value;
    final a = ref.watch(adventureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa przygód')),
      body: a == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SzopSticker(SzopPose.prosi, height: 120),
                    const SizedBox(height: 12),
                    const Text('Dodaj dziecko, a Szop’en narysuje mu mapę przygód.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: () => context.push('/plan/dziecko'), child: const Text('Dodaj dziecko')),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                if ((family?.children.length ?? 0) > 1) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, c) in family!.children.indexed)
                        ChoiceChip(
                          label: Text(c.name.isEmpty ? 'Dziecko ${i + 1}' : c.name),
                          selected: c.id == family.active?.id,
                          showCheckmark: false,
                          selectedColor: AkBrand.sun,
                          labelStyle: TextStyle(
                            color: c.id == family.active?.id ? const Color(0xFF211C35) : context.palette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) => ref.read(familyProvider.notifier).setActive(c.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const SzopSticker(SzopPose.klaszcze, height: 88),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${a.childName.isEmpty ? 'Twoje dziecko' : a.childName}: ${a.steps} ${_steps(a.steps)} na mapie. '
                        'Co $chestEvery zabawy skrzynia z sekretem Szop’ena albo kartami do druku.',
                        style: text.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => showQuickPick(context),
                  icon: const Icon(Icons.casino_rounded),
                  label: Text(
                    a.toNextChest == 1
                        ? 'Jeszcze 1 zabawa do skrzyni: losuj!'
                        : 'Do skrzyni ${a.toNextChest} zabawy: losuj pierwszą',
                  ),
                ),
                const SizedBox(height: 18),
                for (var chest = a.chests + 3; chest >= 1; chest--)
                  _ChestStop(chest: chest, opened: chest <= a.chests, isNext: chest == a.chests + 1, steps: a.steps),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emoji_emotions_rounded, color: AkBrand.tealDeep),
                  title: const Text('Album naklejek'),
                  subtitle: const Text('Naklejki dochodzą za ukończone zabawy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/naklejki'),
                ),
              ],
            ),
    );
  }

  static String _steps(int n) => n == 1
      ? 'krok'
      : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14))
      ? 'kroki'
      : 'kroków';
}

/// One chest on the path, top (furthest) to bottom (first): opened ones play or print again,
/// the next one shows the plays still needed, later ones stay closed.
class _ChestStop extends ConsumerWidget {
  const _ChestStop({required this.chest, required this.opened, required this.isNext, required this.steps});

  final int chest;
  final bool opened;
  final bool isNext;
  final int steps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final reward = rewardForChest(chest);
    final left = chest * chestEvery - steps;
    const ink = Color(0xFF211C35);
    final bg = opened
        ? AkBrand.sun
        : isNext
        ? const Color(0xFFDBCCF0)
        : palette.surfaceMuted;
    final fg = opened || isNext ? ink : palette.inkMuted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The path: a line through the stops.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Expanded(child: Center(child: Container(width: 4, color: palette.inkMuted.withValues(alpha: .25)))),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: opened ? AkBrand.teal : palette.surface,
                    border: Border.all(color: AkBrand.teal, width: 3),
                  ),
                ),
                Expanded(child: Center(child: Container(width: 4, color: palette.inkMuted.withValues(alpha: .25)))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Material(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: opened ? () => openReward(context, ref, chest) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          opened
                              ? (reward.kind == RewardKind.secret ? Icons.record_voice_over_rounded : Icons.print_rounded)
                              : Icons.lock_rounded,
                          color: fg,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Skrzynia $chest · krok ${chest * chestEvery}',
                                style: text.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                opened
                                    ? reward.title
                                    : isNext
                                    ? (left == 1 ? 'Jeszcze 1 zabawa' : 'Jeszcze $left zabawy')
                                    : 'Niespodzianka',
                                style: text.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        if (opened) Icon(Icons.play_circle_fill_rounded, color: fg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
