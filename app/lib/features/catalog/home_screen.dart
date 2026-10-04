import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/golden_hello.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/szop.dart';
import '../family/family.dart' hide progressProvider;
import '../personal/personal_repository.dart';
import '../player/player_providers.dart';
import '../diploma/diploma_screen.dart';
import '../discovery/discovery_model.dart';
import '../discovery/reference_widgets.dart';
import '../purchases/shop.dart';
import '../purchases/shop_screen.dart';
import 'catalog_providers.dart';
import 'seasonal.dart';
import 'widgets/content_cover.dart';
import 'widgets/item_art.dart';
import 'widgets/catalog_loader.dart';

final screenFreeMinutesProvider = Provider<int>((ref) {
  final family = ref.watch(familyProvider).value;
  final since = ref.watch(clockProvider)().subtract(const Duration(days: 7));
  return ((family?.results.where((r) => r.at.isAfter(since)).fold<int>(0, (s, r) => s + r.seconds) ?? 0) +
          59) ~/
      60;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: CatalogLoader(
        builder: (context, catalog) {
          final recent = ref.watch(recentProvider).value ?? [];
          final items = [for (final id in recent) ?catalog.item(id)];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  SzopSticker(szopOfTheDay(ref.watch(clockProvider)()).$1, height: 40),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'AudioKiddo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Szukaj zabawy',
                    onPressed: () => context.go('/biblioteka?szukaj=1'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: 'Sklep',
                    onPressed: () => context.push('/sklep'),
                    icon: const Icon(Icons.shopping_bag_outlined),
                  ),
                  IconButton(
                    tooltip: 'Profil dziecka',
                    onPressed: () => context.push('/profil'),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Co dziś\nrobimy?', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              const HeroShelf(),
              const SizedBox(height: 18),
              const _CategoryGrid(),
              const SizedBox(height: 14),
              const _QuickNeeds(),
              RefSection(
                'Kontynuuj słuchanie',
                action: 'Zobacz wszystkie',
                onTap: () => context.push('/historia'),
              ),
              if (items.isEmpty)
                InkWell(
                  onTap: () => context.go('/biblioteka'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.headphones_rounded, color: AkBrand.tealDeep),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pierwsza przygoda czeka w bibliotece.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                )
              else
                for (final item in items.take(2)) AudioRow(item: item, subtitle: _remaining(ref, item)),
              const PendingDiplomaCard(),
              _NextPackCard(catalog: catalog),
              const _NewThings(),
              const _SeasonShelf(),
              const _QuietSzopen(),
              RefSection('Na co dzień', action: 'Wszystkie tryby', onTap: () => context.push('/rutyny')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant_rounded, color: AkBrand.tealDeep),
                title: const Text('Podczas obiadu'),
                subtitle: const Text('Zabawy bez dodatkowych przygotowań'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/ratunku?tryb=obiad'),
              ),
            ],
          );
        },
      ),
    ),
  );
  String _remaining(WidgetRef ref, ContentItem item) {
    final p = ref.watch(progressProvider(item.id)).value;
    if (p == null || p.completed) return '${(item.durationSec / 60).ceil()} min';
    return '${((p.durationMs - p.positionMs).clamp(0, 1 << 40) / 60000).ceil()} min pozostało';
  }
}

class _QuietSzopen extends ConsumerStatefulWidget {
  const _QuietSzopen();
  @override
  ConsumerState<_QuietSzopen> createState() => _QuietSzopenState();
}

class _QuietSzopenState extends ConsumerState<_QuietSzopen> {
  Timer? _timer;
  Timer? _hide;
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 12), () async {
      final s = await ref.read(discoveryProvider.future);
      if (!mounted) return;
      final day = ref.read(clockProvider)().toIso8601String().substring(0, 10);
      if (s.quiet ||
          s.cameoDay == day ||
          ref.read(currentMediaProvider).value != null ||
          !(ModalRoute.of(context)?.isCurrent ?? false) ||
          !TickerMode.valuesOf(context).enabled) {
        return;
      }
      await ref.read(discoveryProvider.notifier).shown(day);
      if (!mounted) return;
      setState(() => _visible = true);
      _hide = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiet = ref.watch(discoveryProvider).value?.quiet ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          if (_visible && !quiet && ref.watch(currentMediaProvider).value == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: referenceMint, borderRadius: BorderRadius.circular(18)),
              child: LightSurface(
                child: Row(
                  children: [
                    SzopSticker(szopOfTheDay(ref.watch(clockProvider)()).$1, height: 56),
                    const SizedBox(width: 8),
                    Expanded(child: Text(szopOfTheDay(ref.watch(clockProvider)()).$2)),
                    IconButton(
                      tooltip: 'Schowaj Szop’ena',
                      onPressed: () => setState(() => _visible = false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showGoldenHello(context),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Zawołaj Szop’ena'),
            ),
          ),
        ],
      ),
    );
  }
}

/// After the child finished a free taste of a pack, its other plays are the natural next step.
/// One quiet card for the parent, closable for a week; never in kids mode, never a modal.
class _NextPackCard extends ConsumerWidget {
  const _NextPackCard({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    if (family == null || child == null) return const SizedBox.shrink();
    final next = nextPackSuggestion(
      results: family.resultsOf(child.id),
      catalog: catalog,
      scopes: ref.watch(activeScopesProvider),
    );
    final hidden = ref.watch(hiddenPackSuggestionProvider).value;
    if (next == null || !ref.watch(hiddenPackSuggestionProvider).hasValue) return const SizedBox.shrink();
    if (hidden != null &&
        hidden.packId == next.pack.pack.id &&
        hidden.until.isAfter(ref.watch(clockProvider)())) {
      return const SizedBox.shrink();
    }
    final paid = next.pack.items.where((i) => !i.isFree).toList();
    final minutes = paid.fold(0, (s, i) => s + i.durationSec) ~/ 60;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: referenceLilac.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox.square(dimension: 64, child: PackArt(summary: next.pack, radius: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chcecie więcej takich zabaw?',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '„${next.tried.title}” jest z pakietu ${next.pack.pack.title}. '
                    'W środku czeka jeszcze ${playsCount(paid.length)}, razem $minutes min bez ekranu.',
                    style: text.bodySmall,
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => openPack(context, next.pack.pack.id),
                    child: const Text('Zobacz pakiet'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Nie teraz',
              onPressed: () => hidePackSuggestion(ref, next.pack.pack.id),
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Nowości": what was released in the last weeks (from the catalog's release dates).
class _NewThings extends ConsumerWidget {
  const _NewThings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(newItemsProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RefSection('Nowości'),
        for (final item in items.take(3)) AudioRow(item: item),
      ],
    );
  }
}

/// The seasonal collection of the catalog: one row that changes with the time of year.
class _SeasonShelf extends ConsumerWidget {
  const _SeasonShelf();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(seasonalShelfProvider);
    final catalog = ref.watch(catalogProvider).value;
    if (shelf == null || catalog == null) return const SizedBox.shrink();
    final items = [for (final id in shelf.itemIds) ?catalog.item(id)];
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RefSection(shelf.title),
        if (shelf.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(shelf.subtitle!, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
          ),
        SizedBox(
          // Cover plus two lines of title, at any text size.
          height: 120 + MediaQuery.textScalerOf(context).scale(40),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 112,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/zabawa/${item.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ContentCover(
                        item: item,
                        size: 112,
                        locked: !ref.watch(canPlayProvider(item)),
                        fresh: ref.watch(isNewItemProvider(item)),
                      ),
                      const SizedBox(height: 6),
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The tiles of the mockup: six kinds of play, each opening the library filtered to it.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const _look = <PlayCategory, (Color, Color, IconData)>{
    PlayCategory.adventure: (AkBrand.sun, Color(0xFF211C35), Icons.rocket_launch_rounded),
    PlayCategory.detective: (referenceLilac, Color(0xFF211C35), Icons.search_rounded),
    PlayCategory.songs: (referenceMint, Color(0xFF211C35), Icons.music_note_rounded),
    PlayCategory.movement: (AkBrand.teal, Color(0xFF10393B), Icons.directions_run_rounded),
    PlayCategory.creative: (Color(0xFF7B5BA6), Colors.white, Icons.palette_rounded),
    PlayCategory.calm: (Color(0xFFCDEDE8), Color(0xFF211C35), Icons.nightlight_round),
  };

  @override
  Widget build(BuildContext context) => TwoColumns(
    children: [
      for (final c in PlayCategory.values)
        Pressable(
          onTap: () => context.push('/biblioteka?kategoria=${c.name}'),
          child: Semantics(
            button: true,
            label: c.label.replaceAll('\n', ' '),
            excludeSemantics: true,
            child: Container(
              height: 104,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _look[c]!.$1, borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  Icon(_look[c]!.$3, size: 34, color: _look[c]!.$2),
                  const Spacer(),
                  Text(
                    c.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: _look[c]!.$2, fontWeight: FontWeight.w700, height: 1.15),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// "Szybko": the situations a parent is usually in, one tap each.
class _QuickNeeds extends StatelessWidget {
  const _QuickNeeds();

  @override
  Widget build(BuildContext context) {
    final needs = [
      (Icons.schedule_rounded, 'Mam 20 minut', '/ratunku'),
      (Icons.directions_car_rounded, 'W podróży', '/podroz'),
      (Icons.bedtime_rounded, 'Na dobranoc', '/dobranoc'),
      (Icons.auto_awesome_rounded, 'Tryby i rutyny', '/rutyny'),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: needs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          avatar: Icon(needs[i].$1, size: 18),
          label: Text(needs[i].$2),
          onPressed: () => context.push(needs[i].$3),
        ),
      ),
    );
  }
}

/// Plays worth starting now: what is new, then what this child has not heard yet.
final heroItemsProvider = Provider<List<ContentItem>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  final family = ref.watch(familyProvider).value;
  final child = family?.active;
  final played = {
    ...?ref.watch(recentProvider).value,
    if (child != null) ...family!.resultsOf(child.id).map((r) => r.itemId),
  };
  bool fits(ContentItem i) =>
      !played.contains(i.id) &&
      (i.audio.isNotEmpty || i.script != null) &&
      (child == null || (i.ageMin <= child.age && (i.ageMax == null || i.ageMax! >= child.age)));
  final fresh = ref.watch(newItemsProvider).where(fits);
  final rest = catalog.items.where((i) => fits(i) && !fresh.contains(i)).toList()
    ..sort((a, b) {
      int rank(ContentItem i) => ref.watch(canPlayProvider(i)) ? 0 : 1;
      return rank(a).compareTo(rank(b));
    });
  return [...fresh, ...rest].take(4).toList();
});

/// Big covers at the top of Start: one swipe away from something new.
class HeroShelf extends ConsumerWidget {
  const HeroShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(heroItemsProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width - 40;
    return SizedBox(
      height: (width * .62).clamp(190, 300),
      child: PageView.builder(
        padEnds: false,
        controller: PageController(viewportFraction: items.length == 1 ? 1 : .9),
        itemCount: items.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(right: items.length == 1 ? 0 : 12),
          child: _HeroCard(item: items[i]),
        ),
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref.watch(isNewItemProvider(item));
    final text = Theme.of(context).textTheme;
    final age = item.ageMax == null ? '${item.ageMin}+ lat' : '${item.ageMin}–${item.ageMax} lat';
    return Pressable(
      onTap: () => context.push('/zabawa/${item.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ItemArt(item: item),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [.35, 1],
                  colors: [Colors.transparent, Color(0xE61B1530)],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  fresh ? 'Nowość' : 'Jeszcze nie słuchane',
                  style: text.labelMedium?.copyWith(
                    color: const Color(0xFF211C35),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 70,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(item.durationSec / 60).ceil()} min · $age',
                    style: text.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AkBrand.teal, shape: BoxShape.circle),
                child: Icon(
                  ref.watch(canPlayProvider(item)) ? Icons.play_arrow_rounded : Icons.lock_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
