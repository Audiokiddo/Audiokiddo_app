import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/catalog_loader.dart';
import '../catalog/widgets/content_cover.dart';
import '../downloads/download_providers.dart';
import '../games/game_controller.dart';
import '../parental_gate/parental_gate.dart';
import '../player/playback_controller.dart';
import 'kids_mode_controller.dart';

import 'dart:math' as math;

import '../../core/audio/kiddo_voice.dart';
import '../../core/widgets/kiddo.dart';
import '../intro/magic_intro.dart';

/// Kids mode: big covers of what the child may play. No prices, locks, links or settings.
/// Whether entering kids mode starts with the magic word (off in tests).
final kidsMagicEntryProvider = Provider<bool>((ref) => true);

/// Once per app run the child says the magic word; afterwards Kiddo just says hello.
class KidsWelcomed extends Notifier<bool> {
  @override
  bool build() => false;

  void done() => state = true;
}

final kidsWelcomedProvider = NotifierProvider<KidsWelcomed, bool>(KidsWelcomed.new);

class KidsHomeScreen extends ConsumerWidget {
  const KidsHomeScreen({super.key});

  Future<void> _exit(BuildContext context, WidgetRef ref) async {
    if (await showParentalGate(context)) await ref.read(kidsModeProvider).exit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(kidsMagicEntryProvider) && !ref.watch(kidsWelcomedProvider)) {
      return MagicIntro(
        stages: const [IntroStage.password, IntroStage.granted],
        onDone: () => ref.read(kidsWelcomedProvider.notifier).done(),
      );
    }
    return Scaffold(
      backgroundColor: context.palette.surfaceMuted,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceMuted,
        automaticallyImplyLeading: false,
        title: Text(l10n.kidsTitle),
        actions: [
          IconButton(
            tooltip: l10n.kidsParentButton,
            icon: const Icon(Icons.lock_person_rounded),
            onPressed: () => _exit(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          const _KiddoHello(),
          Expanded(
            child: CatalogLoader(builder: (context, catalog) => _KidsGrid(catalog: catalog)),
          ),
        ],
      ),
    );
  }
}

/// Kiddo greets the child out loud, with the words in a speech bubble; touch him for more.
class _KiddoHello extends ConsumerStatefulWidget {
  const _KiddoHello();

  @override
  ConsumerState<_KiddoHello> createState() => _KiddoHelloState();
}

class _KiddoHelloState extends ConsumerState<_KiddoHello> {
  final _random = math.Random();
  late int _line = 1 + _random.nextInt(3);
  bool _talking = false;
  late final KiddoVoice _voice = ref.read(kiddoVoiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  @override
  void dispose() {
    unawaited(_voice.stop());
    super.dispose();
  }

  Future<void> _say() async {
    if (!mounted || _talking) return;
    setState(() => _talking = true);
    await _voice.say('kids_$_line');
    if (mounted) setState(() => _talking = false);
  }

  void _another() {
    setState(() => _line = _line % 3 + 1);
    _say();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (_line) {
      1 => l10n.kidsHello1,
      2 => l10n.kidsHello2,
      _ => l10n.kidsHello3,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.s),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.homeKiddo,
            child: GestureDetector(
              onTap: _another,
              child: Kiddo(size: 88, mood: _talking ? KiddoMood.talking : KiddoMood.idle),
            ),
          ),
          const SizedBox(width: AkSpace.s),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 12),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content shown in kids mode for the given settings (public for tests).
List<ContentItem> kidsItems(
  Catalog catalog,
  KidsModeSettings settings, {
  required bool Function(ContentItem) canPlay,
  required Set<String> downloaded,
}) => [
  for (final item in catalog.items)
    if (item.ageMin <= settings.age &&
        canPlay(item) &&
        (!settings.onlyDownloaded || downloaded.contains(item.id)))
      item,
];

class _KidsGrid extends ConsumerWidget {
  const _KidsGrid({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(kidsModeProvider).settings;
    final downloaded = {...?ref.watch(downloadSummaryProvider).value?.itemIds};
    final items = kidsItems(
      catalog,
      settings,
      canPlay: (item) => ref.watch(canPlayProvider(item)),
      downloaded: downloaded,
    );

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AkSpace.l),
          child: Text(
            l10n.kidsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AkSpace.m),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: AkSpace.m,
        crossAxisSpacing: AkSpace.m,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _KidsTile(item: items[i], pack: catalog.pack(items[i].packId ?? '')),
    );
  }
}

class _KidsTile extends ConsumerWidget {
  const _KidsTile({required this.item, this.pack});

  final ContentItem item;
  final Pack? pack;

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    if (item.kind == ContentKind.interactiveGame) {
      unawaited(ref.read(gameControllerProvider.notifier).start(item, resume: true));
      await context.push('/dziecko/gra');
      return;
    }
    try {
      await ref.read(playbackControllerProvider).start(item, album: pack?.title ?? 'AudioKiddo');
      if (context.mounted) await context.push('/dziecko/graj');
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).kidsCannotPlay)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: item.title,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AkRadius.card),
        onTap: () => _play(context, ref),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => ContentCover(item: item, pack: pack, size: c.biggest.shortestSide),
              ),
            ),
            const SizedBox(height: AkSpace.xs),
            Text(
              item.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
