import 'package:flutter/material.dart';

/// AudioKiddo's colours, the same as the app and the website: cream, teal, sun, lavender.
abstract final class Brand {
  static const cream = Color(0xFFFFFBF2);
  static const ink = Color(0xFF1D1A2B);
  static const teal = Color(0xFF3AAFB0);
  static const tealDeep = Color(0xFF1D7478);
  static const tealSoft = Color(0xFFD2ECED);
  static const sun = Color(0xFFFAC119);
  static const sunDeep = Color(0xFF8A6200);
  static const sunSoft = Color(0xFFFFF1C2);
  static const lav = Color(0xFFA98EC1);
  static const lavDeep = Color(0xFF6B4C8A);
  static const lavSoft = Color(0xFFF1E2FD);
  static const coral = Color(0xFFE8794A);
  static const coralSoft = Color(0xFFFFE3CC);
  static const line = Color(0x1F1D1A2B);
}

/// One colour per part of Studio, so each place is easy to recognise at a glance.
class Tint {
  const Tint(this.deep, this.soft);
  final Color deep;
  final Color soft;

  static const content = Tint(Brand.lavDeep, Brand.lavSoft);
  static const packs = Tint(Brand.sunDeep, Brand.sunSoft);
  static const shelves = Tint(Brand.tealDeep, Brand.tealSoft);
  static const publish = Tint(Brand.coral, Brand.coralSoft);
  static const server = Tint(Brand.tealDeep, Brand.tealSoft);
  static const crm = Tint(Brand.lavDeep, Brand.lavSoft);

  /// Colours for a pack's own colour name in the catalog.
  static Tint ofPack(String? color) => switch (color) {
    'teal' || 'mint' => shelves,
    'sun' || 'yellow' || 'peach' => packs,
    'coral' || 'orange' => publish,
    _ => content,
  };
}

ThemeData studioTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.tealDeep,
    primary: Brand.tealDeep,
    secondary: Brand.sun,
    onSecondary: Brand.ink,
    tertiary: Brand.lavDeep,
    surface: Brand.cream,
    onSurface: Brand.ink,
  );
  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Poppins');
  return base.copyWith(
    scaffoldBackgroundColor: Brand.cream,
    textTheme: base.textTheme.apply(bodyColor: Brand.ink, displayColor: Brand.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Brand.cream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Brand.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Brand.line),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.sunSoft,
      selectedLabelTextStyle: TextStyle(fontWeight: FontWeight.w700, color: Brand.ink, fontSize: 13),
      unselectedLabelTextStyle: TextStyle(color: Color(0xFF625C70), fontSize: 12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Brand.ink,
      unselectedLabelColor: Color(0xFF625C70),
      indicatorColor: Brand.sun,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
      dividerColor: Brand.line,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: const BorderSide(color: Brand.line),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Brand.sun,
      foregroundColor: Brand.ink,
      shape: StadiumBorder(),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: const StadiumBorder(),
      side: const BorderSide(color: Brand.line),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Brand.line),
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white, shape: rounded),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: Brand.ink),
    dividerTheme: const DividerThemeData(color: Brand.line),
  );
}

/// A friendly header for a section: Szop'en, a title, one sentence and the main buttons.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.tint,
    required this.title,
    required this.text,
    this.pose = 'zadowolony',
    this.actions = const [],
  });

  final Tint tint;
  final String title;
  final String text;
  final String pose;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    decoration: BoxDecoration(color: tint.soft, borderRadius: BorderRadius.circular(24)),
    child: Row(
      children: [
        Image.asset('assets/brand/szop-$pose.png', width: 72, height: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700, color: tint.deep),
              ),
              const SizedBox(height: 2),
              Text(text),
            ],
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    ),
  );
}

/// Asks before something is removed for good.
Future<bool> confirmDelete(BuildContext context, String what) async =>
    await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Usunąć $what?'),
        content: const Text('Tego nie da się cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    ) ??
    false;
