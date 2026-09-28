import 'package:flutter/material.dart';

/// Brand colours observed on audiokiddo.pl, extended for the app (docs/ETAP-0-RAPORT.md §3).
///
/// Pack colours are used as backgrounds with [AkPalette.ink] text on top; the deep
/// variants are for text and icons on light surfaces. Contrast is checked in tests.
abstract final class AkBrand {
  static const lavender = Color(0xFFA98EC1);
  static const lavenderDeep = Color(0xFF6B4C8A);
  static const teal = Color(0xFF3EADB2);
  static const tealDeep = Color(0xFF1D7478);
  static const sun = Color(0xFFFAC119);
  static const sunDeep = Color(0xFF8A6200);
  static const orange = Color(0xFFFF7600);
  static const forest = Color(0xFF2F5249);
  static const forestDeep = Color(0xFF16241F);
  static const cream = Color(0xFFF4EDE7);
  static const ink = Color(0xFF1E2B28);

  /// Warm app chrome (2026-09-28): terracotta, peach and sand around the pack colours.
  static const terracotta = Color(0xFFB8431C);
  static const coral = Color(0xFFFF9A6B);
  static const peach = Color(0xFFFFE3CC);
  static const sand = Color(0xFFF7EADB);
  static const cocoa = Color(0xFF231A16);
  static const night = Color(0xFF17120F);
}

/// Semantic colours for one brightness, exposed as a theme extension.
@immutable
class AkPalette extends ThemeExtension<AkPalette> {
  const AkPalette({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.lock,
  });

  static const light = AkPalette(
    background: Color(0xFFFFF7EE),
    surface: Colors.white,
    surfaceMuted: AkBrand.sand,
    ink: AkBrand.cocoa,
    inkMuted: Color(0xFF6B5A50),
    primary: AkBrand.terracotta,
    onPrimary: Colors.white,
    accent: AkBrand.orange,
    lock: Color(0xFF6B5A50),
  );

  static const dark = AkPalette(
    background: AkBrand.night,
    surface: Color(0xFF241C17),
    surfaceMuted: Color(0xFF33281F),
    ink: Color(0xFFFFF3E6),
    inkMuted: Color(0xFFC9B8AA),
    primary: AkBrand.coral,
    onPrimary: AkBrand.cocoa,
    accent: AkBrand.orange,
    lock: Color(0xFFC9B8AA),
  );

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color lock;

  /// Background colour of a pack, from the catalog `color` token. Text on it is always [AkBrand.ink].
  static Color packColor(String token) => switch (token) {
    'lavender' => AkBrand.lavender,
    'teal' => AkBrand.teal,
    'sun' => AkBrand.sun,
    'orange' => AkBrand.orange,
    _ => AkBrand.cream,
  };

  @override
  AkPalette copyWith() => this;

  @override
  AkPalette lerp(AkPalette? other, double t) => t < 0.5 ? this : (other ?? this);
}

abstract final class AkSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
}

abstract final class AkRadius {
  static const card = 24.0;
  static const button = 28.0;
}

/// Soft, wide shadow for floating cards (Apple-style depth without hard edges).
List<BoxShadow> akSoftShadow(BuildContext context) => [
  BoxShadow(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0x66000000)
        : const Color(0x1A8A4B2A),
    blurRadius: 30,
    offset: const Offset(0, 12),
  ),
];

/// Minimum touch target in kids mode (logical pixels), ARCHITECTURE §12.
const double kKidsTouchTarget = 64;

extension AkThemeX on BuildContext {
  AkPalette get palette => Theme.of(this).extension<AkPalette>()!;
}
