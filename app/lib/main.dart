import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/backend/backend_config.dart';
import 'core/storage/storage_providers.dart';
import 'features/account/account_service.dart';
import 'features/downloads/download_providers.dart';
import 'features/kids_mode/kids_mode_controller.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/player/audio_handler.dart';
import 'features/player/playback_controller.dart';
import 'features/player/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await initAudio();
  // Works offline: the saved session is read from the device, nothing waits for the network.
  final supabase = await Supabase.initialize(url: BackendConfig.url, publishableKey: BackendConfig.publishableKey);
  final container = ProviderContainer(
    overrides: [
      accountServiceProvider.overrideWithValue(SupabaseAccountService(supabase.client)),
      audioHandlerProvider.overrideWithValue(audioHandler),
      kidsModeProvider.overrideWith((ref) => KidsModeController(ref.watch(databaseProvider))),
      onboardingProvider.overrideWith((ref) => OnboardingController(ref.watch(databaseProvider))),
    ],
  );
  // Before the first frame: a restart must not flash the parent zone.
  await container.read(kidsModeProvider).load();
  await container.read(onboardingProvider).load();
  // Resume interrupted downloads and start recording listening progress.
  await container.read(downloadManagerProvider).start();
  container.read(playbackControllerProvider);
  runApp(UncontrolledProviderScope(container: container, child: const AudioKiddoApp()));
}
