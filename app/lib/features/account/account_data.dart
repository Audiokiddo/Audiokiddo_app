import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../access/access_controller.dart';
import '../diploma/diploma.dart';
import '../discovery/discovery_model.dart';
import '../family/family.dart' hide progressProvider;
import '../home/first_steps.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../personal/personal_repository.dart';
import '../welcome/welcome_controller.dart';

const _ownerKey = 'account_owner';

/// Keys of one family's data on the phone: child profiles, results, plans, diplomas, the queue
/// and routines, saved games and little "seen it" flags. Device settings (theme, microphone,
/// downloads, catalog) are not here.
const familyDataKeys = [
  'family_children',
  'family_active',
  'family_frozen_plans',
  'family_results',
  'discovery_v1',
  'first_steps_hidden',
  'rating_asked_at',
  'shop_suggestion_hidden',
  'szopen_bubbles',
  'reminders',
  'alerts_opt_in',
  'access_state',
  'welcome_done',
];
const familyDataPrefixes = ['diplomas_', 'game_resume:', 'lord_'];

/// Clears the previous family's data from the phone. Returns whether anything was cleared.
Future<bool> clearFamilyData(AppDatabase db) async {
  for (final key in familyDataKeys) {
    await db.deleteValue(key);
  }
  for (final prefix in familyDataPrefixes) {
    await db.deleteValuesStartingWith(prefix);
  }
  await db.clearListening();
  return true;
}

/// After a sign-in: the phone's family data belongs to the account that signed in. When a
/// different account signs in than the last one, the previous family's names, results,
/// diplomas, favourites and history are removed, so nobody sees another family's data. The
/// same account signing in again keeps everything; the first account on a phone adopts it.
Future<bool> claimFamilyData(AppDatabase db, String userId) async {
  final owner = await db.readValue(_ownerKey);
  var cleared = false;
  if (owner != null && owner != userId) cleared = await clearFamilyData(db);
  if (owner != userId) await db.writeValue(_ownerKey, userId);
  return cleared;
}

/// [claimFamilyData] plus fresh state on screen (and kids mode off) when data was cleared.
Future<void> claimFamilyDataFor(WidgetRef ref, String userId) async {
  if (!await claimFamilyData(ref.read(databaseProvider), userId)) return;
  // A new family on this phone gets its own welcome.
  await ref.read(welcomeProvider).load();
  ref.invalidate(accessProvider);
  final kids = ref.read(kidsModeProvider);
  if (kids.active) await kids.exit();
  ref
    ..invalidate(familyProvider)
    ..invalidate(discoveryProvider)
    ..invalidate(diplomasProvider)
    ..invalidate(firstStepsHiddenProvider)
    ..invalidate(favoritesProvider)
    ..invalidate(favoritesOrderedProvider)
    ..invalidate(recentProvider)
    ..invalidate(progressProvider);
}
