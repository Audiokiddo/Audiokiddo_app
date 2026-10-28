import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../catalog/catalog_providers.dart';
import '../family/family.dart';

/// Packs a child has finished: every play in the pack completed at least once.
Set<String> completedPacks(List<ActivityResult> results, Catalog catalog) {
  final done = {
    for (final r in results)
      if (r.completed) r.itemId,
  };
  return {
    for (final p in catalog.packs)
      if (catalog.itemsInPack(p.id).isNotEmpty && catalog.itemsInPack(p.id).every((i) => done.contains(i.id))) p.id,
  };
}

/// Diplomas a child already received: pack id → the day it was handed over. Local only.
final diplomasProvider = FutureProvider.family<Map<String, DateTime>, String>((ref, childId) async {
  final raw = await ref.watch(databaseProvider).readValue('diplomas_$childId');
  if (raw == null) return const {};
  final json = jsonDecode(raw) as Map<String, Object?>;
  return {for (final e in json.entries) e.key: DateTime.parse(e.value! as String)};
});

/// Records the handover (the first time only) and returns its day.
Future<DateTime> awardDiploma(WidgetRef ref, String childId, String packId) async {
  final current = {...await ref.read(diplomasProvider(childId).future)};
  final day = current[packId] ?? ref.read(clockProvider)();
  current[packId] = day;
  await ref
      .read(databaseProvider)
      .writeValue('diplomas_$childId', jsonEncode({for (final e in current.entries) e.key: e.value.toIso8601String()}));
  ref.invalidate(diplomasProvider(childId));
  return day;
}

/// A finished pack of the active child whose diploma still waits to be handed over.
final pendingDiplomaProvider = Provider<({ChildProfile child, Pack pack})?>((ref) {
  final family = ref.watch(familyProvider).value;
  final child = family?.active;
  final catalog = ref.watch(catalogProvider).value;
  if (family == null || child == null || catalog == null) return null;
  final given = ref.watch(diplomasProvider(child.id)).value;
  if (given == null) return null;
  for (final id in completedPacks(family.resultsOf(child.id), catalog)) {
    if (!given.containsKey(id)) return (child: child, pack: catalog.pack(id)!);
  }
  return null;
});

/// What the reward voice line says, shown on screen while it plays (and for VoiceOver).
String bonusTranscript(String packId) => switch (packId) {
  'wyobraznia' =>
    'Dziś w nocy twoje łóżko zamieni się w statek. Dokąd popłyniesz? Opowiedz o tym rodzicom przy śniadaniu.',
  'slowa-i-wiedza' => 'Ma cztery nogi, ale nie chodzi. Stoi w kuchni i czeka na obiad. Co to? To stół.',
  'detektyw' =>
    'Tajne zadanie: znajdź w domu trzy rzeczy, które zaczynają się na literę K. Szepnij je rodzicowi do ucha.',
  _ => 'Jesteś prawdziwym mistrzem słuchania. Przybij piątkę rodzicowi.',
};

/// The bundled voice file of the reward (tool/ui_voice.py).
String bonusLine(String packId) =>
    const {'wyobraznia', 'slowa-i-wiedza', 'detektyw'}.contains(packId) ? 'bonus_$packId' : 'bonus_inne';
