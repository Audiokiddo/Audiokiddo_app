import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/details_screen.dart';
import '../features/family/child_quiz.dart';
import '../features/family/family.dart';
import '../features/family/plan_screen.dart';
import '../features/family/progress_screen.dart';
import '../features/catalog/home_screen.dart';
import '../features/catalog/library_filter.dart';
import '../features/catalog/library_screen.dart';
import '../features/access/dev_tools_screen.dart';
import '../features/account/account_screen.dart';
import '../features/games/game_screen.dart';
import '../features/kids_mode/kids_home_screen.dart';
import '../features/kids_mode/kids_mode_controller.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/personal/mine_screen.dart';
import '../features/player/mini_player.dart';
import '../features/player/no_look_screen.dart';
import '../features/player/player_screen.dart';
import '../features/purchases/paywall_screen.dart';
import '../features/reminders/reminder_offer.dart';
import '../features/session/session_screens.dart';

import '../l10n/app_localizations.dart';

/// Kids mode locks navigation to `/dziecko…`: back, deep links and a restart all land there
/// until a parent passes the gate (ARCHITECTURE §12).
String? kidsModeRedirect(KidsModeController kids, String location) {
  final inKidsZone = location == '/dziecko' || location.startsWith('/dziecko/');
  if (kids.active && !inKidsZone) return '/dziecko';
  if (!kids.active && inKidsZone) return '/';
  return null;
}

/// The welcome runs once, before anything else (kids mode can only be set up after it).
String? appRedirect(KidsModeController kids, OnboardingController onboarding, String location) {
  if (!onboarding.done) return location == '/powitanie' ? null : '/powitanie';
  if (location == '/powitanie') return kids.active ? '/dziecko' : '/';
  return kidsModeRedirect(kids, location);
}

GoRouter buildRouter(KidsModeController kids, OnboardingController onboarding) => GoRouter(
  initialLocation: !onboarding.done ? '/powitanie' : (kids.active ? '/dziecko' : '/'),
  refreshListenable: Listenable.merge([kids, onboarding]),
  redirect: (context, state) => appRedirect(kids, onboarding, state.matchedLocation),
  routes: [
    GoRoute(path: '/powitanie', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/dziecko', builder: (context, state) => const KidsHomeScreen()),
    GoRoute(path: '/dziecko/graj', builder: (context, state) => const NoLookScreen()),
    GoRoute(path: '/dziecko/gra', builder: (context, state) => const GameScreen()),
    GoRoute(path: '/gra', builder: (context, state) => const GameScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ParentShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/plan', builder: (context, state) => const PlanScreen())],
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
    GoRoute(path: '/plan/postep', builder: (context, state) => const ProgressScreen()),
    GoRoute(
      path: '/plan/dziecko',
      builder: (context, state) =>
          ChildQuiz(onDone: () => context.canPop() ? context.pop() : context.go('/plan')),
    ),
    GoRoute(path: '/plan/glos', builder: (context, state) => const ParentVoiceScreen()),
    // The home-screen widget opens these through audiokiddo://open/dobranoc and /podroz.
    GoRoute(path: '/podroz', builder: (context, state) => const TripScreen()),
    GoRoute(path: '/dobranoc', builder: (context, state) => const BedtimeScreen()),
    GoRoute(path: '/sesja', builder: (context, state) => const SessionScreen()),
    GoRoute(path: '/konto', builder: (context, state) => const AccountScreen()),
    GoRoute(
      path: '/sklep',
      builder: (context, state) => PaywallScreen(itemId: state.uri.queryParameters['zabawa']),
    ),
    GoRoute(
      path: '/zabawa/:id',
      builder: (context, state) => DetailsScreen(itemId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/odtwarzacz', builder: (context, state) => const PlayerScreen()),
    GoRoute(path: '/odtwarzacz/bez-patrzenia', builder: (context, state) => const NoLookScreen()),
  ],
);

class _ParentShell extends ConsumerWidget {
  const _ParentShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final child = ref.watch(familyProvider).value?.active;
    final todayDone = child == null ? null : ref.watch(planPositionProvider(child.id))?.todayDone;
    return Scaffold(
      // Content scrolls under a frosted bar, as in Apple's apps.
      extendBody: true,
      body: RemindersKeeper(todayDone: todayDone, child: shell),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                destinations: [
                  NavigationDestination(icon: const Icon(Icons.home_rounded), label: l10n.navHome),
                  NavigationDestination(icon: const Icon(Icons.queue_music_rounded), label: l10n.navPlan),
                  NavigationDestination(
                    icon: const Icon(Icons.library_music_rounded),
                    label: l10n.navLibrary,
                  ),
                  NavigationDestination(icon: const Icon(Icons.favorite_rounded), label: l10n.navMine),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
