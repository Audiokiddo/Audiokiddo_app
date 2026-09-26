import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/downloads/download_providers.dart';
import 'features/player/audio_handler.dart';
import 'features/player/playback_controller.dart';
import 'features/player/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await initAudio();
  final container = ProviderContainer(overrides: [audioHandlerProvider.overrideWithValue(audioHandler)]);
  // Resume interrupted downloads and start recording listening progress.
  await container.read(downloadManagerProvider).start();
  container.read(playbackControllerProvider);
  runApp(UncontrolledProviderScope(container: container, child: const AudioKiddoApp()));
}
