// Two app instances on one device sync through the in-app fake server: each is the dev
// flavor's wiring (encrypted Drift database, recorder, sync controller, the real client)
// signed in as the same user on its own device. Device A is driven through its screens:
// it shows what it wrote, Sync now pushes it, and after device B, run headless, renames
// a transaction and syncs, A's Sync now brings the new name onto A's Transactions tab.
// Run on the harness's emulator with `tools/emulator_tests.sh integration`.
import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';

const String _email = 'ada@example.com';
const String _password = 'correct horse';

/// One app instance: its encrypted database and its container.
final class Instance {
  Instance(this.container, this.database, this.file);

  final ProviderContainer container;
  final AppDatabase database;
  final File file;

  static Future<Instance> open(
    FakeServer server,
    String name,
    Directory dir,
  ) async {
    final File file = File(p.join(dir.path, 'sync-$name.db'));
    if (file.existsSync()) file.deleteSync();
    final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore();
    final AppDatabase database = AppDatabase(
      LazyDatabase(() => openDatabaseExecutor(file, keyStore: keys)),
    );
    final Session session = server.seedSession(
      email: _email,
      password: _password,
      deviceName: 'Phone $name',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [
        // The dev wiring without its API: the instances share this test's fake server,
        // with or without FT_FAKE_SERVER (which would give each its own).
        ...localDataOverridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(database),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(
          InMemoryTokenStore(session: session, installUserId: session.user.id),
        ),
        fakeFinanceApiOverride,
        deviceNameProvider.overrideWith((ref) async => 'Phone $name'),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        // Sessions run when the test says so.
        syncDebounceProvider.overrideWithValue(const Duration(days: 1)),
      ],
    );
    await database.verifyOpen();
    await container.read(categoryRepositoryProvider).ensureSeeded();
    await container.read(sessionControllerProvider.notifier).restored();
    return Instance(container, database, file);
  }

  /// Runs a session to the end, headless.
  Future<SyncStatus> sync() async {
    final SyncController controller = container.read(
      syncControllerProvider.notifier,
    );
    await controller.syncNow();
    while (container.read(syncControllerProvider).phase != SyncPhase.idle) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await controller.syncNow();
    return container.read(syncControllerProvider);
  }

  Future<void> close() async {
    container.dispose();
    await database.close();
    if (file.existsSync()) file.deleteSync();
  }
}

/// Pumps until [finder] shows, or fails after [timeout] (120 s by default: on an emulator
/// loaded by several lanes, a sync and its Plaid pull have taken longer than 30 s).
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 120),
}) async {
  final DateTime end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('$finder did not appear');
}

/// Taps Sync now once it is enabled: a session, and the Plaid pull after it, must have
/// finished. Scrolls to it first, since the Sync section runs below the fold on a phone.
Future<void> tapSyncNow(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Sync now'));
  await pumpUntil(
    tester,
    find.ancestor(
      of: find.text('Sync now'),
      matching: find.byWidgetPredicate(
        (w) => w is ButtonStyleButton && w.onPressed != null,
      ),
    ),
  );
  await tester.tap(find.text('Sync now'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('two instances sync through the fake server', (tester) async {
    await setUpTimeZones();
    final Directory dir = await getTemporaryDirectory();
    final FakeServer server = FakeServer(
      dataset: FakeDataset.empty(),
      now: () => DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ),
    )..seedUser(email: _email, password: _password, displayName: 'Ada');
    final Instance a = await Instance.open(server, 'A', dir);
    final Instance b = await Instance.open(server, 'B', dir);
    addTearDown(() async {
      await a.close();
      await b.close();
    });

    final DateTime now = a.container.read(clockProvider).nowUtc();
    final LocalDate today = a.container.read(clockProvider).today();
    await a.container
        .read(accountRepositoryProvider)
        .create(
          const Account(
            id: 'joint',
            type: AccountType.depository,
            name: 'Joint account',
            currencyCode: 'USD',
            isHidden: false,
            displayOrder: 0,
          ),
          openingBalance: Transaction(
            id: 'groceries',
            accountId: 'joint',
            amount: Money(-4250, 'USD'),
            date: today,
            pending: false,
            name: 'Groceries',
            source: DataSource.manual,
            createdAt: now,
            updatedAt: now,
            syncVersion: 0,
          ),
        );

    // A, through its screens: its account, then Sync now in Settings.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: a.container,
        child: const FinanceTrackerApp(),
      ),
    );
    await pumpUntil(tester, find.text('Joint account'));
    await tester.tap(find.text('Settings'));
    await pumpUntil(tester, find.text('Sync now'));
    await pumpUntil(tester, find.textContaining('Last synced'));
    await tapSyncNow(tester);
    await pumpUntil(tester, find.text('Every change is synced'));

    // B, headless: A's account and transaction arrive; B renames the transaction.
    expect((await b.sync()).failure, isNull);
    expect(
      await b.container
          .read(accountRepositoryProvider)
          .watchById('joint')
          .first,
      isNotNull,
    );
    final Transaction groceries = (await b.container
        .read(transactionRepositoryProvider)
        .watchById('groceries')
        .first)!;
    await b.container
        .read(transactionRepositoryProvider)
        .upsert(
          groceries.copyWith(
            name: 'Groceries and wine',
            updatedAt: b.container.read(clockProvider).nowUtc(),
          ),
        );
    expect((await b.sync()).failure, isNull);

    // A: Sync now brings B's change onto its Transactions tab.
    await tapSyncNow(tester);
    await pumpUntil(tester, find.text('Every change is synced'));
    await tester.tap(find.text('Transactions'));
    await pumpUntil(tester, find.text('Groceries and wine'));
    expect(find.text('Groceries'), findsNothing);
  });
}
