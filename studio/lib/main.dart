import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart' show AuthChangeEvent;

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
  // The whole of Studio is for the owners only: a saved session of anyone else is dropped.
  final owner = await server.isAdmin();
  if (server.signedIn && !owner) await server.signOut();
  final container = ProviderContainer(
    overrides: [
      studioServerProvider.overrideWithValue(server),
      studioAccessProvider.overrideWith(() => StudioAccess(owner)),
    ],
  );
  // Signing out (in Studio or when the session ends) locks Studio again.
  server.client.auth.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.signedOut) container.read(studioAccessProvider.notifier).set(false);
  });
  runApp(UncontrolledProviderScope(container: container, child: const StudioApp()));
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
    home: const StudioGate(),
  );
}

/// Studio opens only after the code from e-mail, and only for accounts on the owners' list.
class StudioGate extends ConsumerStatefulWidget {
  const StudioGate({super.key});

  @override
  ConsumerState<StudioGate> createState() => _StudioGateState();
}

class _StudioGateState extends ConsumerState<StudioGate> {
  Future<void> _signedIn() async {
    final server = ref.read(studioServerProvider);
    if (await server.isAdmin()) {
      ref.read(studioAccessProvider.notifier).set(true);
      return;
    }
    await server.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'To konto nie jest na liście właścicieli AudioKiddo. Studio jest tylko dla Neli i Dawida.',
        ),
        duration: Duration(seconds: 12),
        showCloseIcon: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(studioAccessProvider)) return const StudioShell();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/logo.png', height: 34),
              const SizedBox(height: 8),
              const Text('Studio · tylko dla właścicieli', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AdminSignIn(onSignedIn: _signedIn),
            ],
          ),
        ),
      ),
    );
  }
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
          IconButton(
            tooltip: 'Wyloguj',
            onPressed: () async {
              await ref.read(studioServerProvider).signOut();
              ref.read(studioAccessProvider.notifier).set(false);
            },
            icon: const Icon(Icons.logout_rounded),
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
