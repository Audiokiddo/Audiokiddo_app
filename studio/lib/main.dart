import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crm/crm_screen.dart';
import 'screens/content_screen.dart';
import 'screens/packs_and_shelves.dart';
import 'screens/publish_screen.dart';
import 'screens/server_screen.dart';
import 'server/studio_server.dart';
import 'state/studio_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The admin stays signed in across reloads of the page.
  final server = StudioServer();
  await server.restore();
  runApp(
    ProviderScope(overrides: [studioServerProvider.overrideWithValue(server)], child: const StudioApp()),
  );
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AudioKiddo Studio',
    debugShowCheckedModeBanner: false,
    theme: studioTheme(),
    locale: const Locale('pl'),
    supportedLocales: const [Locale('pl')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const StudioShell(),
  );
}

class StudioShell extends ConsumerStatefulWidget {
  const StudioShell({super.key});

  @override
  ConsumerState<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends ConsumerState<StudioShell> {
  int _tab = 0;

  Future<void> _import() async {
    final raw = await ref.read(studioIoProvider).pickCatalogJson();
    if (raw == null || !mounted) return;
    try {
      ref.read(studioProvider.notifier).importCatalog(raw);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wczytano katalog.')));
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nie udało się wczytać: ${e.message}')));
    }
  }

  static const _places = [
    (Icons.library_music_rounded, 'Treści', Tint.content),
    (Icons.inventory_2_rounded, 'Pakiety', Tint.packs),
    (Icons.view_carousel_rounded, 'Półki', Tint.shelves),
    (Icons.rocket_rounded, 'Publikacja', Tint.publish),
    (Icons.insights_rounded, 'Serwer', Tint.server),
    (Icons.dashboard_customize_rounded, 'CRM', Tint.crm),
  ];

  @override
  Widget build(BuildContext context) {
    final validation = ref.watch(validationProvider);
    final loaded = ref.watch(studioProvider.select((s) => s.loaded));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset('assets/brand/logo.png', height: 28),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Brand.sun, borderRadius: BorderRadius.circular(99)),
              child: const Text('Studio', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        actions: [
          // The catalog's state; a click goes where it can be fixed.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ActionChip(
              backgroundColor: validation.canPublish ? Brand.tealSoft : Brand.coralSoft,
              avatar: Icon(
                validation.canPublish ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                color: validation.canPublish ? Brand.tealDeep : Brand.coral,
              ),
              label: Text(
                validation.canPublish ? 'Katalog gotowy' : 'Katalog: ${validation.errorCount} do poprawy',
              ),
              tooltip: 'Sprawdzenie zabaw, pakietów i półek przed publikacją',
              onPressed: () => setState(() => _tab = 3),
            ),
          ),
          IconButton(
            tooltip: 'Wczytaj katalog z pliku JSON',
            onPressed: _import,
            icon: const Icon(Icons.upload_file),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 92,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    for (final (icon, label, tint) in _places)
                      NavigationRailDestination(
                        icon: Icon(icon, color: tint.deep.withValues(alpha: .75)),
                        selectedIcon: Icon(icon, color: tint.deep),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: switch (_tab) {
                    0 => const ContentScreen(),
                    1 => const PacksScreen(),
                    2 => const ShelvesScreen(),
                    3 => const PublishScreen(),
                    4 => const ServerScreen(),
                    _ => const CrmScreen(),
                  },
                ),
              ],
            ),
    );
  }
}
