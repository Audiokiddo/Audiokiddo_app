import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../family/family.dart';
import '../purchases/shop.dart';
import 'events.dart';

/// Where the family heard of AudioKiddo, as the parent answers it once after the welcome.
/// No tracking SDK (Kids Category): the answer is the attribution.
enum AcquisitionSource {
  instagram('instagram', 'Instagram'),
  tiktok('tiktok', 'TikTok'),
  facebook('facebook', 'Facebook'),
  ad('ad', 'Reklama'),
  influencer('influencer', 'Influencer lub blog'),
  friend('referral', 'Od znajomych'),
  search('search', 'Wyszukiwarka lub sklep z aplikacjami'),
  other('other', 'Inaczej');

  const AcquisitionSource(this.wire, this.label);

  final String wire;
  final String label;
}

const _sourceKey = 'acquisition_source';

/// The saved answer, or null before the parent answered (or skipped: then 'skipped').
final acquisitionSourceProvider = FutureProvider<String?>(
  (ref) => ref.watch(databaseProvider).readValue(_sourceKey),
);

Future<void> saveAcquisitionSource(WidgetRef ref, AcquisitionSource? source) async {
  final wire = source?.wire ?? 'skipped';
  await ref.read(databaseProvider).writeValue(_sourceKey, wire);
  ref.invalidate(acquisitionSourceProvider);
  ref.read(eventSinkProvider).track(AppEvent.sourceAnswered, props: {'source': wire});
}

/// The global parameters of every event, read from the app's state at that moment.
EventContext eventContextOf(ProviderContainer container) {
  final scopes = container.read(activeScopesProvider);
  final source = container.read(acquisitionSourceProvider).value;
  return EventContext(
    ageGroup: ageGroupOf(container.read(familyProvider).value?.active?.age),
    plan: scopes.contains(Scopes.allContent)
        ? 'subscription'
        : scopes.any((s) => s.startsWith('pack:') || s.startsWith('item:'))
        ? 'package_only'
        : 'free',
    source: source == 'skipped' ? null : source,
  );
}

/// Reads the saved answer and the family once (both on the phone), so events right after
/// launch carry them.
Future<void> loadEventContext(ProviderContainer container) async {
  await container.read(acquisitionSourceProvider.future);
  await container.read(familyProvider.future);
}
