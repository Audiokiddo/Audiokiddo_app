import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One sitting = plays and games with less than [gap] between them; its id is when it began
/// (seconds since 1970). The CRM adds up how long a child really keeps listening
/// (crm_play_minutes), so ads say only measured minutes. Shared by recordings and games.
class SittingClock {
  SittingClock({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const gap = Duration(minutes: 10);

  final DateTime Function() _clock;
  int? _id;
  DateTime? _lastActivity;

  /// The current sitting, if anything has played.
  int? get id => _id;

  /// A play or game starts: the same sitting when the last one ended less than [gap] ago.
  int begin() {
    final now = _clock();
    final idle = _lastActivity;
    if (_id == null || idle == null || now.difference(idle) > gap) _id = now.millisecondsSinceEpoch ~/ 1000;
    _lastActivity = now;
    return _id!;
  }

  /// Something is still going on (playing, a game answered): the gap counts from now.
  void touch() => _lastActivity = _clock();
}

final sittingClockProvider = Provider<SittingClock>((ref) => SittingClock());
