import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/backend/backend_config.dart';
import 'core/storage/storage_providers.dart';
import 'core/storage/database.dart';
import 'features/account/account_data.dart';
import 'features/account/account_service.dart';
import 'features/account/session_gate.dart';
import 'features/catalog/catalog_providers.dart';
import 'features/catalog/remote_catalog.dart';
import 'features/insights/acquisition.dart';
import 'features/insights/events.dart';
import 'features/promotions/promotions.dart';
import 'features/downloads/download_providers.dart';
import 'features/kids_mode/kids_mode_controller.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/welcome/welcome_controller.dart';
import 'features/player/audio_handler.dart';
import 'features/player/car_library.dart';
import 'features/player/playback_controller.dart';
import 'features/player/player_providers.dart';

/// Sent with events, so statistics can tell versions apart.
const appVersion = '0.2.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await initAudio();
  // Works offline: the saved session is read from the device, nothing waits for the network.
  final supabase = await Supabase.initialize(
    url: BackendConfig.url,
    publishableKey: BackendConfig.publishableKey,
  );
  final database = AppDatabase();
  final catalogSource = RemoteCatalogSource(supabase.client, database);
  final events = SupabaseEventSink(
    supabase.client,
    database,
    appVersion: appVersion,
    // "pl_PL" → "PL": the market, not the person.
    country: Platform.localeName.split(RegExp('[_-]')).skip(1).firstOrNull?.toUpperCase(),
  );
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      catalogSourceProvider.overrideWithValue(catalogSource),
      eventSinkProvider.overrideWithValue(events),
      promotionSourceProvider.overrideWithValue(SupabasePromotions(supabase.client)),
      accountServiceProvider.overrideWithValue(SupabaseAccountService(supabase.client)),
      audioHandlerProvider.overrideWithValue(audioHandler),
      kidsModeProvider.overrideWith((ref) => KidsModeController(ref.watch(databaseProvider))),
      onboardingProvider.overrideWith((ref) => OnboardingController(ref.watch(databaseProvider))),
      sessionGateProvider.overrideWith((ref) {
        final gate = SessionGate(ref.watch(accountServiceProvider), required: true);
        ref.onDispose(gate.dispose);
        return gate;
      }),
    ],
  );
  // A newer catalog from Studio replaces the shown one as soon as it arrives.
  catalogSource.onChanged = () => container.invalidate(fullCatalogProvider);
  events.context = () => eventContextOf(container);
  await loadEventContext(container);
  unawaited(trackLaunch(events, database));
  // The phone's family data belongs to the signed-in account (cleared if it changed).
  final signedIn = container.read(accountServiceProvider).current;
  if (signedIn != null) await claimFamilyData(database, signedIn.id);
  // Before the first frame: a restart must not flash the parent zone.
  await container.read(kidsModeProvider).load();
  await container.read(onboardingProvider).load();
  await container.read(welcomeProvider).load();
  // Resume interrupted downloads and start recording listening progress.
  await container.read(downloadManagerProvider).start();
  container.read(playbackControllerProvider);
  // Android Auto shows the family's listening library on the car screen.
  final car = CarLibrary(container);
  audioHandler
    ..browse = car.children
    ..playById = car.play;
  runApp(UncontrolledProviderScope(container: container, child: const AudioKiddoApp()));
}
