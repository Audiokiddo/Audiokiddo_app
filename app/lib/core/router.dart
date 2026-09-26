import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/details_screen.dart';
import '../features/catalog/home_screen.dart';
import '../features/catalog/library_filter.dart';
import '../features/catalog/library_screen.dart';
import '../features/access/dev_tools_screen.dart';
import '../features/personal/mine_screen.dart';
import '../features/player/mini_player.dart';
import '../features/player/no_look_screen.dart';
import '../features/player/player_screen.dart';
import '../l10n/app_localizations.dart';

// Kids mode and the parental gate hook into `redirect` here in Etap 3 (ARCHITECTURE §12).
GoRouter buildRouter() => GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ParentShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/biblioteka',
              builder: (context, state) =>
                  LibraryScreen(filter: LibraryFilter.fromQuery(state.uri.queryParameters)),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/moje', builder: (context, state) => const MineScreen())],
        ),
      ],
    ),
    GoRoute(path: '/moje/narzedzia', builder: (context, state) => const DevToolsScreen()),
    GoRoute(
      path: '/zabawa/:id',
      builder: (context, state) => DetailsScreen(itemId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/odtwarzacz', builder: (context, state) => const PlayerScreen()),
    GoRoute(path: '/odtwarzacz/bez-patrzenia', builder: (context, state) => const NoLookScreen()),
  ],
);

class _ParentShell extends StatelessWidget {
  const _ParentShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_rounded), label: l10n.navHome),
              NavigationDestination(icon: const Icon(Icons.library_music_rounded), label: l10n.navLibrary),
              NavigationDestination(icon: const Icon(Icons.favorite_rounded), label: l10n.navMine),
            ],
          ),
        ],
      ),
    );
  }
}
