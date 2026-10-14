import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Pages on the stack, bottom to top. `currentConfiguration.uri` is no use for this: after a
/// `push` it still names the page underneath, so the player looked "not open" and every tap on
/// "next play" stacked another one.
List<String> routeStack(GoRouter router) {
  final out = <String>[];
  void walk(List<RouteMatchBase> matches) {
    for (final m in matches) {
      if (m is ShellRouteMatch) {
        walk(m.matches);
      } else {
        out.add(m.matchedLocation);
      }
    }
  }

  walk(router.routerDelegate.currentConfiguration.matches);
  return out;
}

/// Opens the player (or the game screen) so there is only ever one of them on the stack:
/// already on top: nothing; the other one on top: replaced; the player right below the page
/// that asks (the queue opened from it): back to it; otherwise a new page.
Future<void> openPlayerOn(GoRouter router, {bool game = false}) async {
  final target = game ? '/gra' : '/odtwarzacz';
  final stack = routeStack(router);
  final top = stack.isEmpty ? '/' : stack.last;
  if (top == target) return;
  if (top == '/odtwarzacz' || top == '/gra') {
    await router.pushReplacement<void>(target);
  } else if (stack.length >= 2 && stack[stack.length - 2] == target && router.canPop()) {
    router.pop();
  } else {
    await router.push<void>(target);
  }
}

Future<void> openPlayer(BuildContext context, {bool game = false}) =>
    openPlayerOn(GoRouter.of(context), game: game);
