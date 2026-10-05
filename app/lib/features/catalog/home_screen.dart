import 'dart:async';

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
import '../home/quick_pick.dart';
import '../purchases/offer_catalog.dart';
import '../purchases/purchase_controller.dart';
import '../purchases/shop.dart';
import '../alerts/alerts.dart';
import '../home/first_play.dart';
import '../promotions/promotions.dart';
import '../rating/rating.dart';
import '../referral/referral_screen.dart';
import '../purchases/shop_screen.dart';
import '../purchases/store_gateway.dart';
import '../downloads/download_providers.dart';
import 'catalog_providers.dart';
import 'library_filter.dart';
import 'seasonal.dart';
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
                  const Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: AudioKiddoLogo(height: 40)),
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
              const _SzopBubble(),
              const AlertsKeeper(),
              const FirstPlayCard(),
              const AccessEndingBanner(),
              const PromotionBanner(),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Co dziś robimy?', maxLines: 1, style: Theme.of(context).textTheme.headlineLarge),
              ),
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
              _OwnedPacks(catalog: catalog),
              const PendingDiplomaCard(),
              const RatingCard(),
              const ReferralCard(),
              _NextPackCard(catalog: catalog),
              _DiscoverPacks(catalog: catalog),
              const UpcomingShelf(),
              const _OfflineCard(),
              const RefSection('Dla wieku'),
              const _AgeRow(),
              const RefSection('Rodzaje zabaw'),
              const _CategoryGrid(),
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

/// What Szop’en says on Start: a tip for this time of day or a joke. He speaks up once when
/// Start opens, then whenever he is tapped; each line goes away by itself.
final startSzopProvider = NotifierProvider<StartSzop, (SzopPose, String)?>(StartSzop.new);

class StartSzop extends Notifier<(SzopPose, String)?> {
  Timer? _hide;
  int _next = 0;
  bool _greeted = false;

  @override
  (SzopPose, String)? build() {
    ref.onDispose(() => _hide?.cancel());
    return null;
  }

  List<(SzopPose, String)> get _lines {
    final now = ref.read(clockProvider)();
    final tips = szopTipsFor(now);
    // Tips first, a joke every third line.
    return [
      for (var i = 0; i < tips.length; i++) ...[
        tips[i],
        if (i % 2 == 1) szopNudges[(now.day + i) % szopNudges.length],
      ],
    ];
  }

  /// Once per app start, a moment after Start shows.
  void greet() {
    if (_greeted) return;
    _greeted = true;
    _next = ref.read(clockProvider)().minute % _lines.length;
    speak();
  }

  void speak() {
    final lines = _lines;
    state = lines[_next++ % lines.length];
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 12), hush);
  }

  void hush() {
    _hide?.cancel();
    state = null;
  }
}

/// Szop’en and his line under the logo. He speaks up a moment after Start opens; a tap shows
/// the next line, a swipe to the left sends him away.
class _SzopBubble extends ConsumerStatefulWidget {
  const _SzopBubble();

  @override
  ConsumerState<_SzopBubble> createState() => _SzopBubbleState();
}

class _SzopBubbleState extends ConsumerState<_SzopBubble> {
  Timer? _greet;

  @override
  void initState() {
    super.initState();
    _greet = Timer(const Duration(seconds: 2), () {
      if (mounted && !(ref.read(discoveryProvider).value?.quiet ?? false)) {
        ref.read(startSzopProvider.notifier).greet();
      }
    });
  }

  @override
  void dispose() {
    _greet?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = ref.watch(startSzopProvider);
    final show = line != null && !(ref.watch(discoveryProvider).value?.quiet ?? false);
    const ink = Color(0xFF211C35);
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Dismissible(
                key: ValueKey(line),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref.read(startSzopProvider.notifier).hush(),
                child: GestureDetector(
                  onTap: () => ref.read(startSzopProvider.notifier).speak(),
                  child: Semantics(
                    liveRegion: true,
                    button: true,
                    label: 'Szop’en mówi: ${line.$2}. Stuknij po kolejną poradę.',
                    excludeSemantics: true,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                      decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          SzopSticker(line.$1, height: 52),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line.$2,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: ink, fontWeight: FontWeight.w600, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Ages as three big chips, each opening the library for that age.
class _AgeRow extends StatelessWidget {
  const _AgeRow();

  @override
  Widget build(BuildContext context) {
    const ages = [(3, 5, AkBrand.sun), (5, 7, Color(0xFFB8E3DF)), (7, 9, Color(0xFFDED0EF))];
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final (i, (from, to, color)) in ages.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push(LibraryFilter(age: to, ageFrom: from).toLocation()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Text(
                        '$from–$to',
                        style: text.titleLarge?.copyWith(
                          color: const Color(0xFF211C35),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('lat', style: text.bodySmall?.copyWith(color: const Color(0xFF211C35))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Plays work without the internet once downloaded: said plainly on Start.
class _OfflineCard extends ConsumerWidget {
  const _OfflineCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(downloadSummaryProvider).value?.itemIds.length ?? 0;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: referenceMint,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/pobrane'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.offline_pin_rounded, size: 34, color: Color(0xFF0E3437)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zabawy bez internetu',
                        style: text.titleSmall?.copyWith(
                          color: const Color(0xFF211C35),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        count == 0
                            ? 'Pobierz je przed drogą do auta, samolotu czy na działkę.'
                            : 'Pobrane: ${playsCount(count)}. Dobierz kolejne, całe pakiety jednym przyciskiem.',
                        style: text.bodySmall?.copyWith(color: const Color(0xFF211C35)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF211C35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The brand logo, in the text colour of the theme (dark on light, light on dark).
class AudioKiddoLogo extends StatelessWidget {
  const AudioKiddoLogo({super.key, this.height = 36});

  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'AudioKiddo',
    image: true,
    excludeSemantics: true,
    child: Image.asset(
      'assets/brand/logo.png',
      height: height,
      fit: BoxFit.contain,
      color: Theme.of(context).colorScheme.onSurface,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium,
    ),
  );
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

/// The packs the family has: how far the child got and how much is still waiting, so the
/// next play is one tap away (and an unfinished pack quietly asks to be finished).
class _OwnedPacks extends ConsumerWidget {
  const _OwnedPacks({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopes = ref.watch(activeScopesProvider);
    final owned = [
      for (final p in catalog.packs)
        if (ownsPack(scopes, p.id)) PackSummary(p, catalog),
    ];
    if (owned.isEmpty) return const SizedBox.shrink();
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final heardIds = child == null
        ? const <String>{}
        : {
            for (final r in family!.resultsOf(child.id))
              if (r.completed) r.itemId,
          };
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RefSection('Wasze pakiety'),
        SizedBox(
          height: 128 + MediaQuery.textScalerOf(context).scale(66),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: owned.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final s = owned[i];
              final heard = s.items.where((it) => heardIds.contains(it.id)).length;
              final left = s.items.length - heard;
              return SizedBox(
                width: 128,
                child: Pressable(
                  onTap: () => openPack(context, s.pack.id),
                  child: Semantics(
                    button: true,
                    label: '${s.pack.title}, przesłuchane $heard z ${s.items.length}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox.square(dimension: 128, child: PackArt(summary: s, radius: 20)),
                        const SizedBox(height: 6),
                        Text(
                          s.pack.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: s.items.isEmpty ? 0 : heard / s.items.length,
                            minHeight: 5,
                            color: AkBrand.teal,
                            backgroundColor: AkBrand.teal.withValues(alpha: .15),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          left == 0 ? 'Wszystko przesłuchane!' : 'Czeka jeszcze ${playsCount(left)}',
                          maxLines: 1,
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

/// Packs the family does not have yet, laid out to make the choice easy and honest: what the
/// child gets (minutes without a screen, what it practises), a free taste before paying, the
/// price per play next to the pack price, and the bundle when it saves money. Never a timer,
/// never "only today": buying happens on the pack page, behind the parental gate.
class _DiscoverPacks extends ConsumerWidget {
  const _DiscoverPacks({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopes = ref.watch(activeScopesProvider);
    if (scopes.contains(Scopes.allContent)) return const SizedBox.shrink();
    final all = [for (final p in catalog.packs) PackSummary(p, catalog)];
    final locked = [
      for (final s in all)
        if (!ownsPack(scopes, s.pack.id)) s,
    ];
    if (locked.isEmpty) return const SizedBox.shrink();
    final products = ref.watch(storeProductsProvider(productsKey(shopProductIds(catalog))));
    final byId = {for (final p in products.value ?? const <StoreProduct>[]) p.id: p};
    final ownedCount = all.length - locked.length;
    final plays = locked.fold(0, (n, s) => n + s.items.length);
    final minutes = locked.fold(0, (n, s) => n + s.minutes);
    final text = Theme.of(context).textTheme;
    // The bundle that covers the most of what is missing, when the store knows its price.
    final bundle = [ProductIds.bundleThree, ProductIds.bundleTwo]
        .map((id) => (id: id, product: byId[id], packs: bundlePacks(id, catalog)))
        .where((b) => b.product != null && b.packs.where((p) => !ownsPack(scopes, p.id)).length >= 2)
        .firstOrNull;
    final saved = bundle == null
        ? null
        : bundleSavings(bundle.product!, [for (final p in bundle.packs) byId[p.storeProductId]]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RefSection(ownedCount == 0 ? 'Pakiety przygód' : 'Czeka na odkrycie'),
        Text(
          ownedCount == 0
              ? '$plays zabaw i $minutes minut bez ekranu. W każdym pakiecie część posłuchacie za darmo.'
              : 'Macie $ownedCount z ${all.length} pakietów. Do pełnej kolekcji brakuje $plays zabaw, '
                    'czyli $minutes minut bez ekranu.',
          style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
        ),
        const SizedBox(height: 10),
        // Two packs or more: the year of everything is the natural next step.
        if (ownedCount >= 2)
          _BundleTeaser(
            title: 'Masz $ownedCount z ${all.length} pakietów',
            line: byId[ProductIds.yearly] == null
                ? 'W abonamencie masz wszystkie pakiety, gry i każdą nowość.'
                : 'Za ${byId[ProductIds.yearly]!.price} rocznie masz wszystkie pakiety, gry i każdą nowość. '
                      'Twoje pakiety zostają Twoje na zawsze.',
          ),
        for (final s in locked) _DiscoverCard(summary: s, product: byId[s.pack.storeProductId]),
        if (ownedCount >= 2)
          const SizedBox.shrink()
        else if (bundle != null && saved != null)
          _BundleTeaser(
            title: 'Zestaw ${bundle.packs.length} pakietów',
            line:
                'Taniej o ${formatMoney(saved, bundle.product!.currencyCode)} niż osobno. '
                'Kupujecie raz, zostaje na zawsze.',
            price: bundle.product!.price,
          )
        else
          _BundleTeaser(
            title: 'Wszystko w abonamencie',
            line: 'Każdy pakiet i każda nowość, bez wybierania. Można zrezygnować w każdej chwili.',
          ),
      ],
    );
  }
}

class _DiscoverCard extends ConsumerWidget {
  const _DiscoverCard({required this.summary, this.product});

  final PackSummary summary;
  final StoreProduct? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final free = summary.freeItems.where((i) => ref.watch(canPlayProvider(i))).firstOrNull;
    final perPlay = product?.rawPrice == null || summary.items.isEmpty
        ? null
        : formatMoney(product!.rawPrice! / summary.items.length, product!.currencyCode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => openPack(context, summary.pack.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: referenceLilac.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PackArt(summary: summary, radius: 16),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AkBrand.sun, shape: BoxShape.circle),
                            child: const Icon(Icons.lock_rounded, size: 14, color: ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.pack.title,
                          style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${playsCount(summary.items.length)} · ${summary.minutes} min · od ${summary.pack.ageMin} lat',
                          style: text.bodySmall?.copyWith(color: ink),
                        ),
                        if (summary.skills.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ćwiczy: ${summary.skills.take(3).join(', ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: ink, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (free != null)
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AkBrand.tealDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () => startItem(context, free),
                        child: const Text('Posłuchaj za darmo', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  if (free != null) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (product != null)
                          Text(
                            product!.price,
                            style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                          ),
                        Text(
                          perPlay == null ? 'Zobacz pakiet' : 'ok. $perPlay za zabawę',
                          textAlign: TextAlign.end,
                          style: text.labelSmall?.copyWith(color: ink),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleTeaser extends StatelessWidget {
  const _BundleTeaser({required this.title, required this.line, this.price});

  final String title;
  final String line;
  final String? price;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Material(
      color: AkBrand.sun,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.go('/sklep'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              const SzopSticker(SzopPose.chytry, height: 60),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                    ),
                    Text(line, style: text.bodySmall?.copyWith(color: ink)),
                  ],
                ),
              ),
              if (price != null) ...[
                const SizedBox(width: 8),
                Text(
                  price!,
                  style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                ),
              ],
              const Icon(Icons.chevron_right_rounded, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six kinds of play, each opening the library filtered to it.
class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) => TwoColumns(
    children: [
      for (final c in ref.watch(shownCategoriesProvider))
        CategoryTile(category: c, onTap: () => context.push('/biblioteka?kategoria=${c.name}')),
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
      (Icons.offline_pin_rounded, 'Pobierz offline', '/pobrane'),
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
  final picks = [...fresh, ...rest].where((i) => i.id != _closingPlayId).take(2).toList();
  // "Prawda czy nie?" always closes the row: a quick game for any moment.
  final closing = catalog.item(_closingPlayId);
  return [...picks, ?closing];
});

const _closingPlayId = 'prawda-czy-nie';

/// Big covers at the top of Start: one swipe away from something new.
class HeroShelf extends ConsumerStatefulWidget {
  const HeroShelf({super.key});

  @override
  ConsumerState<HeroShelf> createState() => _HeroShelfState();
}

class _HeroShelfState extends ConsumerState<HeroShelf> {
  static const _fraction = .66;
  late final _controller = PageController(viewportFraction: _fraction);
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
      height: width * _fraction - 12 + MediaQuery.textScalerOf(context).scale(58),
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
                          fresh
                              ? 'Nowość'
                              : item.id == _closingPlayId
                              ? 'Szybka gra'
                              : 'Jeszcze nie słuchane',
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
