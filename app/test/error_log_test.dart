import 'dart:async';
import 'dart:io';

import 'package:audiokiddo/features/insights/error_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('errors are grouped by type and place, scrubbed, sent once, capped', () async {
    final sent = <Map<String, Object?>>[];
    final log = ErrorLog(
      send: (row) async => sent.add(row),
      installId: () async => 'install',
      appVersion: '0.2.0',
    );
    final stack = StackTrace.fromString(
      '#0      Player.start (package:audiokiddo/features/player/player.dart:42:7)\n#1      main (dart:core)',
    );
    log.record(StateError('rodzic@example.com zamówienie 12345678'), stack);
    log.record(StateError('again'), stack);
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(1), reason: 'the same error once per launch');
    expect(sent.single['message'], 'Bad state: <e-mail> zamówienie <liczba>');
    expect(sent.single['fingerprint'], matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(
      ErrorLog.fingerprint(
        'StateError',
        '#0 Player.start (package:audiokiddo/features/player/player.dart:50:1)',
      ),
      sent.single['fingerprint'],
      reason: 'a new line number in a new version is the same error',
    );
    for (var i = 0; i < 40; i++) {
      log.record(ArgumentError('e$i'), StackTrace.fromString('#0 f$i (package:audiokiddo/a.dart:$i:1)'));
    }
    await Future<void>.delayed(Duration.zero);
    expect(sent, hasLength(ErrorLog.maxPerLaunch));
  });

  test('network trouble is not an error of the app', () {
    expect(ErrorLog.isNoise(const SocketException('offline')), isTrue);
    expect(ErrorLog.isNoise(TimeoutException('slow')), isTrue);
    expect(ErrorLog.isNoise(StateError('x')), isFalse);
  });
}
