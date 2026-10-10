import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import 'case_file.dart';
import 'pdf_screen.dart';

/// Draws one page of a PDF; swapped in widget tests, where no PDF engine runs.
typedef CasePageRasterizer = Stream<ui.Image> Function(Uint8List pdf, double dpi);

Stream<ui.Image> _printingRaster(Uint8List pdf, double dpi) =>
    Printing.raster(pdf, dpi: dpi).asyncMap((page) => page.toImage());

CasePageRasterizer debugCasePageRasterizer = _printingRaster;

/// The case file on the phone: every page of the PDF, and under a page its tasks to answer
/// with big buttons or a code field. Open tasks (drawing, listening) are not graded.
/// Nothing leaves the app, so unlike printing and sharing it needs no parental gate.
class CaseFileScreen extends ConsumerWidget {
  const CaseFileScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(catalogProvider).value?.item(itemId);
    final tasks = ref.watch(caseTasksProvider(itemId));
    final waiting = ref.watch(caseFilesProvider).isLoading || ref.watch(catalogProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: Text(item == null ? 'Akta sprawy' : 'Akta: ${item.title}')),
      body: item == null || item.pdf.isEmpty || tasks == null
          ? Center(child: waiting ? const CircularProgressIndicator() : const Text('Ta zabawa nie ma akt sprawy.'))
          : ref
                .watch(pdfBytesProvider(item.pdf.first))
                .when(
                  data: (bytes) => _Pages(pdf: bytes, tasks: tasks),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(AppLocalizations.of(context).pdfLoadError, textAlign: TextAlign.center),
                    ),
                  ),
                ),
    );
  }
}

class _Pages extends StatefulWidget {
  const _Pages({required this.pdf, required this.tasks});

  final Uint8List pdf;
  final List<CaseTask> tasks;

  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  final _pages = <ui.Image>[];
  final _solved = <CaseTask>{};
  StreamSubscription<ui.Image>? _raster;
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Sharp on this screen, without drawing more pixels than it shows.
    final width = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    final dpi = (width / 8.27).clamp(72.0, 160.0);
    _raster = debugCasePageRasterizer(widget.pdf, dpi).listen(
      (page) => mounted ? setState(() => _pages.add(page)) : page.dispose(),
      onDone: () => mounted ? setState(() => _done = true) : null,
      onError: (Object _) => mounted ? setState(() => _done = true) : null,
    );
  }

  @override
  void dispose() {
    _raster?.cancel();
    for (final p in _pages) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final graded = widget.tasks.where((t) => t.kind != CaseTaskKind.open).length;
    final solved = _solved.where((t) => t.kind != CaseTaskKind.open).length;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _pages.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) return _Progress(solved: solved, graded: graded);
        if (i == _pages.length + 1) {
          return _done
              ? const SizedBox.shrink()
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
        }
        final number = i;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PageImage(image: _pages[number - 1], number: number),
            for (final task in widget.tasks.where((t) => t.page == number))
              CaseTaskCard(key: ValueKey(task), task: task, onSolved: () => setState(() => _solved.add(task))),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.solved, required this.graded});

  final int solved;
  final int graded;

  @override
  Widget build(BuildContext context) {
    final all = solved == graded && graded > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SzopSticker(all ? SzopPose.klaszcze : SzopPose.nasluchuje, height: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              all
                  ? 'Wszystkie zagadki rozwiązane! Brawo, detektywie!'
                  : 'Rozwiązane zagadki: $solved z $graded. Pod każdą stroną zaznacz odpowiedź.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A page of the PDF; a tap opens it full screen to zoom in.
class _PageImage extends StatelessWidget {
  const _PageImage({required this.image, required this.number});

  final ui.Image image;
  final int number;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    button: true,
    label: 'Strona $number akt. Dotknij, żeby powiększyć.',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Strona $number')),
            backgroundColor: Colors.white,
            body: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: RawImage(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: image.width / image.height,
          child: ColoredBox(
            color: Colors.white,
            child: RawImage(image: image, fit: BoxFit.contain),
          ),
        ),
      ),
    ),
  );
}

/// One task under its page: buttons or a code field, then "Dobry wybór!" or "Spróbuj jeszcze raz".
class CaseTaskCard extends StatefulWidget {
  const CaseTaskCard({super.key, required this.task, this.onSolved});

  final CaseTask task;
  final VoidCallback? onSolved;

  @override
  State<CaseTaskCard> createState() => _CaseTaskCardState();
}

class _CaseTaskCardState extends State<CaseTaskCard> {
  final _code = TextEditingController();
  int? _picked;
  bool? _right;
  int _misses = 0;
  bool _shown = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _answer(bool right) {
    setState(() {
      _right = right;
      if (!right) _misses++;
    });
    if (right) widget.onSolved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: akSoftShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.prompt, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          switch (task.kind) {
            CaseTaskKind.choice => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < task.options.length; i++)
                  _ChoiceButton(
                    label: task.options[i],
                    state: _picked == i ? _right : null,
                    onTap: _right == true
                        ? null
                        : () {
                            _picked = i;
                            _answer(task.isCorrectChoice(i));
                          },
                  ),
              ],
            ),
            CaseTaskKind.code => Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    enabled: _right != true,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: text.titleMedium?.copyWith(letterSpacing: 1.5),
                    decoration: const InputDecoration(hintText: 'Wpisz odpowiedź', border: OutlineInputBorder()),
                    onSubmitted: (v) => _answer(task.isCorrectCode(v)),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 56)),
                  onPressed: _right == true ? null : () => _answer(task.isCorrectCode(_code.text)),
                  child: const Text('Sprawdź'),
                ),
              ],
            ),
            CaseTaskKind.open => Row(
              children: [
                const SzopSticker(SzopPose.nasluchuje, height: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Tego nie sprawdzamy w telefonie. Sprawdźcie z Maxem i Milą!', style: text.bodyMedium),
                ),
              ],
            ),
          },
          if (_right == true)
            _Verdict(pose: SzopPose.klaszcze, text: 'Dobry wybór!', color: AkBrand.tealDeep)
          else if (_right == false) ...[
            _Verdict(pose: SzopPose.zdziwiony, text: 'Spróbuj jeszcze raz', color: palette.inkMuted),
            if (_misses >= 2 && !_shown)
              TextButton(onPressed: () => setState(() => _shown = true), child: const Text('Pokaż odpowiedź')),
            if (_shown)
              Text('Odpowiedź: ${task.solution}', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.state, required this.onTap});

  final String label;

  /// true: picked and right; false: picked and wrong; null: not picked.
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      true => AkBrand.teal,
      false => const Color(0xFFE57373),
      null => null,
    };
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
        backgroundColor: color,
        foregroundColor: color == null ? null : Colors.white,
        disabledForegroundColor: color == null ? null : Colors.white,
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap ?? () {},
      child: Text(label),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.pose, required this.text, required this.color});

  final SzopPose pose;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Semantics(
      liveRegion: true,
      child: Row(
        children: [
          SzopSticker(pose, height: 40),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
