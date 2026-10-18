import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../catalog/catalog_providers.dart';
import '../catalog/home_screen.dart' show favoritePlayId;
import '../family/family.dart' hide progressProvider;
import '../parental_gate/parental_gate.dart';

/// "A co z bajkami u babci?" (research 2026-10-12): a message for grandparents with the app,
/// what the child likes and the two house rules that matter. Plain, nothing to set up.
String grandparentsMessage({String? childName, List<String> favorites = const []}) {
  final who = childName ?? 'dziecko';
  return [
    'audiokiddo, czyli zabawy na głos dla ${childName ?? 'dziecka'}: https://audiokiddo.pl',
    if (favorites.isNotEmpty) 'Najbardziej lubi: ${favorites.map((t) => '„$t”').join(', ')}.',
    'Jak to działa: włączasz zabawę i kładziesz telefon ekranem w dół. Głos zadaje pytania, $who odpowiada na głos.',
    'Darmowe zabawy działają od razu. Wszystkie zabawy: poproś nas o kod rodziny i wpisz go w Więcej → Drugi rodzic.',
  ].join('\n\n');
}

/// Shares [grandparentsMessage] with the active child's name and favourites, for an adult only.
Future<void> shareWithGrandparents(BuildContext context, WidgetRef ref) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  final family = ref.read(familyProvider).value;
  final catalog = ref.read(catalogProvider).value;
  final child = family?.active;
  final favorites = <String>[];
  if (child != null && catalog != null) {
    final id = favoritePlayId(family!.results, child.id);
    final fav = id == null ? null : catalog.item(id);
    if (fav != null) favorites.add(fav.title);
    for (final r in family.resultsOf(child.id).reversed) {
      final i = catalog.item(r.itemId);
      if (i != null && r.completed && !favorites.contains(i.title) && i.kind != ContentKind.song) favorites.add(i.title);
      if (favorites.length >= 3) break;
    }
  }
  final origin = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      text: grandparentsMessage(childName: child?.name, favorites: favorites),
      subject: 'audiokiddo dla dziadków',
      sharePositionOrigin: origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size,
    ),
  );
}
