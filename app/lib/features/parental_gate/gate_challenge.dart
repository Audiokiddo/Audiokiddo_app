import 'dart:math';

const _tens = [
  '',
  '',
  'dwadzieścia',
  'trzydzieści',
  'czterdzieści',
  'pięćdziesiąt',
  'sześćdziesiąt',
  'siedemdziesiąt',
  'osiemdziesiąt',
  'dziewięćdziesiąt',
];
const _units = ['', 'jeden', 'dwa', 'trzy', 'cztery', 'pięć', 'sześć', 'siedem', 'osiem', 'dziewięć'];

/// Polish words for 21..99 (the range used by the gate).
String polishNumberWords(int n) {
  assert(n >= 21 && n <= 99);
  final unit = n % 10;
  return unit == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]} ${_units[unit]}';
}

/// "Dotknij liczby czterdzieści siedem": reading the number in words is an adult task
/// for the 3–7 audience. One distractor swaps the digits (47 vs 74) so that guessing
/// from a single recognised digit does not work.
class GateChallenge {
  GateChallenge._(this.target, this.options);

  /// Fixed challenge for tests.
  GateChallenge.fixed(this.target, this.options);

  factory GateChallenge.random([Random? random]) {
    final r = random ?? Random.secure();
    int pick() {
      // Both digits non-zero and different, so the swapped number is a real distractor.
      while (true) {
        final n = 21 + r.nextInt(79);
        if (n % 10 != 0 && n % 10 != n ~/ 10) return n;
      }
    }

    final target = pick();
    final swapped = (target % 10) * 10 + target ~/ 10;
    final options = <int>{target, swapped};
    while (options.length < 4) {
      options.add(pick());
    }
    return GateChallenge._(target, options.toList()..shuffle(r));
  }

  final int target;
  final List<int> options;

  String get targetWords => polishNumberWords(target);

  bool check(int answer) => answer == target;
}

/// Three wrong answers lock the gate for 30 seconds.
class GateAttempts {
  GateAttempts({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const maxFailures = 3;
  static const lockout = Duration(seconds: 30);

  final DateTime Function() _clock;
  int _failures = 0;
  DateTime? _lockedUntil;

  Duration get remainingLock {
    final until = _lockedUntil;
    if (until == null) return Duration.zero;
    final left = until.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  bool get isLocked => remainingLock > Duration.zero;

  void recordFailure() {
    _failures++;
    if (_failures >= maxFailures) {
      _lockedUntil = _clock().add(lockout);
      _failures = 0;
    }
  }

  void recordSuccess() {
    _failures = 0;
    _lockedUntil = null;
  }
}
