import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/kids_mode/kids_mode_controller.dart';
import 'l10n/app_localizations.dart';

class AudioKiddoApp extends ConsumerStatefulWidget {
  const AudioKiddoApp({super.key, this.router});

  /// Injected in tests; the app builds its own otherwise.
  final GoRouter? router;

  @override
  ConsumerState<AudioKiddoApp> createState() => _AudioKiddoAppState();
}

class _AudioKiddoAppState extends ConsumerState<AudioKiddoApp> {
  late final GoRouter _router = widget.router ?? buildRouter(ref.read(kidsModeProvider));

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('pl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
