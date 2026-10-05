import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/appearance.dart';
import 'features/account/session_gate.dart';
import 'features/home/home_widget_sync.dart';
import 'features/personal/app_icon_screen.dart';
import 'features/kids_mode/kids_mode_controller.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/player/now_playing_pill.dart';
import 'features/welcome/welcome_controller.dart';
import 'l10n/app_localizations.dart';

class AudioKiddoApp extends ConsumerStatefulWidget {
  const AudioKiddoApp({super.key, this.router});

  /// Injected in tests; the app builds its own otherwise.
  final GoRouter? router;

  @override
  ConsumerState<AudioKiddoApp> createState() => _AudioKiddoAppState();
}

class _AudioKiddoAppState extends ConsumerState<AudioKiddoApp> {
  late final GoRouter _router =
      widget.router ??
      buildRouter(
        ref.read(kidsModeProvider),
        ref.read(onboardingProvider),
        ref.read(sessionGateProvider),
        ref.read(welcomeProvider),
      );

  static const _launch = MethodChannel('pl.audiokiddo/launch');

  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () {
      _openLaunchRoute();
      _scheduleAppearance();
    },
  );

  /// Automatic appearance turns dark at 20:00 and light at 6:00, also with the app open.
  Timer? _appearanceTimer;

  void _scheduleAppearance() {
    _appearanceTimer?.cancel();
    final now = DateTime.now();
    _appearanceTimer = Timer(nextAppearanceChange(now).difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {});
      _scheduleAppearance();
    });
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _scheduleAppearance();
    // Keep the home-screen widget in step with the child's plan.
    ref.listenManual<HomeWidgetData?>(
      homeWidgetDataProvider,
      (_, data) => ref.read(homeWidgetSinkProvider).push(data),
      fireImmediately: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openLaunchRoute();
      // Szop’en's weekly mood on the home screen, only if the parent chose it.
      unawaited(maybeRotateIcon(ref.read(databaseProvider), DateTime.now()));
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _appearanceTimer?.cancel();
    super.dispose();
  }

  /// A quick action or Siri shortcut that started the app asks for a screen (iOS keeps it
  /// until the router is ready; Android shortcuts arrive as deep links instead).
  Future<void> _openLaunchRoute() async {
    try {
      final route = await _launch.invokeMethod<String>('takePendingRoute');
      if (route != null && mounted) _router.go(route);
    } on MissingPluginException {
      // Android, tests.
    } on PlatformException {
      // Nothing to open.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: effectiveThemeMode(ref.watch(appearanceProvider).value ?? ThemeMode.light, DateTime.now()),
      locale: const Locale('pl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      // Default status bar for the theme; dark scenes (intro, night screens) set their own.
      // Without it, the last dark scene's white icons stay on after it is gone.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: NowPlayingPill(router: _router, child: child!),
      ),
    );
  }
}
