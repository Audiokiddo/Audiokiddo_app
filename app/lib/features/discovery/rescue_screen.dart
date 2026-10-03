import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/app_theme.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_art.dart';
import '../family/family.dart';
import '../home/quick_pick.dart';
import 'discovery_model.dart';
import 'reference_widgets.dart';

const moodLabels = {
  ChildMood.energetic: 'Pełne energii',
  ChildMood.bored: 'Znudzone',
  ChildMood.grumpy: 'Marudne',
  ChildMood.calm: 'Spokojne',
  ChildMood.sleepy: 'Przed snem',
};
const moodIcons = {
  ChildMood.energetic: Icons.wb_sunny_outlined,
  ChildMood.bored: Icons.sentiment_neutral_rounded,
  ChildMood.grumpy: Icons.sentiment_dissatisfied_rounded,
  ChildMood.calm: Icons.sentiment_satisfied_rounded,
  ChildMood.sleepy: Icons.bedtime_outlined,
};

class RescueScreen extends ConsumerStatefulWidget {
  const RescueScreen({super.key});
  @override
  ConsumerState<RescueScreen> createState() => _RescueScreenState();
}

class _RescueScreenState extends ConsumerState<RescueScreen> {
  int minutes = 20;
  ChildMood mood = ChildMood.bored;
  final materials = <Requirement>{};
  bool results = false;
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final age = ref.watch(familyProvider).value?.active?.age ?? 6;
    final picks = rescuePicks(
      catalog.value?.items ?? [],
      minutes: minutes,
      age: age,
      mood: mood,
      available: materials,
      canPlay: (i) => ref.watch(canPlayProvider(i)),
    );
    final top = picks.isEmpty ? null : picks[selected.clamp(0, picks.length - 1)];
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (results) {
              setState(() => results = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(results ? 'Propozycje' : 'Ratunku, mam chwilę'),
      ),
      body: SafeArea(
        child: ListView(
          // The result is a new page: it starts at the top, not where the choices were scrolled to.
          key: ValueKey(results),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Text(
              results ? 'Mamy coś!' : 'Ratunku,\nmam $minutes minut!',
              textAlign: TextAlign.center,
              style: text.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              results
                  ? 'Propozycje do $minutes minut'
                  : 'Znajdźmy zabawę na tę chwilę. Bez długich przygotowań.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (!results) ...[
              const RefSection('Ile masz czasu?'),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final m in [10, 20, 30, 45])
                    ChoiceChip(
                      label: Text('$m\nmin', textAlign: TextAlign.center),
                      selected: minutes == m,
                      labelStyle: selectableChipLabel(context, selected: minutes == m),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => minutes = m),
                    ),
                ],
              ),
              const RefSection('Dziecko jest:'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in ChildMood.values)
                    ChoiceChip(
                      avatar: Icon(moodIcons[m], size: 20),
                      label: Text(moodLabels[m]!),
                      selected: mood == m,
                      labelStyle: selectableChipLabel(context, selected: mood == m),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => mood = m),
                    ),
                ],
              ),
              const RefSection('Co możecie użyć?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in [
                    (Requirement.kartkaIOlowek, 'Kartka i kredki', Icons.edit_outlined),
                    (Requirement.miejsceDoRuchu, 'Miejsce do ruchu', Icons.directions_run_rounded),
                    (Requirement.mikrofon, 'Mikrofon', Icons.mic_none_rounded),
                    (Requirement.wydrukPdf, 'Wydruk', Icons.print_outlined),
                  ])
                    FilterChip(
                      avatar: Icon(r.$3, size: 19),
                      label: Text(r.$2),
                      selected: materials.contains(r.$1),
                      labelStyle: selectableChipLabel(context, selected: materials.contains(r.$1)),
                      onSelected: (v) => setState(() => v ? materials.add(r.$1) : materials.remove(r.$1)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                materials.isEmpty
                    ? 'Bez przygotowań. Tylko Wy i dźwięk.'
                    : 'Pokażemy tylko zabawy z zaznaczonymi materiałami.',
                style: text.bodySmall,
              ),
              if (materials.isNotEmpty)
                TextButton(
                  onPressed: () => setState(materials.clear),
                  child: const Text('Dziś bez przygotowań'),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: catalog.isLoading
                    ? null
                    : () => setState(() {
                        results = true;
                        selected = 0;
                      }),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Pokaż propozycje'),
              ),
              if (catalog.hasError)
                TextButton(
                  onPressed: () => ref.invalidate(catalogProvider),
                  child: const Text('Nie udało się pobrać katalogu. Spróbuj ponownie'),
                ),
            ] else if (top == null) ...[
              const Icon(Icons.headphones_rounded, size: 64, color: AkBrand.tealDeep),
              const SizedBox(height: 20),
              const Text(
                'Nie ma jeszcze dostępnej zabawy spełniającej wszystkie warunki. Spróbuj dłuższego czasu lub innych materiałów.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => setState(() => results = false),
                child: const Text('Zmień wybór'),
              ),
            ] else ...[
              ItemHeaderArt(item: top, maxWidth: 280, radius: 24),
              const SizedBox(height: 16),
              Text(top.title, style: text.headlineSmall),
              const SizedBox(height: 8),
              Text('${(top.durationSec / 60).ceil()} minut · od ${top.ageMin} lat', style: text.bodyMedium),
              const SizedBox(height: 8),
              Text(top.parentDescription, maxLines: 4, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AkBrand.sun, foregroundColor: referencePurple),
                onPressed: () => startItem(context, top),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Zaczynamy'),
              ),
              TextButton(
                onPressed: () => context.push('/zabawa/${top.id}'),
                child: const Text('Zobacz szczegóły i przygotowanie'),
              ),
              if (picks.length > 1) ...[
                const RefSection('Podobne propozycje'),
                for (final (i, item) in picks.take(5).indexed)
                  if (i != selected)
                    AudioRow(
                      item: item,
                      trailing: IconButton(
                        tooltip: 'Wybierz tę propozycję',
                        onPressed: () => setState(() => selected = i),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
