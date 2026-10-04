import 'dart:io';
import 'dart:typed_data';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../l10n/app_localizations.dart';
import '../downloads/download_providers.dart';

/// Printable case file (pakiet Detektyw): the local copy when downloaded, otherwise fetched.
final pdfBytesProvider = FutureProvider.autoDispose.family<Uint8List, AssetRef>((ref, asset) async {
  final local = await ref.watch(downloadManagerProvider).localFilePath(asset);
  if (local != null) return File(local).readAsBytes();
  final url = await ref.watch(contentUrlResolverProvider).urlFor(asset);
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != HttpStatus.ok) throw HttpException('HTTP ${response.statusCode}', uri: url);
    final builder = BytesBuilder(copy: false);
    await response.forEach(builder.add);
    return builder.takeBytes();
  } finally {
    client.close();
  }
});

/// Parent zone only (opened after the parental gate): preview, print and share.
class PdfScreen extends ConsumerWidget {
  const PdfScreen({super.key, required this.asset, required this.title, this.header});

  final AssetRef asset;
  final String title;

  /// Shown above the preview (a guide's links).
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          ?header,
          Expanded(child: _preview(ref, l10n)),
        ],
      ),
    );
  }

  Widget _preview(WidgetRef ref, AppLocalizations l10n) => ref
      .watch(pdfBytesProvider(asset))
      .when(
        data: (bytes) => PdfPreview(
          build: (_) async => bytes,
          pdfFileName: '${title.replaceAll(RegExp(r'[^\w-]+'), '_')}.pdf',
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.pdfLoadError, textAlign: TextAlign.center),
          ),
        ),
      );
}
