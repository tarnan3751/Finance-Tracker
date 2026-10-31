// One background cycle over the dev wiring on a real encrypted file (host SQLite3
// Multiple Ciphers), an in-memory relay and the in-app fake server: what it runs (the
// outbox pushed, the reminders planned, the steps after), what it records, its result
// for WorkManager, and every case where it touches nothing (the demo flavor, an app that
// is busy or ran the sync itself, a pending wipe, signed out, no database, a schema the
// app has not migrated to, a pending restore offer), a session the server ended, and
// the deadline.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/background/background_hooks.dart';
import 'package:finance_tracker/core/background/background_ports.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/connectivity_provider.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:finance_tracker/core/platform/fake_connectivity.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/features/bills/application/reminder_planner.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:finance_tracker/features/widgets/data/fake_widget_writer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../contract/repository_fixture.dart';
import '../../helpers/dev_wiring.dart';

/// A relay that can fail, hang, or end the session as a 401 on refresh would.
final class _Relay implements SyncRelay {
  _Relay(this.inner);

  final InMemorySyncRelay inner;
  Object? fail;
  Completer<void>? hang;
  TokenStore? revoke;
  int pulls = 0;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) async {
    await hang?.future;
    if (revoke case final TokenStore tokens) {
      await tokens.clear();
      throw const TokenRevoked();
    }
    if (fail case final Object failure) throw failure;
    return inner.push(entries);
  }

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) {
    pulls++;
    return inner.pull(since: since, limit: limit, deviceId: deviceId);
  }
}

void main() {
  // The worker's engine has the binding too (`Workmanager.executeTask`).
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(tzdata.initializeTimeZones);

  late Directory directory;
  late File file;
  late InMemoryDatabaseKeyStore keys;
  late _Relay relay;
  late FakeReminderScheduler reminders;
  late MapPortRegistry registry;
  late bool wipePending;
  late List<String> hooks;
  late List<BackgroundCycleHook> extraHooks;
  late InMemoryTokenStore? tokens;
  late FakeWidgetWriter widgets;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('ft-cycle-');
    file = File('${directory.path}/$databaseFileName');
    keys = InMemoryDatabaseKeyStore();
    relay = _Relay(
      InMemorySyncRelay(
        nowWallMillis: () => DateTime.now().millisecondsSinceEpoch,
      ),
    );
    reminders = FakeReminderScheduler();
    registry = MapPortRegistry();
    wipePending = false;
    hooks = [];
    extraHooks = [];
    tokens = null;
    widgets = FakeWidgetWriter();
  });
  tearDown(() async {
    await reminders.close();
    directory.deleteSync(recursive: true);
  });

  List<Override> overrides({
    String? deviceId = 'dev-a',
    File? at,
    bool window = true,
    List<BackgroundCycleHook>? steps,
  }) => [
    for (final Override o in devWiring(window: window))
      // ignore: invalid_use_of_visible_for_testing_member
      if (!identical(o.origin, widgetWriterProvider)) o,
    widgetWriterProvider.overrideWithValue(widgets),
    for (final Override o in fakeApiOverrides(signedIn: true))
      // ignore: invalid_use_of_visible_for_testing_member
      if (tokens == null || !identical(o.origin, tokenStoreProvider)) o,
    if (tokens case final InMemoryTokenStore t)
      tokenStoreProvider.overrideWithValue(t),
    appVersionProvider.overrideWith((ref) async => '1.0.0'),
    databaseKeyStoreProvider.overrideWithValue(keys),
    databaseProvider.overrideWith((ref) {
      final AppDatabase database = AppDatabase(
        LazyDatabase(() => openDatabaseExecutor(at ?? file, keyStore: keys)),
      );
      ref.onDispose(() => databaseClosing[database] = database.close());
      return database;
    }),
    syncDeviceIdProvider.overrideWithValue(deviceId),
    syncRelayProvider.overrideWithValue(deviceId == null ? null : relay),
    connectivityProvider.overrideWith((ref) => FakeConnectivity()),
    backgroundWorkProvider.overrideWith((ref) => FakeBackgroundWork()),
    reminderSchedulerProvider.overrideWithValue(reminders),
    deviceZoneProvider.overrideWithValue(() async => 'America/Chicago'),
    backgroundCycleHooksProvider.overrideWithValue(
      steps ??
          [
            (container) async {
              hooks.add(
                registry.lookup(backgroundPortName) == null ? 'unheld' : 'held',
              );
            },
            ...extraHooks,
          ],
    ),
  ];

  // An install that answered the restore offer, with one change waiting to sync.
  Future<void> install() async {
    final ProviderContainer c = ProviderContainer(overrides: overrides());
    await c.read(databaseProvider).verifyOpen();
    await c
        .read(appMetaStoreProvider)
        .write(AppMetaKeys.restoreOfferAnswered, '2026-10-24T15:00:00.000Z');
    await c.read(accountRepositoryProvider).upsert(testAccount('a1'));
    final AppDatabase database = c.read(databaseProvider);
    c.dispose();
    await databaseClosing[database];
  }

  Future<bool> cycle({
    AppConfig? config,
    Duration deadline = backgroundCycleDeadline,
    String? deviceId = 'dev-a',
  }) => runBackgroundCycle(
    BackgroundEnvironment(
      config: config ?? AppConfig.dev(),
      overrides: overrides(deviceId: deviceId),
      databaseFile: () async => file,
      wipePending: () async => wipePending,
      registry: registry,
      deadline: deadline,
    ),
  );

  Future<BackgroundRun?> lastRun() async {
    final ProviderContainer c = ProviderContainer(overrides: overrides());
    final AppDatabase database = c.read(databaseProvider);
    final String? json = await c
        .read(appMetaStoreProvider)
        .read(AppMetaKeys.backgroundLastRun);
    c.dispose();
    await databaseClosing[database];
    return BackgroundRun.parse(json);
  }

  test('a cycle pushes the outbox, plans the reminders, runs the steps, and '
      'records the run', () async {
    await install();
    expect(await cycle(), isTrue);
    expect(relay.inner.entries, hasLength(1));
    expect(reminders.replaced, hasLength(1));
    expect(hooks, ['held']);
    expect(registry.lookup(backgroundPortName), isNull);
    final BackgroundRun? run = await lastRun();
    expect(run?.result, BackgroundResult.synced);
    expect(run?.delegated, isFalse);
  });

  test('no network is retried, and recorded', () async {
    await install();
    relay.fail = const NetworkError(NetworkErrorKind.connection);
    expect(await cycle(), isFalse);
    expect((await lastRun())?.result, BackgroundResult.offline);
  });

  test('a server failure is not retried by WorkManager', () async {
    await install();
    relay.fail = const ServerError(status: 500);
    expect(await cycle(), isTrue);
    expect((await lastRun())?.result, BackgroundResult.failed);
  });

  test('a session the server ended is recorded for the app to tell', () async {
    await install();
    final InMemoryTokenStore store = tokens = InMemoryTokenStore(
      session: (await ProviderContainer(
        overrides: [...fakeApiOverrides(signedIn: true)],
      ).read(tokenStoreProvider).read()),
    );
    relay.revoke = store;
    expect(await cycle(), isTrue);
    expect((await lastRun())?.result, BackgroundResult.sessionEnded);
    final ProviderContainer c = ProviderContainer(overrides: overrides());
    expect(
      await c
          .read(appMetaStoreProvider)
          .read(AppMetaKeys.sessionEndedInBackground),
      isNotEmpty,
    );
    c.dispose();
  });

  test('the deadline ends a cycle that hangs, recorded as timed out', () async {
    await install();
    relay.hang = Completer<void>();
    final Stopwatch watch = Stopwatch()..start();
    expect(await cycle(deadline: const Duration(milliseconds: 500)), isTrue);
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    expect((await lastRun())?.result, BackgroundResult.timedOut);
    // The lock goes when the cycle has stopped, not when the deadline returned.
    expect(registry.lookup(backgroundPortName), isNotNull);
    relay.hang!.complete();
    for (
      int i = 0;
      i < 100 && registry.lookup(backgroundPortName) != null;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(registry.lookup(backgroundPortName), isNull);
  });

  group('touches nothing', () {
    test('in the demo flavor', () async {
      expect(await cycle(config: AppConfig.demo()), isTrue);
      expect(file.existsSync(), isFalse);
    });

    test('while a wipe is pending', () async {
      await install();
      wipePending = true;
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
      expect(await lastRun(), isNull);
    });

    test('signed out', () async {
      await install();
      tokens = InMemoryTokenStore();
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
    });

    test('with no database, never creating one or a key', () async {
      expect(await cycle(), isTrue);
      expect(file.existsSync(), isFalse);
      expect(keys.key, isNull);
    });

    test('on a schema the app has not migrated to', () async {
      await install();
      final Database raw = sqlite3.open(file.path);
      databaseSetup(hexKey: keys.key, requireEncryption: true)(raw);
      raw.execute('PRAGMA user_version = 12');
      raw.close();
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
      final Database after = sqlite3.open(file.path);
      databaseSetup(hexKey: keys.key, requireEncryption: true)(after);
      expect(after.select('PRAGMA user_version').first.values.first, 12);
      after.close();
    });

    test('while the restore offer is pending, recorded as held', () async {
      // A fresh install: signed in, nothing local, the offer never answered.
      final ProviderContainer c = ProviderContainer(overrides: overrides());
      await c.read(databaseProvider).verifyOpen();
      final AppDatabase database = c.read(databaseProvider);
      c.dispose();
      await databaseClosing[database];
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
      expect((await lastRun())?.result, BackgroundResult.held);
    });

    test('when the app is busy, or ran the sync itself', () async {
      await install();
      bool running = false;
      final AppSyncPort app = AppSyncPort(
        () => running,
        () async => DelegatedResult.retry,
        registry: registry,
      );
      addTearDown(app.close);
      expect(await cycle(), isTrue, reason: 'busy');
      running = true;
      expect(await cycle(), isFalse, reason: "the app's sync went offline");
      expect(relay.inner.entries, isEmpty);
      expect(await lastRun(), isNull);
    });
  });

  // Runs [statements] on the install's file through its own connection.
  void raw(List<String> statements) {
    final Database db = sqlite3.open(file.path);
    databaseSetup(hexKey: keys.key, requireEncryption: true)(db);
    for (final String statement in statements) {
      db.execute(statement);
    }
    db.close();
  }

  group('touches nothing either', () {
    test('without the full-text definition', () async {
      await install();
      raw(["DELETE FROM app_meta WHERE key = '$ftsDefinitionKey'"]);
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
    });

    test('when a full-text object is missing', () async {
      await install();
      raw(['DROP TRIGGER ${ftsTriggers.first}']);
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
      final Database db = sqlite3.open(file.path);
      databaseSetup(hexKey: keys.key, requireEncryption: true)(db);
      expect(
        db.select(
          "SELECT 1 FROM sqlite_master WHERE name = '${ftsTriggers.first}'",
        ),
        isEmpty,
        reason: 'the index is the app to rebuild',
      );
      db.close();
    });

    test('with a database file and no key, never making one', () async {
      await install();
      keys.key = null;
      expect(await cycle(), isTrue);
      expect(relay.inner.entries, isEmpty);
      expect(keys.key, isNull);
      expect(file.existsSync(), isTrue);
    });
  });

  test('two cycles at once: one runs, the other leaves it the lock', () async {
    await install();
    final List<bool> results = await Future.wait([cycle(), cycle()]);
    expect(results, [isTrue, isTrue]);
    expect(relay.pulls, 1);
    expect(registry.lookup(backgroundPortName), isNull);
  });

  test(
    'the deadline closes the database: a transaction it cut leaves nothing',
    () async {
      await install();
      extraHooks.add((container) async {
        await container.read(databaseProvider).transaction(() async {
          await container
              .read(appMetaStoreProvider)
              .write('cut_by_the_deadline', 'yes');
          await Completer<void>().future;
        });
      });
      final Stopwatch watch = Stopwatch()..start();
      expect(await cycle(deadline: const Duration(seconds: 2)), isTrue);
      expect(
        watch.elapsed,
        lessThan(closeTimeout + const Duration(seconds: 5)),
      );
      final ProviderContainer c = ProviderContainer(overrides: overrides());
      final AppDatabase database = c.read(databaseProvider);
      expect(
        await c.read(appMetaStoreProvider).read('cut_by_the_deadline'),
        isNull,
      );
      c.dispose();
      await databaseClosing[database];
    },
  );

  test('a transaction another device added is applied, and the widgets show '
      'it in net worth, with no app running and no window', () async {
    await install();
    // The app's own day: today's snapshot written before it was killed.
    final ProviderContainer app = ProviderContainer(overrides: overrides());
    final LocalDate today = app.read(clockProvider).today();
    expect(
      await app.read(snapshotWriterProvider).write(today, firstOfDay: true),
      isTrue,
    );
    final AppDatabase appDatabase = app.read(databaseProvider);
    app.dispose();
    await databaseClosing[appDatabase];
    expect(await cycle(), isTrue);

    // The other device pulls the account, then adds a transaction on it and pushes.
    final File other = File('${directory.path}/other-$databaseFileName');
    Future<void> otherSession(
      Future<void> Function(ProviderContainer) edit,
    ) async {
      final ProviderContainer b = ProviderContainer(
        overrides: overrides(deviceId: 'dev-b', at: other),
      );
      await b
          .read(appMetaStoreProvider)
          .write(AppMetaKeys.restoreOfferAnswered, '2026-10-24T15:00:00.000Z');
      await edit(b);
      final ProviderSubscription<SyncStatus> s = b.listen(
        syncControllerProvider,
        (_, _) {},
      );
      await b.read(syncControllerProvider.notifier).firstSession();
      s.close();
      final AppDatabase database = b.read(databaseProvider);
      b.dispose();
      await databaseClosing[database];
    }

    await otherSession((_) async {});
    await otherSession(
      (b) => b
          .read(transactionRepositoryProvider)
          .upsert(testTransaction('t1', 'a1', 600, date: today)),
    );

    final List<String> warnings = [];
    final StreamSubscription<LogRecord> logs = Logger.root.onRecord
        .where((r) => r.level >= Level.WARNING)
        .listen((r) => warnings.add('${r.loggerName}: ${r.message}'));
    addTearDown(logs.cancel);
    final ProviderContainer defaults = ProviderContainer();
    final List<BackgroundCycleHook> steps = defaults.read(
      backgroundCycleHooksProvider,
    );
    defaults.dispose();
    expect(
      await runBackgroundCycle(
        BackgroundEnvironment(
          config: AppConfig.dev(),
          overrides: overrides(window: false, steps: steps),
          databaseFile: () async => file,
          wipePending: () async => wipePending,
          registry: registry,
        ),
      ),
      isTrue,
    );
    expect(warnings, isEmpty);

    final ProviderContainer c = ProviderContainer(overrides: overrides());
    final AppDatabase database = c.read(databaseProvider);
    final Transaction? pulled = await c
        .read(transactionRepositoryProvider)
        .watchById('t1')
        .first;
    final Money? derived = (await c
        .read(accountRepositoryProvider)
        .watchDerivedBalances()
        .first)['a1'];
    final List<Account> accounts = await c
        .read(accountRepositoryProvider)
        .watchAll()
        .first;
    final List<BalanceSnapshot> snapshots = await c
        .read(balanceSnapshotRepositoryProvider)
        .watchAll()
        .first;
    c.dispose();
    await databaseClosing[database];
    expect(pulled?.amount, Money(600, 'USD'));
    expect(derived, isNot(Money(0, 'USD')));
    // Today's row follows the pulled transaction, and the widgets' net worth is it.
    expect(
      snapshots
          .singleWhere((s) => s.accountId == 'a1' && s.date == today)
          .current,
      derived,
    );
    expect(widgets.writes, hasLength(1));
    expect(
      widgets.last?.netWorth?.amount,
      observedNetWorth(snapshots, {
        for (final Account a in accounts) a.id: a.type,
      })['USD']!.last.netWorth,
    );
  });
}
