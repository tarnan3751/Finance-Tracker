// The devices screen and a session ended elsewhere: the list with this device marked
// and when each last synced, pull to refresh, removing another device (and a refusal),
// "Sign out everywhere else" going on past a failure, removing this device signing out
// here with no notice and the data kept, the list's error state; then the sign-in
// screen's one-time notice after a remote sign-out, and its offer to erase the device
// with the notice and with the another-account refusal.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/auth/application/devices_controller.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/auth/presentation/devices_screen.dart';
import 'package:finance_tracker/features/auth/presentation/sign_in_screen.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../core/api/support/fake_api.dart';
import '../../helpers/pump_app.dart';

final AppLocalizations l10n = lookupAppLocalizations(const Locale('en'));

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

FakeServer _server(WidgetTester tester) =>
    _container(tester).read(fakeServerProvider);

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Signs [name] in as the demo user on the app's fake server.
FakeClient _another(WidgetTester tester, String name) => FakeClient.signedIn(
  _server(tester),
  email: demoEmail,
  password: demoPassword,
  deviceName: name,
);

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

Future<void> _removeFromMenu(WidgetTester tester, String name) async {
  await _tapAndSettle(tester, find.byTooltip(l10n.devicesActions(name)));
  await _tapAndSettle(tester, find.text(l10n.devicesRemove));
  await _tapAndSettle(
    tester,
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(l10n.devicesRemove),
    ),
  );
}

void main() {
  Future<void> pumpDevices(WidgetTester tester) =>
      pumpApp(tester, initialLocation: const DevicesRoute().location);

  testWidgets('Settings opens the devices; the demo has no entry', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');
    await _tapAndSettle(tester, find.text(l10n.settingsDevices));
    expect(find.byType(DevicesScreen), findsOneWidget);
  });

  testWidgets('lists the devices with this one marked and when each was '
      'last seen', (tester) async {
    await pumpDevices(tester);
    expect(
      find.text('${l10n.devicesThisDevice} · ${l10n.devicesNeverSynced}'),
      findsOneWidget,
    );
    expect(find.text(l10n.devicesSignOutOthers), findsNothing);

    final FakeClient tablet = _another(tester, 'Tablet');
    await tester.runAsync(() => tablet.api.pullChanges(since: 0, limit: 10));
    await _pullToRefresh(tester);
    expect(find.text('Tablet'), findsOneWidget);
    expect(find.textContaining('Last seen Oct 24, 2026'), findsOneWidget);
    expect(find.text(l10n.devicesSignOutOthers), findsOneWidget);
  });

  testWidgets('removes another device, and says when it cannot', (
    tester,
  ) async {
    await pumpDevices(tester);
    _another(tester, 'Tablet');
    await _pullToRefresh(tester);

    _server(tester).failNext('deleteDevice', 500);
    await _removeFromMenu(tester, 'Tablet');
    expect(find.text(l10n.devicesRemoveFailed('Tablet')), findsOneWidget);
    expect(find.text('Tablet'), findsOneWidget);

    await _removeFromMenu(tester, 'Tablet');
    expect(find.text('Tablet'), findsNothing);
    expect(_container(tester).read(sessionControllerProvider), isA<SignedIn>());
  });

  testWidgets('signs out everywhere else, going on past a failure', (
    tester,
  ) async {
    await pumpDevices(tester);
    _another(tester, 'Tablet');
    _another(tester, 'Laptop');
    await _pullToRefresh(tester);
    expect(find.byType(ListTile), findsNWidgets(3));

    _server(tester).failNext('deleteDevice', 500);
    await _tapAndSettle(tester, find.text(l10n.devicesSignOutOthers));
    expect(find.text(l10n.devicesSignOutOthersTitle), findsOneWidget);
    await _tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.devicesSignOutOthers),
      ),
    );
    expect(find.text(l10n.devicesSignOutOthersFailed(1)), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));

    await _tapAndSettle(tester, find.text(l10n.devicesSignOutOthers));
    await _tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.devicesSignOutOthers),
      ),
    );
    expect(find.text(l10n.devicesSignOutOthersDone(1)), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text(l10n.devicesSignOutOthers), findsNothing);
  });

  testWidgets('removing this device signs out here, with no notice and the '
      'data kept', (tester) async {
    await pumpDevices(tester);
    final ProviderContainer container = _container(tester);
    final TokenStore tokens = container.read(tokenStoreProvider);
    final String? installUser = await tokens.readInstallUserId();
    await _tapAndSettle(
      tester,
      find.byTooltip(l10n.devicesActions('Demo device')),
    );
    await _tapAndSettle(tester, find.text(l10n.devicesRemove));
    expect(find.text(l10n.devicesRemoveThisTitle), findsOneWidget);
    await _tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.devicesRemove),
      ),
    );

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(l10n.signInRemoteNotice), findsNothing);
    expect(_server(tester).calls, isNot(contains('logout')));
    expect(await tokens.read(), isNull);
    expect(await tokens.readInstallUserId(), installUser);
  });

  testWidgets('a list that cannot be read says so and tries again', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');
    _server(tester).failNext('listDevices', 500);
    await _tapAndSettle(tester, find.text(l10n.settingsDevices));
    expect(find.text(l10n.devicesLoadFailed), findsOneWidget);
    await _tapAndSettle(tester, find.text(l10n.devicesRetry));
    expect(find.text(l10n.devicesLoadFailed), findsNothing);
    expect(find.textContaining(l10n.devicesThisDevice), findsOneWidget);
  });

  group('signed out elsewhere', () {
    late List<WipeReason> wipes;
    setUp(() => wipes = []);

    Future<void> pumpRevoked(WidgetTester tester) async {
      await pumpApp(
        tester,
        initialLocation: '/settings',
        overrides: [
          wipeLocalDataProvider.overrideWithValue(
            (reason) async => wipes.add(reason),
          ),
        ],
      );
      final ProviderContainer container = _container(tester);
      final Session session = (await container
          .read(tokenStoreProvider)
          .read())!;
      await tester.runAsync(
        () => _another(tester, 'Tablet').api.deleteDevice(session.deviceId),
      );
      container.read(financeApiProvider).listDevices().ignore();
      await tester.pumpAndSettle();
    }

    testWidgets('the sign-in screen says so once', (tester) async {
      await pumpRevoked(tester);
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text(l10n.signInRemoteNotice), findsOneWidget);
      expect(find.text(l10n.signInEraseDevice), findsOneWidget);

      await _tapAndSettle(tester, find.text(l10n.signInCreateAccount));
      await _tapAndSettle(tester, find.text(l10n.registerHaveAccount));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text(l10n.signInRemoteNotice), findsNothing);
      expect(
        find.text(l10n.signInEraseDevice),
        findsOneWidget,
        reason: 'the install still holds the account\'s data',
      );
    });

    testWidgets('and offers to erase the device', (tester) async {
      await pumpRevoked(tester);
      await _tapAndSettle(tester, find.text(l10n.signInEraseDevice));
      expect(find.text(l10n.eraseDeviceTitle), findsOneWidget);
      await _tapAndSettle(tester, find.text(l10n.eraseDeviceConfirm));
      expect(wipes, [WipeReason.deviceErased]);
    });
  });

  group('an install that holds an account\'s data', () {
    late List<WipeReason> wipes;
    setUp(() => wipes = []);

    /// Signed out at registration, the install's user recorded as [installUser].
    Future<void> pumpHeld(WidgetTester tester, String? installUser) async {
      await pumpApp(
        tester,
        signedIn: false,
        initialLocation: '/register',
        overrides: [
          wipeLocalDataProvider.overrideWithValue(
            (reason) async => wipes.add(reason),
          ),
        ],
      );
      (_container(tester).read(
        tokenStoreProvider,
      ) as InMemoryTokenStore).installUserId = installUser;
    }

    testWidgets('the sign-in screen offers to erase it, notice or not', (
      tester,
    ) async {
      await pumpHeld(tester, 'someone-else');
      await _tapAndSettle(tester, find.text(l10n.registerHaveAccount));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text(l10n.signInRemoteNotice), findsNothing);
      await _tapAndSettle(tester, find.text(l10n.signInEraseDevice));
      expect(find.text(l10n.eraseDeviceTitle), findsOneWidget);
      await _tapAndSettle(tester, find.text(l10n.eraseDeviceConfirm));
      expect(wipes, [WipeReason.deviceErased]);
    });

    testWidgets('a fresh install is offered nothing to erase', (tester) async {
      await pumpHeld(tester, null);
      await _tapAndSettle(tester, find.text(l10n.registerHaveAccount));
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.text(l10n.signInEraseDevice), findsNothing);
    });

    testWidgets('registration\'s refusal offers to erase it', (tester) async {
      await pumpHeld(tester, 'someone-else');
      expect(find.text(l10n.signInEraseDevice), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.authEmailLabel),
        'bea@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.authPasswordLabel),
        'correct horse',
      );
      await _tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, l10n.registerSubmit),
      );
      expect(find.text(l10n.authErrorOtherAccount), findsOneWidget);
      await _tapAndSettle(tester, find.text(l10n.signInEraseDevice));
      await _tapAndSettle(tester, find.text(l10n.eraseDeviceConfirm));
      expect(wipes, [WipeReason.deviceErased]);
    });
  });

  testWidgets('removing this device when the server has already removed it '
      'signs out here', (tester) async {
    await pumpDevices(tester);
    _server(tester).failNext('deleteDevice', 404, code: 'not_found');
    await _tapAndSettle(
      tester,
      find.byTooltip(l10n.devicesActions('Demo device')),
    );
    await _tapAndSettle(tester, find.text(l10n.devicesRemove));
    await _tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.devicesRemove),
      ),
    );
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text(l10n.devicesRemoveFailed('Demo device')), findsNothing);
    expect(find.text(l10n.signInRemoteNotice), findsNothing);
  });

  test(
    'a refresh that answers after the screen has gone sets nothing',
    () async {
      final FakeServer server = newFakeServer()
        ..seedUser(email: 'ada@example.com', password: 'correct horse');
      final ProviderContainer container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.prod()),
          clockProvider.overrideWithValue(testClock),
          fakeServerProvider.overrideWithValue(server),
          tokenStoreProvider.overrideWithValue(
            InMemoryTokenStore(
              session: server.seedSession(
                email: 'ada@example.com',
                password: 'correct horse',
              ),
            ),
          ),
          fakeFinanceApiOverride,
        ],
      );
      final ProviderSubscription<AsyncValue<List<Device>>> screen = container
          .listen(devicesControllerProvider, (_, _) {});
      await container.read(devicesControllerProvider.future);
      final DevicesController controller = container.read(
        devicesControllerProvider.notifier,
      );
      server.latency = const Duration(milliseconds: 50);
      final Future<void> refreshing = controller.refresh();
      screen.close();
      await container.pump();
      await expectLater(refreshing, completes);
    },
  );
}
