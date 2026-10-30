// The background sync on a device (`docs/reference/background.md`, **Testing**). The
// first test runs the WorkManager task's body, `runBackgroundCycle`, in this isolate on
// the dev flavor's wiring over an encrypted database on the device and the in-app fake
// server holding the family persona: a change made here is pushed (another device of
// the account pulls it), the reminders are planned again, the widgets' snapshot is
// written once (the cycle's own `writeWidgetsNow` step), the run is recorded, and a
// delta cycle stays inside its deadline. The second schedules the periodic sync afresh
// with the real plugin and reads it back from WorkManager;
// `tools/scripts/background_doze_check.sh` runs it with `--no-uninstall` and then runs
// the task under Doze. Run on the harness's emulator with `tools/emulator_tests.sh
// integration`.
import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/background/background_dispatcher.dart';
import 'package:finance_tracker/core/background/background_ports.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/platform/workmanager_background_work.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:finance_tracker/features/widgets/data/fake_widget_writer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

const String _email = 'family@example.com';
const String _password = 'correct horse';

/// The dev wiring's providers this test replaces with fakes.
final List<Object> _replaced = [
  reminderSchedulerProvider,
  backgroundWorkProvider,
  widgetWriterProvider,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    "the task's body syncs a change, plans the reminders and runs the "
    'steps, inside its deadline',
    (tester) async {
      await setUpTimeZones();
      final Directory dir = await getTemporaryDirectory();
      final File file = File(p.join(dir.path, 'background-$databaseFileName'));
      for (final String suffix in const ['', '-wal', '-shm', '-journal']) {
        final File f = File('${file.path}$suffix');
        if (f.existsSync()) f.deleteSync();
      }
      final DateTime start = DateTime.now().toUtc();
      final FakeServer server =
          FakeServer(
              dataset: FakeDataset.fromDemoSeed(
                demoSeedFor(PersonaId.family, LocalDate.fromDateTime(start)),
              ),
              now: () => DateTime.now().toUtc(),
            )
            ..seedUser(email: _email, password: _password, displayName: 'Ada')
            ..seedLinkedItems(_email);
      final Session session = server.seedSession(
        email: _email,
        password: _password,
        deviceName: 'Phone A',
      );
      final InMemoryTokenStore tokens = InMemoryTokenStore(
        session: session,
        installUserId: session.user.id,
      );
      final InMemoryDatabaseKeyStore keys = InMemoryDatabaseKeyStore();
      final FakeReminderScheduler reminders = FakeReminderScheduler();
      addTearDown(reminders.close);
      final FakeWidgetWriter widgets = FakeWidgetWriter();

      // The dev wiring with this test's server, session, database and fakes.
      List<Override> overrides() => [
        for (final Override o in localDataOverridesFor(AppConfig.dev()))
          if (!_replaced.any(
            // ignore: invalid_use_of_visible_for_testing_member
            (r) => identical(o.origin, r),
          ))
            o,
        databaseKeyStoreProvider.overrideWithValue(keys),
        databaseProvider.overrideWith((ref) {
          final AppDatabase database = AppDatabase(
            LazyDatabase(() => openDatabaseExecutor(file, keyStore: keys)),
          );
          ref.onDispose(() => databaseClosing[database] = database.close());
          return database;
        }),
        fakeServerProvider.overrideWithValue(server),
        tokenStoreProvider.overrideWithValue(tokens),
        fakeFinanceApiOverride,
        deviceNameProvider.overrideWith((ref) async => 'Phone A'),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        reminderSchedulerProvider.overrideWithValue(reminders),
        backgroundWorkProvider.overrideWith((ref) => FakeBackgroundWork()),
        widgetWriterProvider.overrideWithValue(widgets),
      ];

      // The app's first start: the full pull of the family's banks, the offer answered.
      final ProviderContainer app = ProviderContainer(overrides: overrides());
      final AppDatabase appDatabase = app.read(databaseProvider);
      await appDatabase.verifyOpen();
      await app.read(categoryRepositoryProvider).ensureSeeded();
      await app
          .read(appMetaStoreProvider)
          .write(AppMetaKeys.restoreOfferAnswered, start.toIso8601String());
      await app.read(sessionControllerProvider.notifier).restored();
      final Stopwatch full = Stopwatch()..start();
      app.read(syncControllerProvider);
      await app.read(syncControllerProvider.notifier).firstSession();
      // ignore: avoid_print
      print('BACKGROUND first full sync took ${full.elapsedMilliseconds} ms');
      expect(app.read(syncControllerProvider).failure, isNull);
      await app
          .read(accountRepositoryProvider)
          .create(
            const Account(
              id: 'background-cash',
              type: AccountType.depository,
              name: 'Cash jar',
              currencyCode: 'USD',
              isHidden: false,
              displayOrder: 99,
            ),
          );
      app.dispose();
      await databaseClosing[appDatabase];

      final Stopwatch cycle = Stopwatch()..start();
      final bool done = await runBackgroundCycle(
        BackgroundEnvironment(
          config: AppConfig.dev(),
          overrides: overrides(),
          databaseFile: () async => file,
          wipePending: () async => false,
          registry: MapPortRegistry(),
        ),
      );
      // ignore: avoid_print
      print('BACKGROUND delta cycle took ${cycle.elapsedMilliseconds} ms');
      expect(done, isTrue);
      expect(cycle.elapsed, lessThan(backgroundCycleDeadline));
      expect(reminders.replaced, isNotEmpty);
      // The cycle's own step, the widgets' snapshot, was written once.
      expect(widgets.writes, hasLength(1));

      // Another device of the account pulls what the cycle pushed.
      final Session other = server.seedSession(
        email: _email,
        password: _password,
        deviceName: 'Phone B',
      );
      final ProviderContainer b = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.dev()),
          fakeServerProvider.overrideWithValue(server),
          tokenStoreProvider.overrideWithValue(
            InMemoryTokenStore(session: other),
          ),
          fakeFinanceApiOverride,
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
      );
      addTearDown(b.dispose);
      final PullPage page = await b
          .read(financeApiProvider)
          .pullChanges(since: 0, limit: 500);
      expect(page.entries.map((e) => e.entityId), contains('background-cash'));

      final ProviderContainer after = ProviderContainer(overrides: overrides());
      final AppDatabase afterDatabase = after.read(databaseProvider);
      final BackgroundRun? run = BackgroundRun.parse(
        await after
            .read(appMetaStoreProvider)
            .read(AppMetaKeys.backgroundLastRun),
      );
      after.dispose();
      await databaseClosing[afterDatabase];
      expect(run?.result, BackgroundResult.synced);
      expect(run?.delegated, isFalse);
    },
  );

  testWidgets('the periodic sync is scheduled with WorkManager and read back', (
    tester,
  ) async {
    final WorkmanagerBackgroundWork work = WorkmanagerBackgroundWork(
      dispatcher: backgroundDispatcher,
      flavor: AppConfig.demo().flavor.name,
      sdkInt: () async => 36,
    );
    // Scheduled afresh, so a run kept from an earlier install is not what is read back.
    await work.cancelAll();
    await work.schedulePeriodicSync(
      every: backgroundSyncEvery,
      constraints: backgroundSyncConstraints,
    );
    expect(await work.periodicState(), BackgroundWorkState.scheduled);
    // ignore: avoid_print
    print('BACKGROUND periodic sync scheduled');
  });
}
