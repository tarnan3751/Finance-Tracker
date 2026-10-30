// The auth flow on a device, against the in-app fake server. Run on the harness's
// emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The first test starts the demo flavor as main_demo.dart does and finds it signed in as
// the demo user. The second starts the dev flavor, which FT_FAKE_SERVER puts on the fake
// server (it is skipped without the define): register, sign out, sign in, a request after
// the access token expired (refreshed once), and sign out again. The dev flavor opens its
// encrypted database, which the test removes before and after, as
// encrypted_database_test.dart does.
import 'dart:io';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'support/restore_offer.dart';

const String _email = 'flow@example.com';
const String _password = 'correct horse battery';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester tester) => _tap(
  tester,
  find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text('Settings'),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the demo flavor starts signed in as the demo user', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsNothing);
    await _openSettings(tester);
    expect(find.text('Signed in as demo@financetracker.test'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets(
    'dev on the fake server: register, sign out, sign in, refresh, sign out',
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
      expect(find.byType(SignInScreen), findsOneWidget);

      await _tap(tester, find.text('Create an account'));
      await tester.enterText(_field('Email'), _email);
      await tester.enterText(_field('Password'), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Create account'));
      await startFresh(tester);
      expect(find.byType(NavigationBar), findsOneWidget);

      await _openSettings(tester);
      expect(find.text('Signed in as $_email'), findsOneWidget);
      expect(find.text('In-app fake server'), findsOneWidget);
      await _tap(tester, find.text('Sign out'));
      expect(find.byType(SignInScreen), findsOneWidget);

      await tester.enterText(_field('Email'), _email);
      await tester.enterText(_field('Password'), _password);
      await _tap(tester, find.widgetWithText(FilledButton, 'Sign in'));
      expect(find.byType(NavigationBar), findsOneWidget);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      final FakeServer server = container.read(fakeServerProvider);
      server.advanceClock(const Duration(minutes: 16));
      final int refreshes = server.calls
          .where((c) => c == 'refreshTokens')
          .length;
      final user = await container.read(financeApiProvider).getMe();
      expect(user.email, _email);
      expect(
        server.calls.where((c) => c == 'refreshTokens').length,
        refreshes + 1,
      );

      await _openSettings(tester);
      await _tap(tester, find.text('Sign out'));
      expect(find.byType(SignInScreen), findsOneWidget);
    },
    skip: !fakeServerInDev,
  );
}
