import 'dart:math' as math;

/// Local, on-device detection of claps and voice activity from raw microphone samples
/// (ARCHITECTURE §10). Nothing is recorded or stored: samples are reduced to short-term
/// energy and discarded. Detecting *that* a child spoke says nothing about *what*.
///
/// Feed mono PCM samples normalised to -1..1 through [add]. Thresholds are starting
/// points for the Etap 4 device tests, not final values.
class SoundDetector {
  SoundDetector({
    this.sampleRate = 16000,
    this.hop = const Duration(milliseconds: 10),
    this.onsetRatio = 8,
    this.minLevel = 0.02,
    this.clapMaxDecay = const Duration(milliseconds: 80),
    this.clapRefractory = const Duration(milliseconds: 120),
    this.voiceMinDuration = const Duration(milliseconds: 200),
    this.clapMinZeroCrossing = 0.2,
    this.clapMinAttack = 3,
  }) : _hopSamples = (sampleRate * hop.inMicroseconds / 1e6).round();

  final int sampleRate;
  final Duration hop;

  /// Onset when the frame energy exceeds the noise floor this many times.
  final double onsetRatio;

  /// Absolute RMS level below which nothing counts (silent rooms).
  final double minLevel;

  /// A clap is a short transient: energy must fall to 30% of its peak within this time.
  final Duration clapMaxDecay;
  final Duration clapRefractory;

  /// Sustained sound for this long counts as voice activity.
  final Duration voiceMinDuration;

  /// Claps are noise-like (many zero crossings per sample); voiced speech is not. Without
  /// this, syllables with a sharp consonant look like claps (found on real recordings).
  final double clapMinZeroCrossing;

  /// Claps rise within one frame (energy ×[clapMinAttack] vs the previous frame);
  /// fricatives like "s" or "sz" build up more slowly.
  final double clapMinAttack;

  final int _hopSamples;
  double _sumSquares = 0;
  int _count = 0;
  int _crossings = 0;
  double _previous = 0;
  double _noiseFloor = 0.005;
  int _frame = 0;

  // Candidate transient being tracked.
  int? _onsetFrame;
  double _peak = 0;
  int _lastClapFrame = -1000000;
  double _previousRms = 0;
  int _loudFrames = 0;

  int claps = 0;
  bool voiceDetected = false;

  int get _decayFrames => clapMaxDecay.inMicroseconds ~/ hop.inMicroseconds;
  int get _refractoryFrames => clapRefractory.inMicroseconds ~/ hop.inMicroseconds;
  int get _voiceFrames => voiceMinDuration.inMicroseconds ~/ hop.inMicroseconds;

  void add(Iterable<double> samples) {
    for (final s in samples) {
      _sumSquares += s * s;
      if ((s >= 0) != (_previous >= 0)) _crossings++;
      _previous = s;
      if (++_count == _hopSamples) {
        _onFrame(math.sqrt(_sumSquares / _count), _crossings / _count);
        _sumSquares = 0;
        _count = 0;
        _crossings = 0;
      }
    }
  }

  /// Clears counts for a new listening window; keeps the learned noise floor.
  void resetCounts() {
    claps = 0;
    voiceDetected = false;
    _onsetFrame = null;
    _loudFrames = 0;
  }

  void _onFrame(double rms, double zeroCrossingRate) {
    _frame++;
    final threshold = math.max(_noiseFloor * onsetRatio, minLevel);
    final loud = rms > threshold;

    // Voice: sustained energy (claps are too short to reach this).
    _loudFrames = loud ? _loudFrames + 1 : 0;
    if (_loudFrames >= _voiceFrames) voiceDetected = true;

    final onset = _onsetFrame;
    final previousRms = _previousRms;
    _previousRms = rms;
    if (onset == null) {
      final sharp = rms >= math.max(previousRms, _noiseFloor) * clapMinAttack;
      if (loud &&
          sharp &&
          zeroCrossingRate >= clapMinZeroCrossing &&
          _frame - _lastClapFrame > _refractoryFrames) {
        _onsetFrame = _frame;
        _peak = rms;
      } else if (!loud) {
        // Track the background only when quiet, slowly.
        _noiseFloor = 0.98 * _noiseFloor + 0.02 * rms;
      }
      return;
    }
    if (rms > _peak) _peak = rms;
    if (rms < _peak * 0.3) {
      claps++;
      _lastClapFrame = _frame;
      _onsetFrame = null;
    } else if (_frame - onset > _decayFrames) {
      _onsetFrame = null; // too long for a clap: speech, music or a bang that rings on
    }
  }
}
