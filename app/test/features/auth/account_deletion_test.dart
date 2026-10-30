// Deleting the account and erasing this device from Settings: the tiles (not in demo),
// the typed confirmation, a 204 handing over to the local wipe, a 502, a lost
// connection and any other failure each saying why with nothing local changed and the
// button left to try again, and the erase's confirmation with its pending count, from
// the outbox itself when signed out after a restart.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/features/auth/application/account_actions.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/auth/presentation/delete_account_screen.dart';
import 'package:finance_tracker/features/auth/presentation/erase_device_dialog.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

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

Finder get _submit =>
    find.widgetWithText(FilledButton, l10n.deleteAccountSubmit);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

bool _enabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_submit).onPressed != null;

void main() {
  late List<WipeReason> wipes;

  setUp(() => wipes = []);

  Future<void> pumpDelete(WidgetTester tester) => pumpApp(
    tester,
    initialLocation: const DeleteAccountRoute().location,
    overrides: [
      wipeLocalDataProvider.overrideWithValue(
        (reason) async => wipes.add(reason),
      ),
    ],
  );

  test('the typed email confirms trimmed and in any case', () {
    expect(confirmsEmail(' Demo@FinanceTracker.test ', demoEmail), isTrue);
    expect(confirmsEmail('demo@financetracker.tes', demoEmail), isFalse);
    expect(confirmsEmail('', demoEmail), isFalse);
  });

  testWidgets('Settings has the account tiles outside demo only', (
    tester,
  ) async {
    await pumpApp(tester, initialLocation: '/settings');
    expect(find.text(l10n.settingsEraseDevice), findsOneWidget);
    expect(find.text(l10n.settingsDeleteAccount), findsOneWidget);
    await _tapAndSettle(tester, find.text(l10n.settingsDeleteAccount));
    expect(find.byType(DeleteAccountScreen), findsOneWidget);

    await pumpApp(
      tester,
      config: AppConfig.demo(),
      initialLocation: '/settings',
    );
    expect(find.text(l10n.settingsEraseDevice), findsNothing);
    expect(find.text(l10n.settingsDeleteAccount), findsNothing);
  });

  testWidgets('the button waits for the account\'s email', (tester) async {
    await pumpDelete(tester);
    expect(find.text(l10n.deleteAccountConfirmHelper(demoEmail)), findsOne);
    expect(_enabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), 'someone@example.com');
    await tester.pump();
    expect(_enabled(tester), isFalse);
    await tester.enterText(find.byType(TextField), ' DEMO@financetracker.test');
    await tester.pump();
    expect(_enabled(tester), isTrue);
  });

  testWidgets('a 204 hands over to the wipe', (tester) async {
    await pumpDelete(tester);
    await _type(tester, demoEmail);
    await _tapAndSettle(tester, _submit);
    expect(_server(tester).calls, contains('deleteMe'));
    expect(wipes, [WipeReason.accountDeleted]);
  });

  for (final (String name, void Function(FakeServer) fail, String reason) in [
    (
      'a 502 from Plaid',
      (s) => s.failNext('deleteMe', 502, code: 'plaid_error'),
      l10n.deleteAccountFailedPlaid,
    ),
    (
      'a lost connection',
      (s) => s.failNextNetwork('deleteMe'),
      l10n.deleteAccountFailedNetwork,
    ),
    (
      'a 500',
      (s) => s.failNext('deleteMe', 500),
      l10n.deleteAccountFailedOther,
    ),
  ]) {
    testWidgets('$name leaves everything and says why, then a retry works', (
      tester,
    ) async {
      await pumpDelete(tester);
      final ProviderContainer container = _container(tester);
      final Session? before = await container.read(tokenStoreProvider).read();
      fail(_server(tester));
      await _type(tester, demoEmail);
      await _tapAndSettle(tester, _submit);

      expect(find.text(l10n.deleteAccountFailed(reason)), findsOneWidget);
      expect(wipes, isEmpty);
      expect(container.read(sessionControllerProvider), isA<SignedIn>());
      expect(await container.read(tokenStoreProvider).read(), same(before));
      expect(_enabled(tester), isTrue);

      await _tapAndSettle(tester, _submit);
      expect(find.text(l10n.deleteAccountFailed(reason)), findsNothing);
      expect(wipes, [WipeReason.accountDeleted]);
    });
  }

  testWidgets('erasing asks first, then logs out and wipes', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [
        wipeLocalDataProvider.overrideWithValue(
          (reason) async => wipes.add(reason),
        ),
      ],
    );
    await _tapAndSettle(tester, find.text(l10n.settingsEraseDevice));
    expect(find.text(l10n.eraseDeviceTitle), findsOneWidget);
    await _tapAndSettle(tester, find.text('Cancel'));
    expect(wipes, isEmpty);
    expect(_server(tester).calls, isNot(contains('logout')));

    await _tapAndSettle(tester, find.text(l10n.settingsEraseDevice));
    await _tapAndSettle(tester, find.text(l10n.eraseDeviceConfirm));
    expect(_server(tester).calls, contains('logout'));
    expect(wipes, [WipeReason.deviceErased]);
    // The wipe clears the session with the app stopped; until then nothing moves.
    expect(_container(tester).read(sessionControllerProvider), isA<SignedIn>());
  });

  testWidgets('the erase confirmation counts the changes not yet synced', (
    tester,
  ) async {
    Future<void> show(int? pending) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: EraseDeviceDialog(pending: pending),
        ),
      );
      await tester.pump();
    }

    final Finder texts = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Text),
    );
    await show(3);
    expect(find.text('3 changes not yet synced'), findsOneWidget);
    expect(texts, findsNWidgets(5));
    await show(1);
    expect(find.text('1 change not yet synced'), findsOneWidget);
    for (final int? none in [0, null]) {
      await show(none);
      expect(texts, findsNWidgets(4), reason: 'title, body and two buttons');
      expect(find.text(l10n.eraseDeviceBody), findsOneWidget);
    }
  });

  testWidgets('the delete screen lays out at text scale 2.0', (tester) async {
    await pumpApp(
      tester,
      initialLocation: const DeleteAccountRoute().location,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed out after a restart, the count comes from the outbox', (
    tester,
  ) async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DriftSyncStore store = DriftSyncStore(database, testClock);
    for (final int wall in [1, 2]) {
      await tester.runAsync(
        () => store.append(
          ChangeLogEntry(
            entityType: EntityType.goal,
            entityId: 'g',
            operation: ChangeOperation.update,
            payload: const {'name': 'x'},
            hlc: Hlc(wall, 0, 'a'),
            deviceId: 'a',
            synced: false,
          ),
        ),
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDataSyncsProvider.overrideWithValue(true),
          driftSyncStoreProvider.overrideWithValue(store),
          syncControllerProvider.overrideWith(_SignedOutSync.new),
          wipeLocalDataProvider.overrideWithValue(
            (reason) async => wipes.add(reason),
          ),
          accountActionsProvider.overrideWithValue(
            AccountActions(
              api: _NoApi(),
              wipe: (reason) async => wipes.add(reason),
              logOutOnServer: () async {},
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => confirmAndEraseDevice(context, ref),
              child: const Text('erase'),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('erase'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.text('2 changes not yet synced'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(l10n.eraseDeviceConfirm));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(wipes, [WipeReason.deviceErased]);
  });
}

/// The sync status of a signed-out install: no ledger.
final class _SignedOutSync extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(phase: SyncPhase.signedOut);
}

final class _NoApi extends Fake implements FinanceApi {}
