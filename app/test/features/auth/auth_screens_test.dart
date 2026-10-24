// The sign-in and registration screens on the real client and the fake server: the gate
// sends a signed-out user to sign-in, a sign-in or registration opens the shell, every
// failure shows its text inline, the fields validate before anything is sent, the
// password can be shown, and both screens lay out at twice the text size.
import 'dart:async';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/features/auth/presentation/register_screen.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const String _email = 'ada@example.com';
const String _password = 'correct horse';

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

FakeServer _server(WidgetTester tester) =>
    _container(tester).read(fakeServerProvider);

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Future<void> _fill(WidgetTester tester, {String? name}) async {
  await tester.enterText(_field('Email'), _email);
  await tester.enterText(_field('Password'), _password);
  if (name != null) await tester.enterText(_field('Name (optional)'), name);
}

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('sign-in', () {
    testWidgets(
      'a signed-out user lands on sign-in, then signs in to the shell',
      (tester) async {
        await pumpApp(tester, signedIn: false);
        expect(find.byType(SignInScreen), findsOneWidget);
        _server(tester).seedUser(email: _email, password: _password);

        await _fill(tester);
        await _tapAndSettle(
          tester,
          find.widgetWithText(FilledButton, 'Sign in'),
        );

        expect(find.byType(SignInScreen), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
      },
    );

    testWidgets('each failure shows its text', (tester) async {
      await pumpApp(tester, signedIn: false);
      final FakeServer server = _server(tester);
      server.seedUser(email: _email, password: 'another password');
      final Finder submit = find.widgetWithText(FilledButton, 'Sign in');

      await _fill(tester);
      await _tapAndSettle(tester, submit);
      expect(find.text('The email or password is incorrect.'), findsOneWidget);

      server.failNext('login', 429);
      await _tapAndSettle(tester, submit);
      expect(
        find.text('Too many attempts. Try again in 1 second.'),
        findsOneWidget,
      );

      server.failNextNetwork('login');
      await _tapAndSettle(tester, submit);
      expect(
        find.text(
          "Can't reach the server. Check your connection and try again.",
        ),
        findsOneWidget,
      );
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('fields are checked before anything is sent', (tester) async {
      await pumpApp(tester, signedIn: false);
      await _tapAndSettle(tester, find.widgetWithText(FilledButton, 'Sign in'));
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);

      await tester.enterText(_field('Email'), _email);
      await tester.enterText(_field('Password'), 'short');
      await _tapAndSettle(tester, find.widgetWithText(FilledButton, 'Sign in'));
      expect(find.text('Use 8 to 128 characters'), findsOneWidget);
      expect(_server(tester).calls, isNot(contains('login')));
    });

    testWidgets('the password can be shown and hidden', (tester) async {
      await pumpApp(tester, signedIn: false);
      EditableText password() => tester.widget<EditableText>(
        find.descendant(
          of: _field('Password'),
          matching: find.byType(EditableText),
        ),
      );
      expect(password().obscureText, isTrue);
      await _tapAndSettle(tester, find.byTooltip('Show password'));
      expect(password().obscureText, isFalse);
      await _tapAndSettle(tester, find.byTooltip('Hide password'));
      expect(password().obscureText, isTrue);
    });
  });

  group('registration', () {
    testWidgets('registers from the sign-in screen link', (tester) async {
      await pumpApp(tester, signedIn: false);
      await _tapAndSettle(tester, find.text('Create an account'));
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('This device: Pixel 6'), findsOneWidget);

      await _fill(tester, name: 'Ada');
      await _tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, 'Create account'),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      final InMemoryTokenStore store =
          _container(tester).read(tokenStoreProvider) as InMemoryTokenStore;
      expect(store.session!.user.displayName, 'Ada');
      expect(store.session!.device.name, 'Pixel 6');
    });

    testWidgets('an email with an account, and another account on this '
        'install, are refused inline', (tester) async {
      await pumpApp(tester, signedIn: false, initialLocation: '/register');
      _server(tester).seedUser(email: _email, password: _password);
      final Finder submit = find.widgetWithText(FilledButton, 'Create account');

      await _fill(tester);
      await _tapAndSettle(tester, submit);
      expect(
        find.text('An account with this email already exists.'),
        findsOneWidget,
      );

      (_container(tester).read(
        tokenStoreProvider,
      ) as InMemoryTokenStore).installUserId = 'user-somebody';
      await _tapAndSettle(tester, submit);
      expect(
        find.text(
          "This device already holds another account's data. Sign in with "
          "that account, or clear the app's storage in Android settings to "
          'start over.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a password outside 8 to 128 characters is refused', (
      tester,
    ) async {
      await pumpApp(tester, signedIn: false, initialLocation: '/register');
      await tester.enterText(_field('Email'), _email);
      await tester.enterText(_field('Password'), 'x' * 129);
      await _tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, 'Create account'),
      );
      expect(find.text('Use 8 to 128 characters'), findsOneWidget);
    });
  });

  group('the gate', () {
    testWidgets('sign-out in Settings returns to sign-in', (tester) async {
      await pumpApp(tester, initialLocation: '/settings');
      expect(
        find.text('Signed in as demo@financetracker.test'),
        findsOneWidget,
      );
      await _tapAndSettle(tester, find.text('Sign out'));
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('a session the server ends returns to sign-in', (tester) async {
      await pumpApp(tester);
      final ProviderContainer container = _container(tester);
      container
          .read(fakeServerProvider)
          .failNext('listDevices', 401, code: 'token_revoked');
      Object? failure;
      unawaited(
        container
            .read(financeApiProvider)
            .listDevices()
            .then<void>((_) {}, onError: (Object e) => failure = e),
      );
      await tester.pumpAndSettle();
      expect(failure, isA<TokenRevoked>());
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(await container.read(tokenStoreProvider).read(), isNull);
    });

    testWidgets('dev shows the server; demo has no gate and no sign-out', (
      tester,
    ) async {
      await pumpApp(
        tester,
        config: AppConfig.dev(),
        initialLocation: '/settings',
      );
      expect(find.text('http://10.0.2.2:8080/v1'), findsOneWidget);

      await pumpApp(
        tester,
        config: AppConfig.demo(),
        signedIn: false,
        initialLocation: '/accounts',
      );
      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);

      await pumpApp(
        tester,
        config: AppConfig.demo(),
        initialLocation: '/settings',
      );
      expect(
        find.text('Signed in as demo@financetracker.test'),
        findsOneWidget,
      );
      expect(find.text('Sign out'), findsNothing);
      expect(find.text('Server'), findsNothing);
    });

    testWidgets('a signed-in user is sent from the auth screens to the shell', (
      tester,
    ) async {
      await pumpApp(
        tester,
        config: AppConfig.dev(),
        initialLocation: '/sign-in',
      );
      expect(find.byType(SignInScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  for (final String location in ['/sign-in', '/register']) {
    testWidgets('$location lays out at text scale 2.0 without overflow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        signedIn: false,
        initialLocation: location,
        textScale: 2,
      );
      await _tapAndSettle(tester, find.byType(FilledButton));
      expect(tester.takeException(), isNull);
    });
  }
}
