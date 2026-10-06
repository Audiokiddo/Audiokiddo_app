import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';

/// Labels for the finer types of CRM items.
const areaLabels = <String, String>{
  'pack': 'Pakiet',
  'scenario': 'Scenariusz',
  'ad': 'Reklama',
  'feature': 'Funkcja',
  'post': 'Post',
  'reel': 'Rolka',
  'newsletter': 'Newsletter',
  'automation': 'Automatyzacja',
  'promotion': 'Promocja',
  'release': 'Premiera',
  'update': 'Aktualizacja',
  'proposal': 'Propozycja zmiany',
  'launch': 'Start w sklepach',
  'marketing': 'Marketing',
  'crm': 'CRM',
  'server': 'Serwer',
  'brief': 'Raport',
  'support': 'Obsługa klienta',
};

const statusLabels = <String, String>{
  'todo': 'Do zrobienia',
  'doing': 'W toku',
  'done': 'Zrobione',
  'archived': 'Archiwum',
  'new': 'Nowy',
  'chosen': 'Wybrany',
  'in_production': 'W produkcji',
  'published': 'Opublikowany',
};

String areaLabel(Object? area) => areaLabels[area] ?? (area == null ? 'Inne' : '$area');

/// Runs a server action with a spinner-free snackbar on failure; returns whether it worked.
Future<bool> crmRun(BuildContext context, Future<void> Function() action, {String? done}) async {
  try {
    await action();
    if (done != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    }
    return true;
  } on Object catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    return false;
  }
}

/// A number on the dashboard.
class KpiTile extends StatelessWidget {
  const KpiTile(this.label, this.value, {super.key, this.hint, this.color});

  final String label;
  final String value;
  final String? hint;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (hint != null) Text(hint!, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// One CRM item as a card: type, title, owner and date, the text folded, actions.
class CrmCard extends StatefulWidget {
  const CrmCard({
    super.key,
    required this.item,
    this.actions = const [],
    this.onTap,
    this.onDelete,
    this.dense = false,
  });

  final Map<String, dynamic> item;
  final List<Widget> actions;
  final VoidCallback? onTap;

  /// Shows a bin; the caller asks and removes.
  final VoidCallback? onDelete;
  final bool dense;

  @override
  State<CrmCard> createState() => _CrmCardState();
}

class _CrmCardState extends State<CrmCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final text = Theme.of(context).textTheme;
    final body = (item['body'] as String?) ?? '';
    final priority = item['priority'] as int? ?? 2;
    final meta = [
      if (item['owner'] != null) '${item['owner']}',
      if (item['due'] != null) 'termin ${item['due']}',
      if (item['source'] == 'ai') 'od agenta',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap ?? (body.isEmpty ? null : () => setState(() => _open = !_open)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (priority == 1)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.priority_high_rounded, size: 18, color: Colors.redAccent),
                    ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(areaLabel(item['area']), style: text.labelSmall),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item['title']}',
                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      tooltip: 'Usuń',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                      onPressed: widget.onDelete,
                    ),
                ],
              ),
              if (meta.isNotEmpty) Text(meta, style: text.labelSmall),
              if (body.isNotEmpty && !widget.dense) ...[
                const SizedBox(height: 6),
                SelectableText(
                  _open || body.length <= 240 ? body : '${body.substring(0, 240)}…',
                  style: text.bodySmall,
                ),
              ],
              if (widget.actions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: widget.actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Add or change an item: title, text, type, owner, due date, priority, status.
Future<Map<String, Object?>?> editCrmItem(
  BuildContext context, {
  required String kind,
  Map<String, dynamic>? item,
  List<String> areas = const [],
  List<String> statuses = const ['todo', 'doing', 'done'],
}) => showDialog<Map<String, Object?>>(
  context: context,
  builder: (_) => _ItemDialog(kind: kind, item: item, areas: areas, statuses: statuses),
);

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.kind, this.item, required this.areas, required this.statuses});

  final String kind;
  final Map<String, dynamic>? item;
  final List<String> areas;
  final List<String> statuses;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final _title = TextEditingController(text: widget.item?['title'] as String? ?? '');
  late final _body = TextEditingController(text: widget.item?['body'] as String? ?? '');
  late final _owner = TextEditingController(text: widget.item?['owner'] as String? ?? '');
  late String? _area = widget.item?['area'] as String? ?? widget.areas.firstOrNull;
  late String _status = widget.item?['status'] as String? ?? widget.statuses.first;
  late int _priority = widget.item?['priority'] as int? ?? 2;
  late DateTime? _due = DateTime.tryParse(widget.item?['due'] as String? ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _owner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Nowy wpis' : 'Edycja'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Tytuł'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              minLines: 4,
              maxLines: 14,
              decoration: const InputDecoration(labelText: 'Opis', alignLabelWithHint: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.areas.isNotEmpty)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: widget.areas.contains(_area) ? _area : widget.areas.first,
                      decoration: const InputDecoration(labelText: 'Typ'),
                      items: [
                        for (final a in widget.areas) DropdownMenuItem(value: a, child: Text(areaLabel(a))),
                      ],
                      onChanged: (v) => setState(() => _area = v),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.statuses.contains(_status) ? _status : widget.statuses.first,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      for (final s in widget.statuses)
                        DropdownMenuItem(value: s, child: Text(statusLabels[s] ?? s)),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Kto: '),
                      for (final who in const ['Dawid', 'Nela', 'Razem'])
                        ChoiceChip(
                          label: Text(who),
                          selected: _owner.text == who,
                          onSelected: (on) => setState(() => _owner.text = on ? who : ''),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _due ?? DateTime.now(),
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _due = picked);
                    },
                    icon: const Icon(Icons.event),
                    label: Text(_due == null ? 'Termin' : _due!.toIso8601String().substring(0, 10)),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _priority,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Pilne')),
                    DropdownMenuItem(value: 2, child: Text('Normalne')),
                    DropdownMenuItem(value: 3, child: Text('Kiedyś')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 2),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isEmpty) return;
          Navigator.pop(context, {
            'id': widget.item?['id'],
            'kind': widget.kind,
            'area': _area,
            'title': _title.text.trim(),
            'body': _body.text,
            'owner': _owner.text.trim().isEmpty ? null : _owner.text.trim(),
            'due': _due?.toIso8601String().substring(0, 10),
            'priority': _priority,
            'status': _status,
          });
        },
        child: const Text('Zapisz'),
      ),
    ],
  );
}

/// CRM items of one kind, refreshed by bumping [crmRefreshProvider].
final crmItemsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, kind) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).crmItems(kind: kind);
});

final crmPendingProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).crmItems(decision: 'pending');
});

final crmOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).crmOverview();
});

final crmRefreshProvider = NotifierProvider<CrmRefresh, int>(CrmRefresh.new);

class CrmRefresh extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Loading and error states for a provider value.
Widget crmAsync<T>(AsyncValue<T> value, Widget Function(T) data) => value.when(
  data: data,
  loading: () => const Center(
    child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
  ),
  error: (e, _) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text('$e')),
  ),
);
