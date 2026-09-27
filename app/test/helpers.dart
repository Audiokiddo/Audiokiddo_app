import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audiokiddo/core/audio/kiddo_voice.dart';
import 'package:audiokiddo/core/widgets/ambient_motion.dart';
import 'package:audiokiddo/core/platform/device_storage.dart';
import 'package:audiokiddo/core/storage/database.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/features/content/content_urls.dart';
import 'package:audiokiddo/features/downloads/download_providers.dart';
import 'package:audiokiddo/features/downloads/file_transfer.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'package:audiokiddo/features/onboarding/onboarding_controller.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // Closing streams synchronously avoids pending timers when a widget test tears down.
  return AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
}

/// Records enqueued downloads; tests push events to simulate the platform downloader.
class FakeTransfer implements FileTransfer {
  FakeTransfer(this.dir);

  final Directory dir;
  final enqueued = <String, Uri>{};
  final canceled = <String>[];
  final _events = StreamController<TransferEvent>.broadcast();

  @override
  Stream<TransferEvent> get events => _events.stream;

  @override
  Future<void> start() async {}

  @override
  Future<String> directory() async => dir.path;

  @override
  Future<bool> enqueue({required String taskId, required Uri url, required String fileName}) async {
    enqueued[taskId] = url;
    return true;
  }

  @override
  Future<void> cancel(Iterable<String> taskIds) async => canceled.addAll(taskIds);

  void emit(TransferEvent event) => _events.add(event);
}

class FakeStorage extends DeviceStorage {
  const FakeStorage([this.free]);

  final int? free;

  @override
  Future<int?> freeBytes() async => free;

  @override
  Future<void> excludeFromBackup(String path) async {}
}

/// Overrides that let widget tests run without platform audio, downloads or disk.
List<Override> testOverrides(
  AppDatabase db, {
  Directory? downloadsDir,
  KidsModeController? kidsMode,
  bool onboardingDone = true,
}) => [
  onboardingProvider.overrideWithValue(OnboardingController(db, done: onboardingDone)),
  databaseProvider.overrideWithValue(db),
  kidsModeProvider.overrideWithValue(kidsMode ?? KidsModeController(db)),
  fileTransferProvider.overrideWithValue(FakeTransfer(downloadsDir ?? Directory.systemTemp)),
  contentUrlResolverProvider.overrideWithValue(const BaseUrlResolver('http://test.invalid')),
  freeBytesProvider.overrideWith((ref) async => 1 << 34),
  currentMediaProvider.overrideWith((ref) => Stream<MediaItem?>.value(null)),
  kiddoVoiceProvider.overrideWithValue(const SilentKiddoVoice()),
  ambientMotionProvider.overrideWithValue(false),
];
