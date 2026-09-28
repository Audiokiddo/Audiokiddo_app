import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/platform/device_storage.dart';

/// Short messages a parent records for their child, woven into the day: a hello when kids
/// mode opens, praise after a game or a trip, goodnight at the end of the bedtime ritual.
enum ParentClip { hello, praise, goodnight }

/// Recordings live only on this phone (app documents, excluded from backups): a child's
/// name in a parent's voice is personal data and never leaves the device.
abstract interface class ParentVoiceStore {
  /// Paths of the clips recorded for [childId].
  Future<Map<ParentClip, String>> clips(String childId);

  Future<bool> requestMicrophone();

  Future<void> startRecording(String childId, ParentClip clip);

  /// Stops and keeps the recording; returns its path (null when nothing was captured).
  Future<String?> stopRecording();

  Future<void> delete(String childId, ParentClip clip);

  /// Plays a clip; completes when it ends.
  Future<void> play(String path);

  Future<void> stopPlayback();
}

class FileParentVoiceStore implements ParentVoiceStore {
  FileParentVoiceStore(this._storage);

  final DeviceStorage _storage;
  AudioRecorder? _recorder;
  String? _recordingPath;
  final _player = AudioPlayer();

  Future<Directory> _dir() async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'parent_voice'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> _path(String childId, ParentClip clip) async =>
      p.join((await _dir()).path, '${childId}_${clip.name}.m4a');

  @override
  Future<Map<ParentClip, String>> clips(String childId) async => {
    for (final clip in ParentClip.values)
      if (await File(await _path(childId, clip)).exists()) clip: await _path(childId, clip),
  };

  @override
  Future<bool> requestMicrophone() => AudioRecorder().hasPermission();

  @override
  Future<void> startRecording(String childId, ParentClip clip) async {
    final recorder = _recorder = AudioRecorder();
    final path = _recordingPath = await _path(childId, clip);
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, numChannels: 1),
      path: path,
    );
  }

  @override
  Future<String?> stopRecording() async {
    final recorder = _recorder;
    _recorder = null;
    if (recorder == null) return null;
    final path = await recorder.stop();
    await recorder.dispose();
    if (path == null || !await File(path).exists()) return null;
    await _storage.excludeFromBackup(path);
    return path;
  }

  @override
  Future<void> delete(String childId, ParentClip clip) async {
    final file = File(await _path(childId, clip));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> play(String path) async {
    try {
      await _player.setFilePath(path);
      final states = _player.playerStateStream;
      unawaited(_player.play());
      // Done at the end of the clip or when stopped (play() alone may not complete at the end).
      await states.firstWhere((s) => s.playing).timeout(const Duration(seconds: 3));
      await states.firstWhere((s) => s.processingState == ProcessingState.completed || !s.playing);
      await _player.stop();
    } on Exception {
      // A damaged clip is skipped; the app carries on with Kiddo's voice.
    }
  }

  @override
  Future<void> stopPlayback() => _player.stop();

  /// The path being recorded right now, if any (for the UI).
  String? get recordingPath => _recordingPath;
}

final parentVoiceStoreProvider = Provider<ParentVoiceStore>(
  (ref) => FileParentVoiceStore(const DeviceStorage()),
);

/// Clips recorded for a child; invalidate after recording or deleting.
final parentClipsProvider = FutureProvider.family<Map<ParentClip, String>, String>(
  (ref, childId) => ref.watch(parentVoiceStoreProvider).clips(childId),
);
