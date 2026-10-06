import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the sound plays now: the phone's speaker, headphones, a Bluetooth speaker, AirPlay.
@immutable
class AudioRoute {
  const AudioRoute(this.name, this.kind);

  final String name;

  /// speaker, headphones, bluetooth, airplay, car or other.
  final String kind;

  IconData get icon => switch (kind) {
    'headphones' => Icons.headphones_rounded,
    'bluetooth' => Icons.bluetooth_audio_rounded,
    'airplay' => Icons.airplay_rounded,
    'car' => Icons.directions_car_rounded,
    'speaker' => Icons.phone_iphone_rounded,
    _ => Icons.speaker_rounded,
  };

  static AudioRoute? from(Object? raw) => raw is Map
      ? AudioRoute('${raw['name'] ?? 'Głośnik'}', '${raw['kind'] ?? 'other'}')
      : null;

  @override
  bool operator ==(Object other) => other is AudioRoute && other.name == name && other.kind == kind;

  @override
  int get hashCode => Object.hash(name, kind);
}

const _channel = MethodChannel('pl.audiokiddo/audio_route');
const _events = EventChannel('pl.audiokiddo/audio_route/events');

/// The current output, updated when it changes (iOS tells us; Android is asked every few
/// seconds while the player is open). Null where the platform has no such channel (tests).
final audioRouteProvider = StreamProvider.autoDispose<AudioRoute?>((ref) async* {
  try {
    if (Platform.isIOS) {
      yield* _events.receiveBroadcastStream().map(AudioRoute.from);
      return;
    }
    yield AudioRoute.from(await _channel.invokeMethod<Object?>('current'));
    yield* Stream.periodic(const Duration(seconds: 3)).asyncMap(
      (_) async => AudioRoute.from(await _channel.invokeMethod<Object?>('current')),
    );
  } on MissingPluginException {
    yield null;
  } on PlatformException {
    yield null;
  }
});

/// Opens the system picker: AirPlay and Bluetooth on iOS, the output switcher on Android.
Future<bool> pickAudioRoute() async {
  try {
    return await _channel.invokeMethod<bool>('pick') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

/// A pill under the controls: where it plays now, one tap to move it to a speaker.
class AudioRouteChip extends ConsumerWidget {
  const AudioRouteChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(audioRouteProvider).value;
    final label = route?.name ?? 'Wybierz głośnik';
    return Semantics(
      button: true,
      label: 'Gdzie gra dźwięk: $label. Zmień głośnik',
      excludeSemantics: true,
      child: Material(
        color: Colors.white.withValues(alpha: .12),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () async {
            if (!await pickAudioRoute() && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Głośnik wybierzesz w Centrum sterowania telefonu.')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(route?.icon ?? Icons.speaker_group_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.unfold_more_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
