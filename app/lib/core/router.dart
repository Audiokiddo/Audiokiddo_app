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
import '../features/account/access_screen.dart';
import '../features/account/account_screen.dart';
import '../features/games/game_screen.dart';
import '../features/kids_mode/kids_home_screen.dart';
import '../features/kids_mode/kids_mode_controller.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/diploma/diploma_screen.dart';
import '../features/discovery/parent_screens.dart';
import '../features/discovery/rescue_screen.dart';
import '../features/discovery/routines_screen.dart';
import '../features/discovery/queue_screen.dart';
import '../features/player/bottom_dock.dart';
import '../features/player/no_look_screen.dart';
import '../features/player/player_screen.dart';
import '../features/purchases/paywall_screen.dart';
import '../features/purchases/shop_screen.dart';
import '../features/reminders/reminder_offer.dart';
import '../features/games/speech_check_screen.dart';
import '../features/personal/app_icon_screen.dart';
import '../features/session/session_screens.dart';

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
  // An unknown or outdated link (old widget, typo) opens Start instead of an error page.
  onException: (context, state, router) => router.go('/'),
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
          routes: [
            GoRoute(
              path: '/biblioteka',
              builder: (context, state) =>
                  LibraryScreen(filter: LibraryFilter.fromQuery(state.uri.queryParameters)),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/ulubione', builder: (context, state) => const CollectionScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/moje', builder: (context, state) => const MoreScreen())],
        ),
      ],
    ),
    GoRoute(path: '/sklep', builder: (context, state) => const ShopScreen()),
    GoRoute(path: '/ratunku', builder: (context, state) => const RescueScreen()),
    GoRoute(path: '/rutyny', builder: (context, state) => const RoutinesScreen()),
    GoRoute(path: '/kolejka', builder: (context, state) => const QueueScreen()),
    GoRoute(path: '/profil', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/pobrane', builder: (context, state) => const DownloadsScreen()),
    GoRoute(path: '/historia', builder: (context, state) => const CollectionScreen(history: true)),
    GoRoute(path: '/plan', builder: (context, state) => const PlanScreen()),
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
    GoRoute(path: '/dostep', builder: (context, state) => const AccessScreen()),
    GoRoute(path: '/mowa', builder: (context, state) => const SpeechCheckScreen()),
    GoRoute(path: '/ikona', builder: (context, state) => const AppIconScreen()),
    GoRoute(
      path: '/oferta',
      builder: (context, state) => PaywallScreen(itemId: state.uri.queryParameters['zabawa']),
    ),
    GoRoute(
      path: '/pakiet/:id',
      builder: (context, state) => PackScreen(packId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/dyplom/:id',
      builder: (context, state) => DiplomaScreen(packId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/zabawa/:id',
      builder: (context, state) => DetailsScreen(itemId: state.pathParameters['id']!),
    ),
    // The player slides up like a sheet and is pulled down to minimise it.
    GoRoute(
      path: '/odtwarzacz',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PlayerScreen(),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    ),
    GoRoute(path: '/odtwarzacz/bez-patrzenia', builder: (context, state) => const NoLookScreen()),
  ],
);

class _ParentShell extends ConsumerWidget {
  const _ParentShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(familyProvider).value?.active;
    final todayDone = child == null ? null : ref.watch(planPositionProvider(child.id))?.todayDone;
    return Scaffold(
      body: RemindersKeeper(todayDone: todayDone, child: shell),
      bottomNavigationBar: BottomDock(
        current: shell.currentIndex,
        onTab: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        tabs: const [
          (icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Start'),
          (icon: Icons.auto_stories_outlined, selected: Icons.auto_stories_rounded, label: 'Biblioteka'),
          (icon: Icons.favorite_border_rounded, selected: Icons.favorite_rounded, label: 'Ulubione'),
          (icon: Icons.menu_rounded, selected: Icons.menu_rounded, label: 'Więcej'),
        ],
      ),
    );
  }
}

/// Screens a child uses: no swipe-back there (games are left by holding a button).
bool noSwipeBack(String path) =>
    path.startsWith('/dziecko') || path == '/gra' || path == '/powitanie' || path.startsWith('/odtwarzacz');

/// A swipe from the left edge goes back, on every screen and platform, also where the
/// system gesture does not reach (iOS only listens to the first 20 points).
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  double _dx = 0;

  void _back() {
    final router = widget.router;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (noSwipeBack(path) || !router.canPop()) return;
    router.pop();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: 24,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => _dx = 0,
          onHorizontalDragUpdate: (d) => _dx += d.delta.dx,
          onHorizontalDragEnd: (d) {
            if (_dx > 70 || (d.primaryVelocity ?? 0) > 700) _back();
          },
        ),
      ),
    ],
  );
}
