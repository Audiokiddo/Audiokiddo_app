import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../parental_gate/parental_gate.dart';
import '../../core/router.dart' show swipeRoute;
import 'pdf_screen.dart';

/// "Do druku": the files to print, not the plays (Nela, 2026-10-18): pack guides, case files,
/// diplomas, and later other materials. Each opens to preview, print or share.
class PrintablesScreen extends ConsumerWidget {
  const PrintablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final text = Theme.of(context).textTheme;
    final groups = <(String, List<(String, String, AssetRef, bool)>)>[];
    for (final pack in catalog?.packs ?? const <Pack>[]) {
      final files = <(String, String, AssetRef, bool)>[
        if (pack.guide case final guide?) ('Przewodnik dla rodzica', 'Co jest w pakiecie i jak się bawić', guide, true),
        for (final item in catalog!.items.where((i) => i.packId == pack.id))
          for (final pdf in item.pdf)
            (
              item.title,
              pdf.path.contains('dyplom') ? 'Dyplom do wydrukowania' : 'Materiały do zabawy',
              pdf,
              ref.watch(canPlayProvider(item)),
            ),
      ];
      if (files.isNotEmpty) groups.add((pack.title, files));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Do druku')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(
            'Pliki do pobrania i wydrukowania. Dotknij, żeby zobaczyć, wydrukować albo wysłać.',
            style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
          ),
          if (catalog == null) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
          for (final (title, files) in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 6),
              child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final (name, line, asset, open) in files)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(open ? Icons.picture_as_pdf_rounded : Icons.lock_rounded),
                  title: Text(name),
                  subtitle: Text(open ? line : '$line · w abonamencie'),
                  trailing: Icon(open ? Icons.print_rounded : Icons.chevron_right_rounded),
                  onTap: () async {
                    if (!open) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ten plik otworzy się z abonamentem.')),
                      );
                      return;
                    }
                    if (!await showParentalGate(context) || !context.mounted) return;
                    await Navigator.of(context).push(
                      swipeRoute<void>(builder: (_) => PdfScreen(asset: asset, title: name)),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
