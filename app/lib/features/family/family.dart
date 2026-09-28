import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../catalog/catalog_providers.dart';

/// Children, the one currently listening, and what each has played. Kept only on this
/// device (ARCHITECTURE §4); nothing about children goes to the server.
class FamilyState {
  const FamilyState({
    this.children = const [],
    this.activeId,
    this.results = const [],
    this.frozen = const {},
  });

  final List<ChildProfile> children;
  final String? activeId;
  final List<ActivityResult> results;

  /// Plan days each child already started, kept as they were (see [withFrozenDays]).
  final Map<String, List<List<String>>> frozen;

  FamilyState copyWith({
    List<ChildProfile>? children,
    String? activeId,
    List<ActivityResult>? results,
    Map<String, List<List<String>>>? frozen,
  }) => FamilyState(
    children: children ?? this.children,
    activeId: activeId ?? this.activeId,
    results: results ?? this.results,
    frozen: frozen ?? this.frozen,
  );

  ChildProfile? get active => children.where((c) => c.id == activeId).firstOrNull ?? children.firstOrNull;

  List<ActivityResult> resultsOf(String childId) => [
    for (final r in results)
      if (r.childId == childId) r,
  ];
}

class FamilyController extends AsyncNotifier<FamilyState> {
  static const _childrenKey = 'family_children';
  static const _activeKey = 'family_active';
  static const _resultsKey = 'family_results';
  static const _frozenKey = 'family_frozen_plans';

  /// Older results are dropped; progress needs weeks, not years.
  static const maxResults = 2000;

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<FamilyState> build() async {
    final db = ref.watch(databaseProvider);
    List<Map<String, Object?>> list(String? raw) =>
        raw == null ? const [] : (jsonDecode(raw) as List).cast<Map<String, Object?>>();
    return FamilyState(
      children: [for (final j in list(await db.readValue(_childrenKey))) ChildProfile.fromJson(j)],
      activeId: await db.readValue(_activeKey),
      results: [for (final j in list(await db.readValue(_resultsKey))) ActivityResult.fromJson(j)],
      frozen: _decodeFrozen(await db.readValue(_frozenKey)),
    );
  }

  Future<FamilyState> _current() async => state.value ?? await future;

  static Map<String, List<List<String>>> _decodeFrozen(String? raw) {
    if (raw == null) return const {};
    final json = jsonDecode(raw) as Map<String, Object?>;
    return {
      for (final MapEntry(:key, :value) in json.entries)
        key: [for (final day in value! as List) (day as List).cast<String>()],
    };
  }

  /// Keeps the plan days up to [throughDay] as they are now for [childId].
  Future<void> freezePlan(String childId, List<PlanDay> plan, int throughDay) async {
    final s = await _current();
    if ((s.frozen[childId]?.length ?? 0) >= throughDay) return;
    final frozen = {
      ...s.frozen,
      childId: [for (final day in plan.take(throughDay)) day.itemIds],
    };
    await _db.writeValue(_frozenKey, jsonEncode(frozen));
    if (ref.mounted) state = AsyncData(s.copyWith(frozen: frozen));
  }

  Future<void> saveChild(ChildProfile child) async {
    final s = await _current();
    final children = [
      for (final c in s.children)
        if (c.id != child.id) c,
      child,
    ];
    await _db.writeValue(_childrenKey, jsonEncode([for (final c in children) c.toJson()]));
    state = AsyncData(s.copyWith(children: children, activeId: s.activeId ?? child.id));
    if (s.activeId == null) await _db.writeValue(_activeKey, child.id);
  }

  Future<void> removeChild(String id) async {
    final s = await _current();
    final children = [
      for (final c in s.children)
        if (c.id != id) c,
    ];
    final results = [
      for (final r in s.results)
        if (r.childId != id) r,
    ];
    await _db.writeValue(_childrenKey, jsonEncode([for (final c in children) c.toJson()]));
    await _db.writeValue(_resultsKey, jsonEncode([for (final r in results) r.toJson()]));
    final active = s.activeId == id ? children.firstOrNull?.id : s.activeId;
    if (active == null) {
      await _db.deleteValue(_activeKey);
    } else {
      await _db.writeValue(_activeKey, active);
    }
    final frozen = {...s.frozen}..remove(id);
    await _db.writeValue(_frozenKey, jsonEncode(frozen));
    state = AsyncData(FamilyState(children: children, activeId: active, results: results, frozen: frozen));
  }

  Future<void> setActive(String id) async {
    final s = await _current();
    await _db.writeValue(_activeKey, id);
    state = AsyncData(s.copyWith(activeId: id));
  }

  /// Credits a finished activity to the child who is listening now (if any profile exists).
  Future<void> record({
    required String itemId,
    required int seconds,
    bool completed = true,
    int answers = 0,
    int? correct,
    DateTime? at,
  }) async {
    final s = await _current();
    final child = s.active;
    if (child == null) return;
    final result = ActivityResult(
      childId: child.id,
      itemId: itemId,
      at: at ?? DateTime.now(),
      seconds: seconds,
      completed: completed,
      answers: answers,
      correct: correct,
    );
    final results = [...s.results, result];
    final kept = results.length > maxResults ? results.sublist(results.length - maxResults) : results;
    await _db.writeValue(_resultsKey, jsonEncode([for (final r in kept) r.toJson()]));
    if (ref.mounted) {
      state = AsyncData(s.copyWith(results: kept));
      // The day the child is on now stays as it is, whatever gets unlocked later.
      final Catalog catalog;
      try {
        catalog = await ref.read(catalogProvider.future);
      } on Object {
        return; // no catalog, nothing to freeze
      }
      if (ref.mounted) {
        bool canPlay(ContentItem item) => ref.read(canPlayProvider(item));
        final plan = composePlan(catalog, child, s.frozen[child.id], canPlay);
        final position = composePosition(catalog, plan, [
          for (final r in kept)
            if (r.childId == child.id) r,
        ], canPlay);
        await freezePlan(child.id, plan, position.currentDay);
      }
    }
  }
}

final familyProvider = AsyncNotifierProvider<FamilyController, FamilyState>(FamilyController.new);

/// The path of [child]: generated, with the days already started kept as they were.
List<PlanDay> composePlan(
  Catalog catalog,
  ChildProfile child,
  List<List<String>>? frozen,
  bool Function(ContentItem) canPlay,
) => withFrozenDays(buildPlan(catalog, child, canPlay: canPlay), frozen ?? const []);

PlanPosition composePosition(
  Catalog catalog,
  List<PlanDay> plan,
  List<ActivityResult> results,
  bool Function(ContentItem) canPlay, {
  DateTime? now,
}) => planPosition(
  plan,
  results,
  now ?? DateTime.now(),
  playable: (id) {
    final item = catalog.item(id);
    return item != null && canPlay(item);
  },
);

/// The development path of [childId]; prefers what the family can already play.
final planProvider = Provider.family<List<PlanDay>, String>((ref, childId) {
  final catalog = ref.watch(catalogProvider).value;
  final family = ref.watch(familyProvider).value;
  final child = family?.children.where((c) => c.id == childId).firstOrNull;
  if (catalog == null || child == null) return const [];
  return composePlan(catalog, child, family!.frozen[childId], (item) => ref.watch(canPlayProvider(item)));
});

final planPositionProvider = Provider.family<PlanPosition?, String>((ref, childId) {
  final plan = ref.watch(planProvider(childId));
  final family = ref.watch(familyProvider).value;
  final catalog = ref.watch(catalogProvider).value;
  if (plan.isEmpty || family == null || catalog == null) return null;
  return composePosition(
    catalog,
    plan,
    family.resultsOf(childId),
    (item) => ref.watch(canPlayProvider(item)),
    now: ref.watch(clockProvider)(),
  );
});

final progressProvider = Provider.family<ChildProgress?, String>((ref, childId) {
  final catalog = ref.watch(catalogProvider).value;
  final family = ref.watch(familyProvider).value;
  if (catalog == null || family == null) return null;
  return summarizeProgress(family.resultsOf(childId), catalog, ref.watch(clockProvider)());
});

/// A fresh id for a new child profile (local only).
String newChildId() => 'child-${DateTime.now().microsecondsSinceEpoch}';
