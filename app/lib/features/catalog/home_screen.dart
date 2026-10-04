import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/szop.dart';
import '../family/family.dart' hide progressProvider;
import '../personal/personal_repository.dart';
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
                    onPressed: () => context.push('/biblioteka?szukaj=1'),
                    icon: const Icon(Icons.search_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ulubione',
                    onPressed: () => context.push('/ulubione'),
                    icon: const Icon(Icons.favorite_border_rounded),
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
              _PacksShelf(catalog: catalog),
              const _SeasonShelf(),
              const _CategoryGrid(),
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

/// Every pack, owned or not, as one swipeable row: tapping opens the pack page with its plays
/// (locked ones can be previewed there).
class _PacksShelf extends ConsumerWidget {
  const _PacksShelf({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (catalog.packs.isEmpty) return const SizedBox.shrink();
    final scopes = ref.watch(activeScopesProvider);
    final text = Theme.of(context).textTheme;
    final summaries = [for (final p in catalog.packs) PackSummary(p, catalog)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RefSection('Pakiety'),
        SizedBox(
          // Cover plus three lines under it, at any text size.
          height: 150 + MediaQuery.textScalerOf(context).scale(66),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: summaries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final s = summaries[i];
              final owned = ownsPack(scopes, s.pack.id);
              return SizedBox(
                width: 150,
                child: Pressable(
                  onTap: () => openPack(context, s.pack.id),
                  child: Semantics(
                    button: true,
                    label: '${s.pack.title}, ${playsCount(s.items.length)}, ${owned ? 'masz' : 'do odblokowania'}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox.square(
                          dimension: 150,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PackArt(summary: s, radius: 22),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: owned ? AkBrand.teal : AkBrand.sun,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    owned ? Icons.check_rounded : Icons.lock_rounded,
                                    size: 18,
                                    color: owned ? Colors.white : const Color(0xFF211C35),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.pack.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${playsCount(s.items.length)} · ${owned ? 'masz' : 'do odblokowania'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                        ),
                      ],
                    ),
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
              constraints: const BoxConstraints(minHeight: 104),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _look[c]!.$1, borderRadius: BorderRadius.circular(22)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_look[c]!.$3, size: 34, color: _look[c]!.$2),
                  const SizedBox(height: 10),
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
    const colors = [AkBrand.sun, Color(0xFFB8E3DF), Color(0xFFDED0EF), Color(0xFFE5DCEF)];
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < 2; col++) ...[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: colors[row * 2 + col],
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => context.push(needs[row * 2 + col].$3),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(needs[row * 2 + col].$1, size: 30, color: Color(0xFF211C35)),
                                const SizedBox(height: 12),
                                Text(
                                  needs[row * 2 + col].$2,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
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
class HeroShelf extends ConsumerStatefulWidget {
  const HeroShelf({super.key});

  @override
  ConsumerState<HeroShelf> createState() => _HeroShelfState();
}

class _HeroShelfState extends ConsumerState<HeroShelf> {
  late final _controller = PageController(viewportFraction: .9);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(heroItemsProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width - 40;
    return SizedBox(
      // A square cover plus two lines under it.
      height: width * .9 - 12 + MediaQuery.textScalerOf(context).scale(58),
      child: PageView.builder(
        padEnds: false,
        controller: _controller,
        onPageChanged: (p) => setState(() => _page = p),
        itemCount: items.length,
        // The next card peeks in as a hint; only the one in view is a target.
        itemBuilder: (context, i) => ExcludeSemantics(
          excluding: i != _page,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _HeroCard(item: items[i]),
          ),
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
    // Covers carry their own title art: shown whole (square), the title goes underneath.
    return Pressable(
      onTap: () => context.push('/zabawa/${item.id}'),
      child: Semantics(
        button: true,
        label:
            '${fresh ? 'Nowość' : 'Jeszcze nie słuchane'}: ${item.title}, ${(item.durationSec / 60).ceil()} min',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ItemArt(item: item),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AkBrand.sun,
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AkBrand.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
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
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${(item.durationSec / 60).ceil()} min · $age',
              maxLines: 1,
              style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
