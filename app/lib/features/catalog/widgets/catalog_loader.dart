import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';

/// Shows loading and error states and builds [builder] once the catalog is available.
class CatalogLoader extends ConsumerWidget {
  const CatalogLoader({super.key, required this.builder});

  final Widget Function(BuildContext context, Catalog catalog) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(catalogProvider)
        .when(
          data: (catalog) => builder(context, catalog),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AkSpace.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context).loadError, textAlign: TextAlign.center),
                  const SizedBox(height: AkSpace.m),
                  FilledButton(
                    onPressed: () => ref.invalidate(catalogProvider),
                    child: Text(AppLocalizations.of(context).retry),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
