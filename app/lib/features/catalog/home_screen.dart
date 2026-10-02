import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/kiddo.dart';
import '../../core/widgets/golden_hello.dart';
import '../../core/widgets/motion.dart';
import '../family/family.dart' hide progressProvider;
import '../personal/personal_repository.dart';
import '../player/player_providers.dart';
import '../discovery/discovery_model.dart';
import '../discovery/reference_widgets.dart';
import '../lord/lord_lines.dart';
import 'catalog_providers.dart';
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
                    tooltip: 'Profil dziecka',
                    onPressed: () => context.push('/profil'),
                    icon: const Icon(Icons.account_circle_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Czego dziś\npotrzebujesz?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              TwoColumns(
                children: [
                  _Need(
                    'Mam\n20 minut',
                    'Szybkie propozycje',
                    Icons.schedule_rounded,
                    AkBrand.sun,
                    () => context.push('/ratunku'),
                  ),
                  _Need(
                    'Podróżujemy',
                    'Do auta, pociągu, samolotu',
                    Icons.directions_car_rounded,
                    referenceMint,
                    () => context.push('/podroz'),
                  ),
                  _Need(
                    'Trochę\nruchu',
                    'Zabawy pełne energii',
                    Icons.directions_run_rounded,
                    referenceLilac,
                    () => context.push('/biblioteka?kategoria=movement'),
                  ),
                  _Need(
                    'Czas się\nwyciszyć',
                    'Spokojne historie i dźwięki',
                    Icons.bedtime_rounded,
                    referencePurple,
                    () => context.push('/dobranoc'),
                  ),
                ],
              ),
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

class _Need extends StatelessWidget {
  const _Need(this.title, this.hint, this.icon, this.color, this.onTap);
  final String title, hint;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ink = color == referencePurple ? Colors.white : const Color(0xFF211C35);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: ink),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: ink, fontWeight: FontWeight.w700, height: 1.15),
            ),
            const SizedBox(height: 6),
            Text(hint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ink, height: 1.25)),
          ],
        ),
      ),
    );
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
              child: Row(
                children: [
                  const Kiddo(size: 42, cheeky: true, outfit: GoldenOutfit.official),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lordLine(LordPool.hello, ref.watch(clockProvider)().difference(DateTime(2026)).inDays),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Schowaj Szop’ena',
                    onPressed: () => setState(() => _visible = false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
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
