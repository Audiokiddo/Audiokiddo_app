import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../catalog/catalog_providers.dart';

/// A link from a pack guide (a film or a file on Google Drive).
typedef GuideLink = ({String label, Uri url});

/// One play of a guide: its film and its files.
typedef GuidePlay = ({String itemId, Uri? video, List<GuideLink> files});

/// The links printed in a pack's guide PDF (tool: links pulled out of the PDFs into
/// assets/guide_links.json). The PDF preview draws pages as pictures, so its links cannot be
/// tapped; the guide screen lists them as buttons instead.
typedef GuideLinks = ({List<GuidePlay> plays, List<GuideLink> extras});

GuideLinks parseGuideLinks(Map<String, Object?> pack) {
  GuideLink link(Object? raw) {
    final m = raw! as Map<String, Object?>;
    return (label: m['label']! as String, url: Uri.parse(m['url']! as String));
  }

  return (
    plays: [
      for (final raw in pack['plays'] as List? ?? const [])
        (
          itemId: (raw as Map<String, Object?>)['item']! as String,
          video: raw['video'] == null ? null : Uri.parse(raw['video']! as String),
          files: [for (final f in raw['files'] as List? ?? const []) link(f)],
        ),
    ],
    extras: [for (final e in pack['extras'] as List? ?? const []) link(e)],
  );
}

final guideLinksProvider = FutureProvider.family<GuideLinks?, String>((ref, packId) async {
  final raw = jsonDecode(await rootBundle.loadString('assets/guide_links.json')) as Map<String, Object?>;
  final pack = raw[packId] as Map<String, Object?>?;
  return pack == null ? null : parseGuideLinks(pack);
});

/// The guide's films and files as a sheet of buttons (already in the parent zone: guides open
/// behind the parental gate).
Future<void> showGuideLinks(BuildContext context, String packId) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _GuideLinksSheet(packId: packId),
);

/// The button above the guide preview that opens [showGuideLinks].
class GuideLinksButton extends ConsumerWidget {
  const GuideLinksButton({super.key, required this.packId});

  final String packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(guideLinksProvider(packId)).value;
    if (links == null || links.plays.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: FilledButton.icon(
        onPressed: () => showGuideLinks(context, packId),
        icon: const Icon(Icons.smart_display_rounded),
        label: const Text('Filmy i pliki do pobrania'),
      ),
    );
  }
}

class _GuideLinksSheet extends ConsumerWidget {
  const _GuideLinksSheet({required this.packId});

  final String packId;

  Future<void> _open(BuildContext context, Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(const SnackBar(content: Text('Nie udało się otworzyć linku.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(guideLinksProvider(packId)).value;
    final catalog = ref.watch(catalogProvider).value;
    final text = Theme.of(context).textTheme;
    if (links == null) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    String title(String id) => catalog?.item(id)?.title ?? id;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('Filmy i pliki z przewodnika', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Filmy otwierają się w YouTube, pliki w przeglądarce. Tam możesz je pobrać lub wydrukować.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final play in links.plays) ...[
              Text(title(play.itemId), style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (play.video case final video?)
                    OutlinedButton.icon(
                      onPressed: () => _open(context, video),
                      icon: const Icon(Icons.smart_display_rounded),
                      label: const Text('Film'),
                    ),
                  for (final f in play.files)
                    OutlinedButton.icon(
                      onPressed: () => _open(context, f.url),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(f.label),
                    ),
                ],
              ),
              const Divider(height: 24),
            ],
            for (final e in links.extras)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.workspace_premium_rounded),
                title: Text(e.label),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _open(context, e.url),
              ),
          ],
        ),
      ),
    );
  }
}
