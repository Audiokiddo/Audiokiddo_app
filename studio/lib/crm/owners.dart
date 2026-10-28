import 'package:flutter/material.dart';

import '../theme.dart';

/// Who does what: Nela the creative side, Dawid the technical one, some things together.
class Owner {
  const Owner(this.name, this.color, this.soft, this.icon);
  final String name;
  final Color color;
  final Color soft;
  final IconData icon;

  static const nela = Owner('Nela', Brand.lavDeep, Brand.lavSoft, Icons.palette_rounded);
  static const dawid = Owner('Dawid', Brand.tealDeep, Brand.tealSoft, Icons.build_rounded);
  static const razem = Owner('Razem', Brand.sunDeep, Brand.sunSoft, Icons.people_rounded);
  static const all = [dawid, nela, razem];

  /// The owner written on a task; Claude's work counts as Dawid's (he orders and checks it).
  static Owner? of(Object? owner) {
    final who = '${owner ?? ''}'.trim().toLowerCase();
    if (who.startsWith('nel')) return nela;
    if (who.startsWith('dawid') || who.startsWith('claude')) return dawid;
    if (who.startsWith('razem')) return razem;
    return null;
  }
}

/// Who should take a task, from its type and words: scenarios, recordings, graphics, editing and
/// posts go to Nela; features, fixes, the shop, setup and reports to Dawid.
Owner suggestOwner(Map<String, dynamic> item) {
  const nelaAreas = {'scenario', 'pack', 'reel', 'post', 'ad'};
  const dawidAreas = {'feature', 'server', 'crm', 'support', 'update', 'proposal'};
  final area = '${item['area'] ?? ''}';
  final text = '${item['title']} ${item['body'] ?? ''}'.toLowerCase();
  bool any(List<String> words) => words.any(text.contains);
  // Strong words decide on their own; weak ones only tip the balance.
  final makes = any([
    'scenariusz',
    'nagra',
    'grafik',
    'montaż',
    'montow',
    'rolk',
    'ilustr',
    'okładk',
    'zmontuj',
  ]);
  final fixes = any([
    'błęd',
    'bug',
    'kod',
    'serwer',
    'supabase',
    'wordpress',
    'woocommerce',
    'wdroż',
    'integrac',
    'raport',
  ]);
  if (makes && !fixes) return Owner.nela;
  if (fixes && !makes) return Owner.dawid;
  if (nelaAreas.contains(area)) return Owner.nela;
  if (dawidAreas.contains(area)) return Owner.dawid;
  final creative = any([
    'film',
    'wideo',
    'video',
    'reel',
    'post',
    'zdjęci',
    'kreatyw',
    'głos',
    'zabaw',
    'baner',
  ]);
  final technical = any([
    'aplikac',
    'stron',
    'analiz',
    'sklep',
    'płatno',
    'konfigur',
    'konto',
    'klucz',
    'funkcj',
  ]);
  return creative && !technical ? Owner.nela : Owner.dawid;
}

/// On a task card: who has it (a click changes it) and, when it seems to belong to the other
/// person, a one-click "Przekaż Neli / Dawidowi".
class OwnerPicker extends StatelessWidget {
  const OwnerPicker({super.key, required this.item, required this.onChange});

  final Map<String, dynamic> item;
  final ValueChanged<String> onChange;

  static String _dative(Owner o) => o == Owner.nela ? 'Neli' : 'Dawidowi';

  @override
  Widget build(BuildContext context) {
    final current = Owner.of(item['owner']);
    final suggested = suggestOwner(item);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<Owner>(
          tooltip: 'Kto bierze to zadanie',
          onSelected: (o) => onChange(o.name),
          itemBuilder: (_) => [
            for (final o in Owner.all)
              PopupMenuItem(
                value: o,
                child: Row(
                  children: [
                    Icon(o.icon, color: o.color, size: 18),
                    const SizedBox(width: 8),
                    Text(o == Owner.razem ? 'Robimy razem' : 'Bierze ${o.name}'),
                  ],
                ),
              ),
          ],
          child: Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.only(right: 6),
            avatar: Icon(
              current?.icon ?? Icons.person_add_alt_1_rounded,
              size: 14,
              color: current?.color ?? Brand.coral,
            ),
            label: Text(current == null ? 'Kto bierze?' : current.name, style: const TextStyle(fontSize: 11)),
            backgroundColor: current?.soft ?? Brand.coralSoft,
          ),
        ),
        if (current != suggested && current != Owner.razem)
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: suggested.color,
            ),
            onPressed: () => onChange(suggested.name),
            icon: Icon(Icons.swap_horiz_rounded, size: 16, color: suggested.color),
            label: Text('Sugeruję: przekaż ${_dative(suggested)}', style: const TextStyle(fontSize: 11)),
          ),
      ],
    );
  }
}
