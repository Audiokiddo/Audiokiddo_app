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
import 'package:audiokiddo/features/games/speech.dart';
import 'package:audiokiddo/features/kids_mode/kids_home_screen.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'package:audiokiddo/features/onboarding/onboarding_controller.dart';
import 'package:audiokiddo/features/parent_voice/parent_voice.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:audiokiddo/features/purchases/preview_player.dart';
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
  MediaItem? media,
  SpeechInput? speech,
}) => [
  onboardingProvider.overrideWithValue(OnboardingController(db, done: onboardingDone)),
  databaseProvider.overrideWithValue(db),
  kidsModeProvider.overrideWithValue(kidsMode ?? KidsModeController(db)),
  fileTransferProvider.overrideWithValue(FakeTransfer(downloadsDir ?? Directory.systemTemp)),
  contentUrlResolverProvider.overrideWithValue(const BaseUrlResolver('http://test.invalid')),
  freeBytesProvider.overrideWith((ref) async => 1 << 34),
  currentMediaProvider.overrideWith((ref) => Stream<MediaItem?>.value(media)),
  kiddoVoiceProvider.overrideWithValue(const SilentKiddoVoice()),
  ambientMotionProvider.overrideWithValue(false),
  kidsMagicEntryProvider.overrideWithValue(false),
  parentVoiceStoreProvider.overrideWithValue(FakeParentVoiceStore()),
  previewAudioProvider.overrideWithValue(FakePreviewAudio()),
  speechInputProvider.overrideWithValue(speech ?? FakeSpeech(available: false)),
];

/// Word recognition without a recogniser: [answer] picks what the child "says" to each
/// question (null: silence); [available] false is a phone without offline Polish.
class FakeSpeech implements SpeechInput {
  FakeSpeech({this.available = true, this.answer});

  bool available;
  String? Function(List<String> vocabulary)? answer;

  @override
  bool get supported => true;
  final heard = <String>[];
  bool listening = false;

  @override
  Future<bool> ready() async => available;

  @override
  Future<bool> requestPermission() async => available;

  @override
  Future<void> listen({
    required Duration window,
    required List<String> vocabulary,
    required void Function(List<String> transcripts) onHeard,
  }) async {
    if (!available) throw const SpeechUnavailable('test');
    listening = true;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final said = answer?.call(vocabulary);
    if (said != null && listening) {
      heard.add(said);
      // As a real recogniser would: a sentence around the word, alternatives after it.
      onHeard(['no to $said', said]);
    }
    await Future<void>.delayed(window);
  }

  @override
  Future<void> stop() async => listening = false;
}

/// Parent recordings in memory: [clipsByChild] is what "was recorded", [played] what played.
class FakeParentVoiceStore implements ParentVoiceStore {
  FakeParentVoiceStore([Map<String, Map<ParentClip, String>>? clips]) : clipsByChild = clips ?? {};

  final Map<String, Map<ParentClip, String>> clipsByChild;
  final played = <String>[];
  (String, ParentClip)? _recording;

  @override
  Future<Map<ParentClip, String>> clips(String childId) async => {...?clipsByChild[childId]};

  @override
  Future<bool> requestMicrophone() async => true;

  @override
  Future<void> startRecording(String childId, ParentClip clip) async => _recording = (childId, clip);

  @override
  Future<String?> stopRecording() async {
    final r = _recording;
    _recording = null;
    if (r == null) return null;
    final path = '/fake/${r.$1}_${r.$2.name}.m4a';
    (clipsByChild[r.$1] ??= {})[r.$2] = path;
    return path;
  }

  @override
  Future<void> delete(String childId, ParentClip clip) async => clipsByChild[childId]?.remove(clip);

  @override
  Future<void> play(String path) async => played.add(path);

  @override
  Future<void> stopPlayback() async {}
}

/// Previews "play" instantly in tests: [played] lists the URLs, [finish] ends the current one.
class FakePreviewAudio implements PreviewAudio {
  final played = <Uri>[];
  void Function()? _done;

  @override
  Future<void> play(
    Uri url, {
    required void Function(double) onProgress,
    required void Function() onDone,
  }) async {
    played.add(url);
    _done = onDone;
    onProgress(.5);
  }

  @override
  Future<void> stop() async => _done = null;

  void finish() => _done?.call();
}
