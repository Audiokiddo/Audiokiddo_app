import 'package:audiokiddo/core/router.dart';
import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/player/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> mount(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, state) => swipePage(state, const Scaffold(body: Text('Dom'))),
        ),
        GoRoute(
          path: '/detail',
          pageBuilder: (_, state) => swipePage(
            state,
            Scaffold(
              body: PullDownToClose(
                child: ListView(
                  physics: PullDownToClose.physics,
                  children: const [SizedBox(height: 1800, child: Text('Szczegóły'))],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(theme: buildTheme(Brightness.light), routerConfig: router));
    router.push('/detail');
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a swipe from the left edge drags the page and goes back; a short one stays', (tester) async {
    final router = await mount(tester);
    var gesture = await tester.startGesture(const Offset(4, 260));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(15, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue, reason: 'a short swipe springs back');

    gesture = await tester.startGesture(const Offset(4, 260));
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('Szczegóły'), findsNothing);
    expect(find.text('Dom'), findsOneWidget);
  });

  testWidgets('scrolling keeps the player; pulling past its top follows the finger and closes', (
    tester,
  ) async {
    final router = await mount(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await tester.pumpAndSettle();

    // A small pull springs back.
    await tester.dragFrom(const Offset(250, 100), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);

    await tester.dragFrom(const Offset(250, 100), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(find.text('Dom'), findsOneWidget);
  });
}
