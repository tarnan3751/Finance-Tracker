// The developer menu on a device, against the in-app fake server. Run on the harness's
// emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The dev flavor, which FT_FAKE_SERVER puts on the fake server (skipped without the
// define), over its encrypted database (removed before and after): register and link
// First Platypus Bank, then from Settings → Developer → Sandbox controls reset its login
// and see Linked banks ask for the connection to be fixed, fix it, and inject two
// transactions and see them in Transactions.
import 'dart:io';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/features/developer/application/developer_controller.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:finance_tracker/features/items/domain/item_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'support/restore_offer.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// How long a wait for the app may last, in wall-clock time: on an emulator loaded by
/// several lanes, the Link flow has taken longer than 30 s.
const Duration _patience = Duration(seconds: 120);

/// Pumps until [done]: the Item flows wait 5 s between sync requests, in real time.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  final Stopwatch waited = Stopwatch()..start();
  while (waited.elapsed < _patience) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (done()) return;
  fail('the app never got there in ${_patience.inSeconds} s');
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// Pumps until no Item action and no developer operation runs.
Future<void> _settle(WidgetTester tester) async {
  final ProviderContainer container = _container(tester);
  await _pumpUntil(tester, () {
    final LinkState link = container.read(linkControllerProvider);
    return !(link.newLink?.isRunning ?? false) &&
        !link.byItem.values.any((a) => a.isRunning) &&
        container.read(developerControllerProvider).running == null;
  });
  await tester.pumpAndSettle();
}

/// Scrolls the screen's list by [delta] steps until [finder] is built.
Future<void> _scrollTo(WidgetTester tester, Finder finder, double delta) =>
    tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

Future<void> _openSandboxControls(WidgetTester tester) async {
  await _tap(tester, _tab('Settings'));
  // The Developer section is the last of Settings, built once scrolled to.
  await tester.scrollUntilVisible(
    find.text('Sandbox controls'),
    300,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await _tap(tester, find.text('Sandbox controls'));
  expect(find.widgetWithText(AppBar, 'Sandbox controls'), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'dev on the fake server: reset login and fix it, inject and see the rows',
    (tester) async {
      final File database = File(
        p.join((await getApplicationSupportDirectory()).path, databaseFileName),
      );
      if (database.existsSync()) database.deleteSync();
      addTearDown(() {
        if (database.existsSync()) database.deleteSync();
      });
      await bootstrap(AppConfig.dev());
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Create an account'));
      await tester.enterText(_field('Email'), 'developer@example.com');
      await tester.enterText(_field('Password'), 'correct horse battery');
      await _tap(tester, find.widgetWithText(FilledButton, 'Create account'));
      await startFresh(tester);

      await _tap(tester, _tab('Settings'));
      await _tap(tester, find.text('Linked banks'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Link a bank'));
      await _settle(tester);
      expect(find.text('Connected'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Reset login: the pull after it shows the bank needing attention.
      await _openSandboxControls(tester);
      expect(find.text('First Platypus Bank (sample-item-1)'), findsOneWidget);
      await _tap(tester, find.text('Reset login'));
      await _settle(tester);
      expect(
        find.text('Login reset; the Item needs its connection fixed'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('Linked banks'), -300);
      await _tap(tester, find.text('Linked banks'));
      expect(find.text('Needs attention'), findsOneWidget);
      await _tap(tester, find.text('Fix connection'));
      await _settle(tester);
      expect(find.text('Connected'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Inject two transactions dated Plaid's today, and see them arrive.
      await _openSandboxControls(tester);
      await _scrollTo(tester, _field('How many (1 to 10)'), 300);
      await tester.enterText(_field('How many (1 to 10)'), '2');
      await tester.enterText(_field('Description'), 'Harness coffee');
      await _scrollTo(tester, find.widgetWithText(FilledButton, 'Inject'), 300);
      await _tap(tester, find.widgetWithText(FilledButton, 'Inject'));
      await _settle(tester);
      // The outcome line sits above the form, with the Item's other controls.
      final DeveloperResult result = _container(tester)
          .read(developerControllerProvider)
          .result!;
      expect(result.failure, isNull);
      expect(result.pullFailure, isNull);
      expect(result.injected, 2);
      await _scrollTo(tester, find.text('Injected 2 transactions'), -300);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tap(tester, _tab('Transactions'));
      // The rows show the merchant name cleaned of its number (transactions.md,
      // **Merchants**).
      expect(find.text('Harness coffee'), findsNWidgets(2));
    },
    skip: !fakeServerInDev,
  );
}
