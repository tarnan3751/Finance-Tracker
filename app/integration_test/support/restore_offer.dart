// Past a fresh install's restore offer in an integration flow: a sign-in or registration
// on an empty database lands on /restore (`docs/reference/backup.md`, **Restore**), and
// sync waits until it is answered, so a flow that starts fresh answers it first. Not a
// test file itself: the flows import it.
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// How long the offer may take to show, in wall-clock time.
const Duration _patience = Duration(seconds: 120);

/// Pumps until the restore offer shows, taps Start fresh, then pumps until the router
/// has left `/restore` for the shell (the answer is written first), so a route the flow
/// pushes next lands on the shell's stack.
Future<void> startFresh(WidgetTester tester) async {
  final Finder fresh = find.text('Start fresh');
  await _pumpWhile(tester, () => fresh.evaluate().isEmpty, 'showed');
  await tester.tap(fresh);
  await _pumpWhile(
    tester,
    () =>
        fresh.evaluate().isNotEmpty ||
        find.byType(NavigationBar).evaluate().isEmpty ||
        _location(tester) == const RestoreOfferRoute().location,
    'went',
  );
  await tester.pumpAndSettle();
}

String _location(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(goRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

Future<void> _pumpWhile(
  WidgetTester tester,
  bool Function() waiting,
  String what,
) async {
  final Stopwatch waited = Stopwatch()..start();
  while (waiting()) {
    if (waited.elapsed > _patience) {
      fail('the restore offer never $what in ${_patience.inSeconds} s');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
