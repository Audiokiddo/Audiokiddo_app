import 'dart:io';
import 'dart:typed_data';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../discovery/reference_widgets.dart';
import '../../core/widgets/szop.dart';
import '../parental_gate/parental_gate.dart';
import 'case_file.dart';
import 'pdf_screen.dart';

const _ink = Color(0xFF211C35);

/// Szop’en pointing the parent to a case file: solve it on the phone, or print or send it.
/// Shown big on a Detektyw play, so nobody misses that the case comes with files.
class CaseFileCard extends ConsumerWidget {
  const CaseFileCard({super.key, required this.item});

  final ContentItem item;

  Future<void> _print(BuildContext context) async {
    if (!await showParentalGate(context) || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfScreen(asset: item.pdf.first, title: item.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactive = ref.watch(caseTasksProvider(item.id)) != null;
    final text = Theme.of(context).textTheme;
    return _SzopCard(
      pose: SzopPose.chytry,
      title: 'Psst, detektywie! Do tej sprawy są akta.',
      body: interactive
          ? 'W środku zadania, mapy i poszlaki. Odpowiadajcie w telefonie albo wydrukujcie akta '
                'i rozwiązujcie ołówkiem. Akta możesz też wysłać sobie mailem.'
          : 'W środku zadania i poszlaki. Wydrukuj akta albo wyślij je sobie mailem.',
      children: [
        if (interactive)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: referencePurple, foregroundColor: Colors.white),
            onPressed: () => context.push('/akta/${item.id}'),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Rozwiązuj w telefonie'),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _ink),
          ),
          onPressed: () => _print(context),
          icon: const Icon(Icons.print_rounded),
          label: Text('Wydrukuj lub wyślij', style: text.labelLarge?.copyWith(color: _ink)),
        ),
      ],
    );
  }
}

/// On the Detektyw pack page: every case file at once, sent in one share or printed as one
/// document, so nobody has to open five files one by one.
class AllCaseFilesCard extends ConsumerStatefulWidget {
  const AllCaseFilesCard({super.key, required this.packTitle, required this.items});

  final String packTitle;

  /// Plays of the pack that come with a case file.
  final List<ContentItem> items;

  @override
  ConsumerState<AllCaseFilesCard> createState() => _AllCaseFilesCardState();
}

class _AllCaseFilesCardState extends ConsumerState<AllCaseFilesCard> {
  String? _busy;

  Future<List<(ContentItem, Uint8List)>> _load() async => [
    for (final i in widget.items) (i, await ref.read(pdfBytesProvider(i.pdf.first).future)),
  ];

  Future<void> _run(String what, Future<void> Function() action) async {
    if (!await showParentalGate(context) || !mounted) return;
    setState(() => _busy = what);
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się pobrać akt. Sprawdź internet i spróbuj ponownie.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _share() async {
    final origin = context.findRenderObject() as RenderBox?;
    final files = await _load();
    final dir = await getTemporaryDirectory();
    final saved = <XFile>[];
    for (final (item, bytes) in files) {
      final file = File(p.join(dir.path, 'akta-${item.id}.pdf'));
      await file.writeAsBytes(bytes);
      saved.add(XFile(file.path, mimeType: 'application/pdf'));
    }
    await SharePlus.instance.share(
      ShareParams(
        files: saved,
        subject: 'Akta sprawy: ${widget.packTitle}',
        text: 'Wszystkie akta sprawy z pakietu ${widget.packTitle} (AudioKiddo).',
        sharePositionOrigin: origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size,
      ),
    );
  }

  Future<void> _printAll() async {
    final merged = await mergeForPrint(await _load());
    await Printing.layoutPdf(onLayout: (_) async => merged, name: 'Akta sprawy - ${widget.packTitle}');
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    Widget busy(String what, Widget icon) => _busy == what
        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : icon;
    return _SzopCard(
      pose: SzopPose.zadowolony,
      title: 'Wszystkie akta sprawy w jednym miejscu',
      body:
          'Każda zagadka ma swoje akta ($n plików). Wyślij je sobie naraz, na przykład mailem, '
          'albo wydrukuj wszystkie jednym przyciskiem. Odpowiadać można też w telefonie, przy każdej sprawie.',
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: referencePurple, foregroundColor: Colors.white),
          onPressed: _busy != null ? null : () => _run('share', _share),
          icon: busy('share', const Icon(Icons.ios_share_rounded)),
          label: Text('Wyślij wszystkie akta ($n)'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _ink),
          ),
          onPressed: _busy != null ? null : () => _run('print', _printAll),
          icon: busy('print', const Icon(Icons.print_rounded)),
          label: const Text('Wydrukuj wszystkie naraz'),
        ),
      ],
    );
  }
}

/// One printable document from several PDFs: each page drawn at print resolution, in order.
Future<Uint8List> mergeForPrint(List<(ContentItem, Uint8List)> files, {double dpi = 150}) async {
  final doc = pw.Document(title: 'Akta sprawy', author: 'AudioKiddo');
  for (final (_, bytes) in files) {
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      final image = pw.MemoryImage(await page.toPng());
      final format = page.width > page.height ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
  }
  return doc.save();
}

/// Szop’en beside a yellow card with a title, a line and buttons.
class _SzopCard extends StatelessWidget {
  const _SzopCard({required this.pose, required this.title, required this.body, required this.children});

  final SzopPose pose;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SzopSticker(pose, height: 76),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: _ink, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(body, style: text.bodyMedium?.copyWith(color: _ink, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}
