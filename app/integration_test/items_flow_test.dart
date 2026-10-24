// Linked banks on a device, against the in-app fake server and the fake Link launcher.
// Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The first test starts the demo flavor as main_demo.dart does: Linked banks lists the
// persona's banks, and Link a bank adds Houndstooth Bank, which no persona uses, with its
// accounts and transactions. The second
// starts the dev flavor, which FT_FAKE_SERVER puts on the fake server (skipped without
// the define), over its encrypted database (removed before and after): register, link
// First Platypus Bank and see its accounts, have the fake reset its login and repair it
// with Fix connection, then unlink it deleting its history and see them go.
import 'dart:io';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:finance_tracker/features/items/domain/item_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:persona_engine/persona_engine.dart' show DemoSeed;

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Pumps until [done]: the Link flow waits 5 s between sync requests, in real time on a
/// device.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (int i = 0; i < 300; i++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('the app never got there');
}

/// Pumps until no Item action runs (one may have ended failed, which stays shown).
Future<void> _settleActions(WidgetTester tester) {
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  return _pumpUntil(tester, () {
    final LinkState state = container.read(linkControllerProvider);
    return !(state.newLink?.isRunning ?? false) &&
        !state.byItem.values.any((a) => a.isRunning);
  });
}

Future<void> _openLinkedBanks(WidgetTester tester) async {
  await _tap(tester, _tab('Accounts'));
  await _tap(tester, find.byTooltip('Linked banks'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: the persona\'s banks, and Link a bank adds one more', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final DemoSeed seed = container.read(demoSeedProvider);

    await _openLinkedBanks(tester);
    for (final institution in seed.household.institutions) {
      expect(find.text(institution.name), findsWidgets);
    }
    expect(find.text('Houndstooth Bank'), findsNothing);
    await _tap(tester, find.text('Link a bank'));
    await _settleActions(tester);
    await tester.pumpAndSettle();
    expect(find.text('Houndstooth Bank'), findsOneWidget);
    final List<String> banks = [
      for (final b
          in await container.read(itemRepositoryProvider).watchAll().first)
        b.id,
    ];
    expect(banks, contains('demo-houndstooth'));
    // Its accounts and transactions came with it: each account has a balance from
    // transactions, and the Accounts tab lists them.
    expect(
      await container
          .read(transactionRepositoryProvider)
          .watchById('sample-txn-01')
          .first,
      isNotNull,
    );
    for (final String account in [
      'sample-checking',
      'sample-savings',
      'sample-card',
    ]) {
      expect(
        await container
            .read(accountRepositoryProvider)
            .watchDerivedBalance(account)
            .first,
        isNotNull,
        reason: account,
      );
    }
    // Tapping the current tab returns it to the account list.
    await _tap(tester, _tab('Accounts'));
    await tester.scrollUntilVisible(find.text('Houndstooth Checking'), 300);
    expect(find.text('Houndstooth Checking'), findsOneWidget);
  });

  testWidgets(
    'dev on the fake server: link a bank, then unlink it deleting its history',
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
      await tester.enterText(_field('Email'), 'banks@example.com');
      await tester.enterText(_field('Password'), 'correct horse battery');
      await _tap(tester, find.widgetWithText(FilledButton, 'Create account'));

      await _tap(tester, _tab('Settings'));
      await _tap(tester, find.text('Linked banks'));
      expect(find.text('No linked banks'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Link a bank'));
      await _settleActions(tester);
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('First Platypus Bank'), findsOneWidget);

      await _tap(tester, _tab('Accounts'));
      expect(find.text('Platypus Checking'), findsOneWidget);
      expect(find.text('Platypus Savings'), findsOneWidget);

      // The fake's sandbox route resets the login: the next sync says so, and Fix
      // connection repairs it through update-mode Link.
      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      await container
          .read(financeApiProvider)
          .sandboxResetLogin('sample-item-1');
      await _openLinkedBanks(tester);
      await _tap(tester, find.text('Sync now'));
      await _settleActions(tester);
      await tester.pumpAndSettle();
      expect(find.text('Needs attention'), findsOneWidget);
      await _tap(tester, find.text('Fix connection'));
      await _settleActions(tester);
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Fix connection'), findsNothing);

      await _tap(tester, find.text('Unlink'));
      await _tap(tester, find.text('Delete its accounts and transactions'));
      await _tap(tester, find.widgetWithText(TextButton, 'Unlink').last);
      await _settleActions(tester);
      await tester.pumpAndSettle();
      expect(find.text('No linked banks'), findsOneWidget);

      await _tap(tester, _tab('Accounts'));
      expect(find.text('Platypus Checking'), findsNothing);
    },
    skip: !fakeServerInDev,
  );
}
