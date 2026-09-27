import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Endless decorative motion (Kiddo breathing and blinking, drifting doodles). Tests turn it
/// off so screens can settle; the system "reduce motion" setting is honoured separately.
final ambientMotionProvider = Provider<bool>((ref) => true);
