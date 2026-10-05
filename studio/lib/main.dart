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
    theme: ThemeData(colorSchemeSeed: const Color(0xFF2F5249), useMaterial3: true),
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

  @override
  Widget build(BuildContext context) {
    final validation = ref.watch(validationProvider);
    final loaded = ref.watch(studioProvider.select((s) => s.loaded));
    return Scaffold(
      appBar: AppBar(
        title: const Text('AudioKiddo Studio'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              avatar: Icon(validation.canPublish ? Icons.check_circle_outline : Icons.error_outline),
              label: Text(validation.canPublish ? 'Katalog poprawny' : 'Błędy: ${validation.errorCount}'),
            ),
          ),
          TextButton.icon(
            onPressed: _import,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importuj JSON'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.library_music_outlined),
                      label: Text('Treści'),
                    ),
                    NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), label: Text('Pakiety')),
                    NavigationRailDestination(icon: Icon(Icons.view_carousel_outlined), label: Text('Półki')),
                    NavigationRailDestination(icon: Icon(Icons.publish_outlined), label: Text('Publikacja')),
                    NavigationRailDestination(icon: Icon(Icons.insights_outlined), label: Text('Serwer')),
                    NavigationRailDestination(icon: Icon(Icons.rocket_launch_outlined), label: Text('CRM')),
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
