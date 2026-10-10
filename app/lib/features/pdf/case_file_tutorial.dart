import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../player/player_providers.dart';
import 'case_files_card.dart';
import 'pdf_screen.dart';

/// Family data: the detective tutorial was shown.
const caseFileTutorialKey = 'case_file_tutorial_done';

/// Whether [item] is a play with a case file (Detektyw).
bool hasCaseFile(ContentItem item) => item.pdf.isNotEmpty && item.packId == 'detektyw';

/// Before the first case: playback waits while Szop’en shows how to get the case file ready
/// (print it, or open it on a phone or tablet), then the case starts.
Future<void> maybeShowCaseFileTutorial(BuildContext context, WidgetRef ref, ContentItem item) async {
  if (!hasCaseFile(item)) return;
  final db = ref.read(databaseProvider);
  if (await db.readValue(caseFileTutorialKey) == 'true' || !context.mounted) return;
  await db.writeValue(caseFileTutorialKey, 'true');
  final handler = ref.read(audioHandlerProvider);
  await handler.pause();
  if (!context.mounted) return;
  final start = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CaseFileTutorial(item: item),
  );
  if (start ?? false) await handler.play();
}

class CaseFileTutorial extends ConsumerStatefulWidget {
  const CaseFileTutorial({super.key, required this.item});

  final ContentItem item;

  @override
  ConsumerState<CaseFileTutorial> createState() => _CaseFileTutorialState();
}

class _CaseFileTutorialState extends ConsumerState<CaseFileTutorial> {
  int _step = 0;

  static const _steps = [
    (
      SzopPose.chytry,
      'Psst, to sprawa z aktami!',
      'W zabawach Detektywa dziecko rozwiązuje zagadkę na papierze: mapy, poszlaki i zadania. '
          'Zanim zacznie się nagranie, przygotujmy akta sprawy.',
    ),
    (
      SzopPose.zadowolony,
      'Wydrukuj albo otwórz w telefonie',
      'Najlepiej wydrukować akta tej sprawy. Nie masz drukarki? Otwórz je na tablecie albo drugim '
          'telefonie i połóż obok dziecka. Możesz też wysłać je sobie mailem i wydrukować później.',
    ),
    (
      SzopPose.klaszcze,
      'Kartka, ołówek i gramy',
      'Daj dziecku ołówek i akta, połóż telefon z nagraniem obok. Narrator powie, kiedy zajrzeć do '
          'akt. Akta tej sprawy znajdziesz też zawsze w odtwarzaczu pod przyciskiem „Akta sprawy”.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (pose, title, body) = _steps[_step];
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final all = catalog == null ? const <ContentItem>[] : caseFileItems(catalog);
    final last = _step == _steps.length - 1;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(.12, 0), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(_step),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SzopSticker(pose, height: 90),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Samouczek detektywa ${_step + 1}/${_steps.length}',
                          style: text.labelMedium?.copyWith(color: AkBrand.tealDeep, fontWeight: FontWeight.w800),
                        ),
                        Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(body, style: text.bodyLarge),
              if (_step == 1) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    swipeRoute<void>(
                      builder: (_) => PdfScreen(asset: widget.item.pdf.first, title: widget.item.title),
                    ),
                  ),
                  icon: const Icon(Icons.description_rounded),
                  label: const Text('Otwórz akta tej sprawy (drukuj, wyślij, podgląd)'),
                ),
                if (all.length > 1) ...[
                  const SizedBox(height: 8),
                  CaseFilesBulkButtons(packTitle: 'Detektyw', items: all),
                ],
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: const Text('Wstecz')),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(140, 48)),
                    onPressed: last ? () => Navigator.of(context).pop(true) : () => setState(() => _step++),
                    child: Text(last ? 'Akta gotowe, gramy!' : 'Dalej'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
