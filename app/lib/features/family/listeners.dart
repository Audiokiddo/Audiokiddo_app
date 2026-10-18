import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import 'family.dart';

const _key = 'listening_now';

/// Which of the children listen right now (siblings, parent review 2026-10-18). Plans are
/// made for the youngest of them, so everyone can join in; the parent sees and changes who
/// on the Teraz card. Empty means all of them.
class ListenersController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final saved = await ref.read(databaseProvider).readValue(_key);
    return {...?saved?.split(',').where((s) => s.isNotEmpty)};
  }

  Future<void> toggle(String childId, List<ChildProfile> children) async {
    final now = {...listening(children, state.value ?? const {}).map((c) => c.id)};
    if (!now.remove(childId)) now.add(childId);
    // Nobody listening makes no sense: back to everyone.
    final next = now.isEmpty || now.length == children.length ? <String>{} : now;
    state = AsyncData(next);
    await ref.read(databaseProvider).writeValue(_key, next.join(','));
  }
}

final listenersProvider = AsyncNotifierProvider<ListenersController, Set<String>>(ListenersController.new);

/// The children listening now: those chosen, or all when none is (or a chosen one is gone).
List<ChildProfile> listening(List<ChildProfile> children, Set<String> chosen) {
  final picked = [for (final c in children) if (chosen.contains(c.id)) c];
  return picked.isEmpty ? children : picked;
}

/// The age plans are made for: the youngest of those listening (6 with no profile yet).
final listeningAgeProvider = Provider<int>((ref) {
  final children = ref.watch(familyProvider).value?.children ?? const <ChildProfile>[];
  if (children.isEmpty) return 6;
  return listening(children, ref.watch(listenersProvider).value ?? const {})
      .map((c) => c.age)
      .reduce((a, b) => a < b ? a : b);
});
