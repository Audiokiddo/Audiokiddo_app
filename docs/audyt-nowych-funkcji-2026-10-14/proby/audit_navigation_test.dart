import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:audiokiddo/core/open_player.dart';

void main() {
  late GoRouter router;

  Future<void> boot(WidgetTester tester) async {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('start')),
        ),
        GoRoute(
          path: '/odtwarzacz',
          builder: (_, _) => const Scaffold(body: Text('player')),
        ),
        GoRoute(
          path: '/gra',
          builder: (_, _) => const Scaffold(body: Text('game')),
        ),
        GoRoute(
          path: '/kolejka',
          builder: (_, _) => const Scaffold(body: Text('queue')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  testWidgets('the player is opened once however often it is asked for', (tester) async {
    await boot(tester);
    unawaited(openPlayerOn(router));
    await tester.pumpAndSettle();
    // "Next in pack" from the player: still one player (the old check read the page below).
    unawaited(openPlayerOn(router));
    unawaited(openPlayerOn(router));
    await tester.pumpAndSettle();
    expect(routeStack(router).where((p) => p == '/odtwarzacz'), hasLength(1));
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('start'), findsOneWidget);
  });

  testWidgets('a game replaces the player instead of piling on it', (tester) async {
    await boot(tester);
    unawaited(openPlayerOn(router));
    await tester.pumpAndSettle();
    unawaited(openPlayerOn(router, game: true));
    await tester.pumpAndSettle();
    expect(routeStack(router).where((p) => p == '/odtwarzacz' || p == '/gra'), ['/gra']);
  });

  testWidgets('the queue opened from the player goes back to it', (tester) async {
    await boot(tester);
    unawaited(openPlayerOn(router));
    await tester.pumpAndSettle();
    unawaited(router.push<void>('/kolejka'));
    await tester.pumpAndSettle();
    unawaited(openPlayerOn(router));
    await tester.pumpAndSettle();
    expect(find.text('player'), findsOneWidget);
    expect(routeStack(router).where((p) => p == '/odtwarzacz'), hasLength(1));
    expect(routeStack(router), isNot(contains('/kolejka')));
  });
  testWidgets('AUDIT: game selected from queue replaces existing player', (tester) async {
    await boot(tester);
    unawaited(openPlayerOn(router));
    await tester.pumpAndSettle();
    unawaited(router.push<void>('/kolejka'));
    await tester.pumpAndSettle();
    unawaited(openPlayerOn(router, game: true));
    await tester.pumpAndSettle();
    expect(routeStack(router).where((p) => p == '/odtwarzacz' || p == '/gra'), ['/gra']);
  });
}