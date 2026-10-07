import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart' show AuthChangeEvent;

import 'crm/crm_screen.dart';
import 'io/fullscreen_stub.dart' if (dart.library.js_interop) 'io/fullscreen_web.dart';
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

  /// The side panel is folded away on a phone and can be folded to icons on a wide screen.
  bool _compactRail = false;

  /// Sideways phones: fullscreen on the next tap, so the browser bars give the room back.
  bool _wasLandscape = false;

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

  Widget _page() => switch (_tab) {
    0 => const ContentScreen(),
    1 => const PacksScreen(),
    2 => const ShelvesScreen(),
    3 => const PublishScreen(),
    4 => const ServerScreen(),
    _ => const CrmScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final validation = ref.watch(validationProvider);
    final loaded = ref.watch(studioProvider.select((s) => s.loaded));
    final size = MediaQuery.sizeOf(context);
    final phone = size.shortestSide < 600 && size.width < 700 || size.height < 500;
    final landscapePhone = size.height < 500;
    // Turning a phone sideways: the first tap puts the page fullscreen (where the browser can).
    if (landscapePhone && !_wasLandscape) armFullscreenOnTap();
    _wasLandscape = landscapePhone;
    final ready = validation.canPublish;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: landscapePhone ? 40 : (phone ? 52 : 68),
        titleSpacing: phone ? 16 : 20,
        title: Row(
          children: [
            Image.asset('assets/brand/logo.png', height: phone ? 20 : 28),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: phone ? 7 : 10, vertical: phone ? 1 : 3),
              decoration: BoxDecoration(color: Brand.sun, borderRadius: BorderRadius.circular(99)),
              child: Text(
                'Studio',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: phone ? 11 : 13),
              ),
            ),
          ],
        ),
        // On a phone the places are in the bottom bar; on a wide screen the side panel folds.
        automaticallyImplyLeading: false,
        leading: phone
            ? null
            : IconButton(
                tooltip: _compactRail ? 'Rozwiń panel' : 'Zwiń panel',
                onPressed: () => setState(() => _compactRail = !_compactRail),
                icon: Icon(_compactRail ? Icons.menu_rounded : Icons.menu_open_rounded),
              ),
        actions: [
          // The catalog's state; a click goes where it can be fixed.
          if (phone)
            IconButton(
              tooltip: ready ? 'Katalog gotowy' : 'Katalog: ${validation.errorCount} do poprawy',
              onPressed: () => setState(() => _tab = 3),
              icon: Icon(
                ready ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                color: ready ? Brand.tealDeep : Brand.coral,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ActionChip(
                backgroundColor: ready ? Brand.tealSoft : Brand.coralSoft,
                avatar: Icon(
                  ready ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                  color: ready ? Brand.tealDeep : Brand.coral,
                ),
                label: Text(ready ? 'Katalog gotowy' : 'Katalog: ${validation.errorCount} do poprawy'),
                tooltip: 'Sprawdzenie zabaw, pakietów i półek przed publikacją',
                onPressed: () => setState(() => _tab = 3),
              ),
            ),
          IconButton(
            tooltip: isFullscreen ? 'Wyjdź z pełnego ekranu' : 'Pełny ekran',
            onPressed: () {
              if (fullscreenSupported) {
                toggleFullscreen();
                setState(() {});
              } else {
                _fullscreenHelp();
              }
            },
            icon: Icon(isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
          ),
          if (!phone)
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
          SizedBox(width: phone ? 0 : 12),
        ],
      ),
      bottomNavigationBar: phone && loaded ? _bottomBar() : null,
      body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : phone
          ? _page()
          : Row(
              children: [
                NavigationRail(
                  selectedIndex: _tab,
                  labelType: _compactRail ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  minWidth: _compactRail ? 56 : 92,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    for (final (icon, label, tint) in _places)
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: label,
                          child: Icon(icon, color: tint.deep.withValues(alpha: .75)),
                        ),
                        selectedIcon: Icon(icon, color: tint.deep),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _page()),
              ],
            ),
    );
  }

  /// The places in the phone's bottom bar; the rest is under "Więcej".
  static const _bottom = [0, 1, 5, 4];

  Widget _bottomBar() {
    final at = _bottom.indexOf(_tab);
    return NavigationBar(
      height: 64,
      selectedIndex: at < 0 ? _bottom.length : at,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) {
        if (i < _bottom.length) {
          setState(() => _tab = _bottom[i]);
        } else {
          _more();
        }
      },
      destinations: [
        for (final i in _bottom)
          NavigationDestination(
            icon: Icon(_places[i].$1, color: _places[i].$3.deep.withValues(alpha: .7)),
            selectedIcon: Icon(_places[i].$1, color: _places[i].$3.deep),
            label: _places[i].$2,
          ),
        const NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'Więcej'),
      ],
    );
  }

  Future<void> _more() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (icon, label, tint)) in _places.indexed)
            if (!_bottom.contains(i))
              ListTile(
                selected: i == _tab,
                leading: Icon(icon, color: tint.deep),
                title: Text(label),
                onTap: () {
                  Navigator.of(sheet).pop();
                  setState(() => _tab = i);
                },
              ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Wczytaj katalog z pliku JSON'),
            onTap: () {
              Navigator.of(sheet).pop();
              _import();
            },
          ),
        ],
      ),
    ),
  );

  /// iPhone Safari cannot show a page fullscreen; a page added to the home screen opens without
  /// the browser bars.
  void _fullscreenHelp() => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Studio bez paska przeglądarki'),
      content: const Text(
        'iPhone nie pozwala przeglądarce wejść na pełny ekran. Zrób tak: w Safari stuknij Udostępnij, '
        'potem „Dodaj do ekranu początkowego”. Studio otworzy się wtedy z ikony jak aplikacja, '
        'bez paska adresu, także po obróceniu telefonu.',
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Rozumiem'))],
    ),
  );
}
