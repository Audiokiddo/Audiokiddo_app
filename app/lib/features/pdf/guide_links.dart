import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../catalog/catalog_providers.dart';
import '../parental_gate/parental_gate.dart';

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

/// The pack's films and files on their own page. Links leave the app, so the page opens after
/// the parental gate (once, not for every link).
Future<void> openPackMaterials(BuildContext context, String packId) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  await context.push('/pakiet/$packId/materialy');
}

/// "Filmy i materiały": each play of the pack with its film (YouTube) and files to download or
/// print, then extras such as the diploma.
class PackMaterialsScreen extends ConsumerWidget {
  const PackMaterialsScreen({super.key, required this.packId});

  final String packId;

  Future<void> _open(BuildContext context, Uri url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(const SnackBar(content: Text('Nie udało się otworzyć linku.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(guideLinksProvider(packId));
    final catalog = ref.watch(catalogProvider).value;
    final text = Theme.of(context).textTheme;
    String title(String id) => catalog?.item(id)?.title ?? id;
    return Scaffold(
      appBar: AppBar(title: Text('Filmy i materiały: ${catalog?.pack(packId)?.title ?? ''}')),
      body: SafeArea(
        child: links.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Nie udało się wczytać materiałów.')),
          data: (links) => links == null
              ? const Center(child: Text('Ten pakiet nie ma jeszcze materiałów.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      'Filmy otwierają się w YouTube, pliki w przeglądarce. Tam możesz je pobrać lub wydrukować.',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 16),
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
      ),
    );
  }
}
