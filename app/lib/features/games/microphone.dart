import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ak_core/ak_core.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import 'speech.dart';

/// Sample rate the detectors are tuned for.
const micSampleRate = 16000;

/// Microphone for games (ARCHITECTURE §9, §10). Samples go straight to the on-device
/// detector and are discarded: nothing is recorded, stored or sent.
abstract interface class MicrophoneInput {
  /// Whether the system permission is granted, without asking.
  Future<bool> hasPermission();

  /// Shows the system prompt if it was never answered. Call only after the parental gate.
  Future<bool> requestPermission();

  /// Mono samples normalised to -1..1 at [micSampleRate].
  Future<Stream<List<double>>> start();

  Future<void> stop();
}

class RecordMicrophone implements MicrophoneInput {
  AudioRecorder? _recorder;

  @override
  Future<bool> hasPermission() => AudioRecorder().hasPermission(request: false);

  @override
  Future<bool> requestPermission() => AudioRecorder().hasPermission();

  @override
  Future<Stream<List<double>>> start() async {
    await stop();
    final recorder = _recorder = AudioRecorder();
    final session = await AudioSession.instance;
    if (Platform.isIOS) {
      // We own the session: play and listen at once, keep A2DP headphones in stereo and the
      // phone's own microphone as input (a Bluetooth headset mic would force the low-quality
      // call profile).
      await recorder.ios?.manageAudioSession(false);
      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.defaultToSpeaker |
              AVAudioSessionCategoryOptions.allowBluetoothA2dp,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
        ),
      );
      await session.setActive(true);
    }
    final bytes = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: micSampleRate,
        numChannels: 1,
        // Processing would flatten the sharp attack that tells a clap from speech.
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        audioInterruption: AudioInterruptionMode.none,
      ),
    );
    return bytes.map(pcm16ToSamples);
  }

  @override
  Future<void> stop() async {
    final recorder = _recorder;
    _recorder = null;
    if (recorder == null) return;
    await recorder.stop();
    await recorder.dispose();
    if (Platform.isIOS) {
      await (await AudioSession.instance).configure(const AudioSessionConfiguration.music());
    }
  }
}

/// Little-endian signed 16-bit PCM → -1..1.
List<double> pcm16ToSamples(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return [for (var i = 0; i + 1 < bytes.length; i += 2) data.getInt16(i, Endian.little) / 32768];
}

final microphoneInputProvider = Provider<MicrophoneInput>((ref) => RecordMicrophone());

/// The parent's choice to let games listen (off by default), combined with the system
/// permission. Turned on only behind the parental gate.
class MicrophoneSettings extends AsyncNotifier<bool> {
  static const _key = 'games_microphone';

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<bool> build() async {
    if (await _db.readValue(_key) != '1') return false;
    return ref.read(microphoneInputProvider).hasPermission();
  }

  /// Asks the system if needed; returns false when the parent (or the system) refused.
  /// With [words] it also asks for speech recognition (games answered with words); a refusal
  /// there still leaves claps and voice working.
  Future<bool> enable({bool words = false}) async {
    final granted = await ref.read(microphoneInputProvider).requestPermission();
    await _db.writeValue(_key, granted ? '1' : '0');
    if (granted && words) {
      await ref.read(speechInputProvider).requestPermission();
      ref.invalidate(speechReadyProvider);
    }
    state = AsyncData(granted);
    return granted;
  }

  Future<void> disable() async {
    await _db.writeValue(_key, '0');
    state = const AsyncData(false);
  }
}

final microphoneSettingsProvider = AsyncNotifierProvider<MicrophoneSettings, bool>(MicrophoneSettings.new);

/// Whether [script] can listen for claps, voice or words (and so benefits from the microphone).
bool scriptListensToSound(GameScript script) => script.steps.values.any(
  (step) => switch (step) {
    InputStep(:final input) => input == InputKind.clap || input == InputKind.voiceActivity,
    ChoiceStep(:final inputs) => inputs.any(
      {InputKind.clap, InputKind.voiceActivity, InputKind.speechKeywords}.contains,
    ),
    _ => false,
  },
);

/// Whether the child can answer [script] with words (engine 3).
bool scriptListensToWords(GameScript script) =>
    script.steps.values.any((step) => step is ChoiceStep && step.words.isNotEmpty);

/// Whether word answers can be heard on this phone now (permission given, offline Polish).
final speechReadyProvider = FutureProvider<bool>((ref) async {
  if (!await ref.watch(microphoneSettingsProvider.future)) return false;
  return ref.watch(speechInputProvider).ready();
});
