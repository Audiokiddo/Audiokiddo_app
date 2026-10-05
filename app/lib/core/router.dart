import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

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
import '../features/account/session_gate.dart';
import '../features/account/sign_in_screen.dart';
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
import '../features/referral/referral_screen.dart';
import '../features/reminders/reminder_offer.dart';
import '../features/games/speech_check_screen.dart';
import '../features/personal/app_icon_screen.dart';
import '../features/pdf/case_file_screen.dart';
import '../features/pdf/guide_links.dart';
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
String? appRedirect(
  KidsModeController kids,
  OnboardingController onboarding,
  String location, {
  SessionGate? session,
}) {
  if (!onboarding.done) return location == '/powitanie' ? null : '/powitanie';
  // Signed out on purpose: nothing but the sign-in screen until they sign in or skip.
  if (session?.signedOut ?? false) return location == '/logowanie' ? null : '/logowanie';
  if (location == '/logowanie') return kids.active ? '/dziecko' : '/';
  if (location == '/powitanie') return kids.active ? '/dziecko' : '/';
  return kidsModeRedirect(kids, location);
}

GoRouter buildRouter(
  KidsModeController kids,
  OnboardingController onboarding, [
  SessionGate? session,
]) => GoRouter(
  initialLocation: !onboarding.done ? '/powitanie' : (kids.active ? '/dziecko' : '/'),
  refreshListenable: Listenable.merge([kids, onboarding, ?session]),
  redirect: (context, state) => appRedirect(kids, onboarding, state.matchedLocation, session: session),
  // An unknown or outdated link (old widget, typo) opens Start instead of an error page.
  onException: (context, state, router) => router.go('/'),
  routes: [
    GoRoute(path: '/powitanie', pageBuilder: (context, state) => swipePage(state, const OnboardingScreen())),
    GoRoute(
      path: '/logowanie',
      pageBuilder: (context, state) => NoTransitionPage(child: const SignInScreen()),
    ),
    GoRoute(path: '/dziecko', pageBuilder: (context, state) => swipePage(state, const KidsHomeScreen())),
    GoRoute(path: '/dziecko/graj', pageBuilder: (context, state) => swipePage(state, const NoLookScreen())),
    GoRoute(path: '/dziecko/gra', pageBuilder: (context, state) => swipePage(state, const GameScreen())),
    GoRoute(path: '/gra', pageBuilder: (context, state) => swipePage(state, const GameScreen())),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ParentShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', pageBuilder: (context, state) => swipePage(state, const HomeScreen()))],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/biblioteka',
              // Each filter is its own page (keyed by the whole address), so changing it rebuilds.
              pageBuilder: (context, state) => SwipeablePage<void>(
                key: ValueKey(state.uri.toString()),
                canOnlySwipeFromEdge: true,
                backGestureDetectionWidth: 32,
                builder: (_) => LibraryScreen(filter: LibraryFilter.fromQuery(state.uri.queryParameters)),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/sklep', pageBuilder: (context, state) => swipePage(state, const ShopScreen())),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/moje', pageBuilder: (context, state) => swipePage(state, const MoreScreen())),
          ],
        ),
      ],
    ),
    GoRoute(path: '/ulubione', pageBuilder: (context, state) => swipePage(state, const CollectionScreen())),
    GoRoute(path: '/ratunku', pageBuilder: (context, state) => swipePage(state, const RescueScreen())),
    GoRoute(path: '/rutyny', pageBuilder: (context, state) => swipePage(state, const RoutinesScreen())),
    GoRoute(path: '/kolejka', pageBuilder: (context, state) => swipePage(state, const QueueScreen())),
    GoRoute(path: '/profil', pageBuilder: (context, state) => swipePage(state, const ProfileScreen())),
    GoRoute(path: '/pobrane', pageBuilder: (context, state) => swipePage(state, const DownloadsScreen())),
    GoRoute(
      path: '/historia',
      pageBuilder: (context, state) => swipePage(state, const CollectionScreen(history: true)),
    ),
    GoRoute(path: '/plan', pageBuilder: (context, state) => swipePage(state, const PlanScreen())),
    GoRoute(
      path: '/moje/narzedzia',
      pageBuilder: (context, state) => swipePage(state, const DevToolsScreen()),
    ),
    GoRoute(path: '/plan/postep', pageBuilder: (context, state) => swipePage(state, const ProgressScreen())),
    GoRoute(
      path: '/plan/dziecko',
      pageBuilder: (context, state) =>
          swipePage(state, ChildQuiz(onDone: () => context.canPop() ? context.pop() : context.go('/plan'))),
    ),
    GoRoute(path: '/plan/glos', pageBuilder: (context, state) => swipePage(state, const ParentVoiceScreen())),
    // The home-screen widget opens these through audiokiddo://open/dobranoc and /podroz.
    GoRoute(path: '/podroz', pageBuilder: (context, state) => swipePage(state, const TripScreen())),
    GoRoute(path: '/dobranoc', pageBuilder: (context, state) => swipePage(state, const BedtimeScreen())),
    GoRoute(path: '/sesja', pageBuilder: (context, state) => swipePage(state, const SessionScreen())),
    GoRoute(path: '/polec', pageBuilder: (context, state) => swipePage(state, const ReferralScreen())),
    GoRoute(path: '/konto', pageBuilder: (context, state) => swipePage(state, const AccountScreen())),
    GoRoute(path: '/dostep', pageBuilder: (context, state) => swipePage(state, const AccessScreen())),
    GoRoute(path: '/mowa', pageBuilder: (context, state) => swipePage(state, const SpeechCheckScreen())),
    GoRoute(path: '/ikona', pageBuilder: (context, state) => swipePage(state, const AppIconScreen())),
    GoRoute(
      path: '/oferta',
      pageBuilder: (context, state) =>
          swipePage(state, PaywallScreen(itemId: state.uri.queryParameters['zabawa'])),
    ),
    GoRoute(
      path: '/pakiet/:id',
      pageBuilder: (context, state) => swipePage(state, PackScreen(packId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/pakiet/:id/materialy',
      pageBuilder: (context, state) =>
          swipePage(state, PackMaterialsScreen(packId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/dyplom/:id',
      pageBuilder: (context, state) => swipePage(state, DiplomaScreen(packId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/akta/:id',
      pageBuilder: (context, state) => swipePage(state, CaseFileScreen(itemId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/zabawa/:id',
      pageBuilder: (context, state) => swipePage(state, DetailsScreen(itemId: state.pathParameters['id']!)),
    ),
    // The player slides up like a sheet: pulled down to minimise it, or swiped from the left
    // edge like any other page (then it follows the finger sideways).
    GoRoute(
      path: '/odtwarzacz',
      pageBuilder: (context, state) => SwipeablePage<void>(
        key: state.pageKey,
        canOnlySwipeFromEdge: true,
        backGestureDetectionWidth: 32,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionBuilder: (context, animation, _, isSwipeGesture, child) => SlideTransition(
          position: Tween(begin: isSwipeGesture ? const Offset(1, 0) : const Offset(0, 1), end: Offset.zero)
              .animate(
                isSwipeGesture ? animation : CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
        builder: (_) => const PlayerScreen(),
      ),
    ),
    GoRoute(
      path: '/odtwarzacz/bez-patrzenia',
      pageBuilder: (context, state) => swipePage(state, const NoLookScreen()),
    ),
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
          (icon: Icons.shopping_bag_outlined, selected: Icons.shopping_bag_rounded, label: 'Sklep'),
          (icon: Icons.menu_rounded, selected: Icons.menu_rounded, label: 'Więcej'),
        ],
      ),
    );
  }
}

/// Pages swipe back from the left edge, following the finger with the previous page
/// underneath (iOS-style, on both platforms). Game screens opt out with PopScope.
Page<void> swipePage(GoRouterState state, Widget child) => SwipeablePage<void>(
  key: state.pageKey,
  canOnlySwipeFromEdge: true,
  backGestureDetectionWidth: 32,
  builder: (_) => child,
);

/// The same swipe back for screens pushed directly with the Navigator (PDF preview, editing).
Route<T> swipeRoute<T>({required WidgetBuilder builder}) =>
    SwipeablePageRoute<T>(canOnlySwipeFromEdge: true, backGestureDetectionWidth: 32, builder: builder);
