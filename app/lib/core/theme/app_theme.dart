import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? AkPalette.light : AkPalette.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: AkBrand.teal,
    onSecondary: AkBrand.ink,
    tertiary: AkBrand.lavender,
    onTertiary: AkBrand.ink,
    error: const Color(0xFFB3261E),
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    secondaryContainer: p.primary,
    onSecondaryContainer: p.onPrimary,
    surfaceContainerHighest: p.surfaceMuted,
    outline: p.inkMuted,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Poppins');
  final text = base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink);

  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    extensions: [p],
    // Apple-style type: big, bold, tightly tracked headlines; calm body text.
    textTheme: text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      headlineLarge: text.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.1,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: p.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkRadius.card)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
        foregroundColor: p.ink,
        textStyle: text.titleMedium,
        side: BorderSide(color: p.inkMuted.withValues(alpha: 0.5)),
        shape: const StadiumBorder(),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: p.surface,
      selectedColor: p.primary,
      labelStyle: _ChipLabelStyle(color: p.inkMuted, selectedColor: p.onPrimary),
      checkmarkColor: p.onPrimary,
      side: BorderSide(color: p.surfaceMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      // Translucent: the shell blurs what scrolls underneath (Apple's frosted bar).
      backgroundColor: p.background,
      elevation: 0,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? p.primary : p.inkMuted),
      ),
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
    ),
  );
}

/// Label style for selectable chips (FilterChip/ChoiceChip): readable on the selected fill.
TextStyle selectableChipLabel(BuildContext context, {required bool selected}) {
  final p = Theme.of(context).extension<AkPalette>()!;
  return TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: selected ? p.onPrimary : p.ink,
  );
}

/// Chip label with a fixed colour for plain chips and [selectedColor] for selected ones.
/// Plain chips use the style as-is; selectable chips resolve it with their state.
class _ChipLabelStyle extends TextStyle implements WidgetStateProperty<TextStyle> {
  const _ChipLabelStyle({required Color super.color, required this.selectedColor})
    : super(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500);

  final Color selectedColor;

  @override
  TextStyle resolve(Set<WidgetState> states) =>
      states.contains(WidgetState.selected) ? copyWith(color: selectedColor) : this;
}
