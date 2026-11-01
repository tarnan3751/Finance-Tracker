// The Server field of a build with no compiled URL: shown on sign-in and registration
// (and not over a compiled or fake address), refusing what is not an address and, in
// prod, plain http before anything is sent; an unreachable server and something that is
// not a Spendthrift server shown under the field with no sign-in tried; a good one
// kept and used, the sign-in going on; registration the same; Settings showing the
// entered server; and "Try the demo instead" on a new live install going back to
// Welcome.
import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/server_address.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/server_check.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../core/api/support/fake_api.dart';
import '../../core/api/support/scripted_adapter.dart';
import '../../helpers/pump_app.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

const String _email = 'ada@example.com';
const String _password = 'correct horse';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// A build with no compiled URL: the address editable, kept in [modes], checked over
/// [health]'s answers.
List<Override> _overrides({
  required ServerAddress address,
  required InMemoryAppModeStore modes,
  required ScriptedAdapter health,
}) => [
  serverAddressProvider.overrideWithValue(address),
  appModeStoreProvider.overrideWithValue(modes),
  serverCheckProvider.overrideWith(
    (ref) => ServerCheck(
      config: AppConfig.prod(),
      clock: fakeClientClock,
      version: () async => '1.0.0',
      adapter: health,
    ),
  ),
];

Answer _healthy(RequestOptions options, Object? body) =>
    ok({'status': 'ok', 'version': contractVersion});

Future<void> _submit(WidgetTester tester, String label) async {
  final Finder button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a compiled or fake server shows no field', (tester) async {
    await pumpApp(tester, signedIn: false);
    expect(_field(l10n.serverFieldLabel), findsNothing);
  });

  testWidgets('sign-in checks the server first, then keeps and uses it', (
    tester,
  ) async {
    final ServerAddress address = ServerAddress();
    final InMemoryAppModeStore modes = InMemoryAppModeStore(mode: AppMode.live);
    Answer Function(RequestOptions, Object?) answer = (options, _) =>
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'refused',
        );
    final ScriptedAdapter health = ScriptedAdapter(
      (options, body) => answer(options, body),
    );
    await pumpApp(
      tester,
      signedIn: false,
      overrides: _overrides(address: address, modes: modes, health: health),
    );
    final FakeServer server = _container(tester).read(fakeServerProvider);
    server.seedUser(email: _email, password: _password);
    expect(_field(l10n.serverFieldLabel), findsOneWidget);
    await tester.enterText(_field(l10n.authEmailLabel), _email);
    await tester.enterText(_field(l10n.authPasswordLabel), _password);

    // Not an address, then plain http: refused before anything is sent.
    await tester.enterText(_field(l10n.serverFieldLabel), 'money.example');
    await _submit(tester, l10n.signInSubmit);
    expect(find.text(l10n.serverUrlInvalid), findsOneWidget);
    await tester.enterText(
      _field(l10n.serverFieldLabel),
      'http://money.example.com',
    );
    await _submit(tester, l10n.signInSubmit);
    expect(find.text(l10n.serverUrlNotHttps), findsOneWidget);
    expect(health.requests, isEmpty);

    // Unreachable, then something else: shown, no sign-in tried.
    await tester.enterText(
      _field(l10n.serverFieldLabel),
      'https://money.example.com',
    );
    await _submit(tester, l10n.signInSubmit);
    expect(find.text(l10n.serverUnreachable), findsOneWidget);
    answer = (_, _) => problem(404, 'not_found');
    await _submit(tester, l10n.signInSubmit);
    expect(find.text(l10n.serverNotFinanceTracker), findsOneWidget);
    expect(server.calls.where((c) => c.contains('login')), isEmpty);
    expect(modes.serverUrl, isNull);
    expect(address.entered, isNull);

    // A Spendthrift server: kept, used, and the sign-in goes on.
    answer = _healthy;
    await _submit(tester, l10n.signInSubmit);
    expect(modes.serverUrl, Uri.parse('https://money.example.com'));
    expect(address.entered, Uri.parse('https://money.example.com'));
    expect(health.count('GET', '/health'), 3);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a server already kept is not checked again', (tester) async {
    final ScriptedAdapter health = ScriptedAdapter(_healthy);
    final Uri kept = Uri.parse('https://money.example.com');
    await pumpApp(
      tester,
      signedIn: false,
      overrides: _overrides(
        address: ServerAddress(entered: kept),
        modes: InMemoryAppModeStore(mode: AppMode.live, serverUrl: kept),
        health: health,
      ),
    );
    _container(tester)
        .read(fakeServerProvider)
        .seedUser(email: _email, password: _password);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: _field(l10n.serverFieldLabel),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      kept.toString(),
    );
    await tester.enterText(_field(l10n.authEmailLabel), _email);
    await tester.enterText(_field(l10n.authPasswordLabel), _password);
    await _submit(tester, l10n.signInSubmit);
    expect(health.requests, isEmpty);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Settings shows the server entered.
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsServer), findsOneWidget);
    expect(find.text(apiBaseUrl(kept)), findsOneWidget);
  });

  testWidgets('registration checks and keeps the server too', (tester) async {
    final ServerAddress address = ServerAddress();
    final InMemoryAppModeStore modes = InMemoryAppModeStore(mode: AppMode.live);
    await pumpApp(
      tester,
      signedIn: false,
      initialLocation: '/register',
      overrides: _overrides(
        address: address,
        modes: modes,
        health: ScriptedAdapter(_healthy),
      ),
    );
    await tester.enterText(
      _field(l10n.serverFieldLabel),
      'https://money.example.com',
    );
    await tester.enterText(_field(l10n.authEmailLabel), _email);
    await tester.enterText(_field(l10n.authPasswordLabel), _password);
    await _submit(tester, l10n.registerSubmit);
    expect(modes.serverUrl, Uri.parse('https://money.example.com'));
    expect(address.entered, Uri.parse('https://money.example.com'));
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a new live install can go back to try the demo', (tester) async {
    final InMemoryAppModeStore modes = InMemoryAppModeStore(mode: AppMode.live);
    final List<int> restarts = [];
    await pumpApp(
      tester,
      signedIn: false,
      config: AppConfig.prod().withChoices(mode: AppMode.live),
      overrides: [
        appModeStoreProvider.overrideWithValue(modes),
        appModeRestartProvider.overrideWithValue(() async => restarts.add(1)),
      ],
    );
    final Finder back = find.text(l10n.signInTryDemo);
    await tester.ensureVisible(back);
    await tester.tap(back);
    // The restart replaces the app; here the screen stays busy.
    await tester.pump();
    expect(modes.mode, isNull);
    expect(restarts, hasLength(1));
  });

  testWidgets('not on an install that holds an account, nor a built one', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);
    expect(find.text(l10n.signInTryDemo), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(
      tester,
      signedIn: false,
      config: AppConfig.prod().withChoices(mode: AppMode.live),
      overrides: [
        tokenStoreProvider.overrideWith(
          (ref) => InMemoryTokenStore(installUserId: 'user-1'),
        ),
      ],
    );
    expect(find.text(l10n.signInTryDemo), findsNothing);
  });

  testWidgets('the field lays out at twice the text size', (tester) async {
    await pumpApp(
      tester,
      signedIn: false,
      textScale: 2,
      overrides: _overrides(
        address: ServerAddress(),
        modes: InMemoryAppModeStore(),
        health: ScriptedAdapter(_healthy),
      ),
    );
    await _submit(tester, l10n.signInSubmit);
    expect(find.text(l10n.serverUrlEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('going back says so when the store refuses', (tester) async {
    final List<int> restarts = [];
    await pumpApp(
      tester,
      signedIn: false,
      config: AppConfig.prod().withChoices(mode: AppMode.live),
      overrides: [
        appModeStoreProvider.overrideWithValue(_RefusingClear()),
        appModeRestartProvider.overrideWithValue(() async => restarts.add(1)),
      ],
    );
    final Finder back = find.text(l10n.signInTryDemo);
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text(l10n.modeChoiceFailed), findsOneWidget);
    expect(restarts, isEmpty);
    // Not busy: Sign in is a button again.
    expect(
      find.widgetWithText(FilledButton, l10n.signInSubmit),
      findsOneWidget,
    );
  });
}

/// A store whose clear is refused.
final class _RefusingClear extends Fake implements AppModeStore {
  @override
  Future<void> clear() async => throw StateError('storage refused');
}
