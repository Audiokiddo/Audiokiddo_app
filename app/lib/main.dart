import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/audio/kiddo_voice.dart';
import 'core/backend/backend_config.dart';
import 'core/storage/storage_providers.dart';
import 'core/storage/database.dart';
import 'features/account/account_data.dart';
import 'features/account/account_service.dart';
import 'features/account/session_gate.dart';
import 'features/catalog/catalog_providers.dart';
import 'features/catalog/remote_catalog.dart';
import 'features/family_sharing/parent_cloud.dart';
import 'features/insights/error_log.dart';
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
const appVersion = '1.0.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clearBundledAudioCopies();
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
  // Our own error log (no third-party crash reporting in the Kids Category).
  ErrorLog(
    send: (row) => supabase.client.from('app_errors').insert(row),
    installId: events.installId,
    userId: () => supabase.client.auth.currentUser?.id,
    appVersion: appVersion,
    platform: Platform.isIOS ? 'ios' : 'android',
    osVersion: Platform.operatingSystemVersion,
    database: database,
  ).install();
  final cloud = SupabaseParentCloud(supabase.client);
  final variants = await loadVariants(
    cloud,
    await events.installId(),
    () => database.readValue('experiments'),
    (v) => database.writeValue('experiments', v),
  );
  events.abTests = variants;
  final container = ProviderContainer(
    overrides: [
      parentCloudProvider.overrideWithValue(cloud),
      experimentsProvider.overrideWithValue(variants),
      databaseProvider.overrideWithValue(database),
      catalogSourceProvider.overrideWithValue(catalogSource),
      eventSinkProvider.overrideWithValue(events),
      promotionSourceProvider.overrideWithValue(SupabasePromotions(supabase.client)),
      accountServiceProvider.overrideWithValue(SupabaseAccountService(supabase.client)),
      audioHandlerProvider.overrideWithValue(audioHandler),
      kidsModeProvider.overrideWith((ref) => KidsModeController(ref.watch(databaseProvider))),
      onboardingProvider.overrideWith((ref) => OnboardingController(ref.watch(databaseProvider))),
      sessionGateProvider.overrideWith((ref) {
        // Free plays need no account (App Store 5.1.1, Dawid's decision 2026-10-17): a family
        // signs in from Więcej → Konto when it wants to; purchases wait on an anonymous holder
        // until then. A build that must ask first: --dart-define=REQUIRE_SIGN_IN=true.
        final gate = SessionGate(
          ref.watch(accountServiceProvider),
          required: const bool.fromEnvironment('REQUIRE_SIGN_IN'),
        );
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
  // Start recording listening progress; download recovery runs after the first frame.
  container.read(playbackControllerProvider);
  // Android Auto shows the family's listening library on the car screen.
  final car = CarLibrary(container);
  audioHandler
    ..browse = car.children
    ..playById = car.play;
  // CarPlay asks for its tabs (ios/Runner/SceneDelegate.swift, CarPlaySceneDelegate) and is
  // told to ask again when what the family may play, has downloaded or hears now changes.
  const carPlay = MethodChannel('pl.audiokiddo/carplay');
  carPlay.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'library':
        return car.carPlayLibrary();
      case 'play':
        await car.play('${call.arguments}');
        return null;
      case 'toggleLoop':
        return car.toggleLoop();
    }
    return null;
  });
  watchCarPlayChanges(container, () => carPlay.invokeMethod<void>('reload').catchError((Object _) {}));
  runApp(UncontrolledProviderScope(container: container, child: const AudioKiddoApp()));
  // File checks and downloader recovery may take time. Show the first frame first;
  // a platform failure must not leave the family stuck on the launch screen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      container.read(downloadManagerProvider).start().catchError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack, library: 'download startup'),
        );
      }),
    );
  });
}
