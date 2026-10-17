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
/// already present: pop the pages above it and reuse or replace it; otherwise a new page.
Future<void> openPlayerOn(GoRouter router, {bool game = false}) async {
  final target = game ? '/gra' : '/odtwarzacz';
  final stack = routeStack(router);
  final playbackIndex = stack.lastIndexWhere((p) => p == '/odtwarzacz' || p == '/gra');
  if (playbackIndex >= 0) {
    for (var above = stack.length - playbackIndex - 1; above > 0 && router.canPop(); above--) {
      router.pop();
    }
    if (stack[playbackIndex] != target) await router.pushReplacement<void>(target);
    return;
  }
  await router.push<void>(target);
}

Future<void> openPlayer(BuildContext context, {bool game = false}) =>
    openPlayerOn(GoRouter.of(context), game: game);
