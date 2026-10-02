import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';

enum PlayCategory {
  adventure('Przygody\ni wyobraźnia'),
  detective('Zagadki\ni detektywi'),
  songs('Piosenki'),
  movement('Ruch i energia'),
  creative('Twórcze\nzabawy'),
  calm('Spokój\ni wyciszenie');

  const PlayCategory(this.label);
  final String label;
  bool matches(ContentItem i) => switch (this) {
    adventure => i.packId == 'wyobraznia',
    detective => i.packId == 'detektyw' || i.skills.any((s) => s.contains('logik')),
    songs => i.kind == ContentKind.song,
    movement => i.skills.contains('ruch') || i.requirements.contains(Requirement.miejsceDoRuchu),
    creative =>
      i.requirements.contains(Requirement.kartkaIOlowek) || i.skills.any((s) => s.contains('kreatyw')),
    calm => i.situations.contains(Situation.przedSnem),
  };
}

enum ChildMood { energetic, bored, grumpy, calm, sleepy }

List<ContentItem> rescuePicks(
  Iterable<ContentItem> items, {
  required int minutes,
  required int age,
  required ChildMood mood,
  required Set<Requirement> available,
  required bool Function(ContentItem) canPlay,
}) {
  final candidates = items
      .where(
        (i) =>
            i.ageMin <= age &&
            (i.ageMax == null || i.ageMax! >= age) &&
            i.durationSec <= minutes * 60 &&
            canPlay(i) &&
            (i.audio.isNotEmpty || i.script != null) &&
            i.requirements.every(available.contains) &&
            (mood != ChildMood.sleepy ||
                (i.kind != ContentKind.interactiveGame && i.situations.contains(Situation.przedSnem))),
      )
      .toList();
  int score(ContentItem i) {
    final movement = PlayCategory.movement.matches(i);
    final calm = PlayCategory.calm.matches(i);
    return (switch (mood) {
          ChildMood.energetic => movement ? 10000 : 0,
          ChildMood.bored => i.kind == ContentKind.interactiveGame ? 10000 : 0,
          ChildMood.grumpy || ChildMood.calm || ChildMood.sleepy => calm ? 10000 : 0,
        }) +
        i.durationSec;
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));
  return candidates;
}

class SavedRoutine {
  const SavedRoutine(this.id, this.name, this.items);
  final String id, name;
  final List<String> items;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'items': items};
}

class DiscoveryState {
  const DiscoveryState({this.queue = const [], this.routines = const [], this.quiet = false, this.cameoDay});
  final List<String> queue;
  final List<SavedRoutine> routines;
  final bool quiet;
  final String? cameoDay;
  DiscoveryState copyWith({
    List<String>? queue,
    List<SavedRoutine>? routines,
    bool? quiet,
    String? cameoDay,
  }) => DiscoveryState(
    queue: queue ?? this.queue,
    routines: routines ?? this.routines,
    quiet: quiet ?? this.quiet,
    cameoDay: cameoDay ?? this.cameoDay,
  );
}

class DiscoveryController extends AsyncNotifier<DiscoveryState> {
  static const key = 'discovery_v1';
  Future<void> _writes = Future.value();
  @override
  Future<DiscoveryState> build() async {
    final raw = await ref.watch(databaseProvider).readValue(key);
    if (raw == null) return const DiscoveryState();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return DiscoveryState(
        queue: List<String>.from(j['queue'] ?? []),
        quiet: j['quiet'] == true,
        cameoDay: j['cameoDay'] as String?,
        routines: [
          for (final r in j['routines'] ?? [])
            SavedRoutine(r['id'] as String, r['name'] as String, List<String>.from(r['items'])),
        ],
      );
    } on FormatException {
      return const DiscoveryState();
    } on TypeError {
      return const DiscoveryState();
    }
  }

  Future<void> _save(DiscoveryState next) {
    state = AsyncData(next);
    final db = ref.read(databaseProvider);
    final raw = jsonEncode({
      'queue': next.queue,
      'routines': next.routines.map((r) => r.toJson()).toList(),
      'quiet': next.quiet,
      'cameoDay': next.cameoDay,
    });
    return _writes = _writes.catchError((Object _) {}).then((_) => db.writeValue(key, raw));
  }

  Future<void> setQueue(List<String> ids) async {
    final s = state.value ?? await future;
    await _save(s.copyWith(queue: List.unmodifiable(ids)));
  }

  Future<void> add(String id) async {
    final s = state.value ?? await future;
    if (!s.queue.contains(id)) await _save(s.copyWith(queue: [...s.queue, id]));
  }

  Future<void> quiet(bool quiet) async {
    final s = state.value ?? await future;
    await _save(s.copyWith(quiet: quiet));
  }

  Future<void> shown(String day) async {
    final s = state.value ?? await future;
    await _save(s.copyWith(cameoDay: day));
  }

  Future<void> saveRoutine(String name) async {
    final s = state.value ?? await future;
    if (s.queue.isEmpty || name.trim().isEmpty) return;
    await _save(
      s.copyWith(
        routines: [
          ...s.routines,
          SavedRoutine(DateTime.now().microsecondsSinceEpoch.toString(), name.trim(), List.of(s.queue)),
        ],
      ),
    );
  }

  Future<void> removeRoutine(String id) async {
    final s = state.value ?? await future;
    await _save(s.copyWith(routines: s.routines.where((r) => r.id != id).toList()));
  }
}

final discoveryProvider = AsyncNotifierProvider<DiscoveryController, DiscoveryState>(DiscoveryController.new);
