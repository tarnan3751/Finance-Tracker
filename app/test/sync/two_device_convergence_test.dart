// Two (and three) devices, each the real app wiring over its own Drift database (the
// Drift repositories, the recorder, the device clock, the sync controller), syncing
// through one relay: scripted conflicts, rules among them, and seeded random runs, after
// which every device's entity tables and sync records are the same (sync-app.md,
// **Testing**). The Plaid pull after each session goes to an in-app fake server with no
// bank linked, so it brings nothing and never touches the network; a test that needs a
// bank row applies it as the pull's page does.
import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/drift_plaid_pull_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart'
    show ArrivalProcessor;
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:timezone/timezone.dart' as tz;

import '../contract/repository_fixture.dart';

/// The server the Plaid pull of every device asks: no bank linked.
final FakeServer _bankless = FakeServer(dataset: FakeDataset.empty())
  ..seedUser(email: demoEmail, password: demoPassword);

/// Virtual time shared by every device: each read moves it a millisecond on.
final class World {
  int now = DateTime.utc(2026, 10, 24, 15).millisecondsSinceEpoch;
  int tick() => now++;
}

/// A device's clock: the world's time plus the device's skew.
final class SkewedClock implements Clock {
  SkewedClock(this.world, this.skew);

  final World world;
  final Duration skew;

  @override
  DateTime nowUtc() => DateTime.fromMillisecondsSinceEpoch(
    world.tick() + skew.inMilliseconds,
    isUtc: true,
  );

  @override
  DateTime todayLocalMidnight() => DateTime.utc(2026, 10, 24);

  @override
  LocalDate today() => LocalDate(2026, 10, 24);

  @override
  tz.Location get location => tz.UTC;
}

/// The relay, replaceable to simulate a server whose log was wiped.
final class SwappableRelay implements SyncRelay {
  SwappableRelay(this.inner);

  SyncRelay inner;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) => inner.push(entries);

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) => inner.pull(since: since, limit: limit, deviceId: deviceId);
}

/// One device: the app's dev wiring over an in-memory database.
final class Device {
  Device(this.name, this.relay, this.clock, {String? deviceId})
    : database = AppDatabase(NativeDatabase.memory()) {
    _open(deviceId ?? name);
  }

  final String name;
  final SyncRelay relay;
  final Clock clock;
  final AppDatabase database;
  late ProviderContainer container;

  void _open(String? deviceId) {
    container = ProviderContainer(
      overrides: [
        ...overridesFor(AppConfig.dev()),
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        syncDeviceIdProvider.overrideWithValue(deviceId),
        syncRelayProvider.overrideWithValue(deviceId == null ? null : relay),
        // Sessions run only when a test says so.
        syncDebounceProvider.overrideWithValue(const Duration(days: 1)),
        fakeServerProvider.overrideWithValue(_bankless),
        tokenStoreProvider.overrideWith(
          (ref) => InMemoryTokenStore(
            session: _bankless.seedSession(
              email: demoEmail,
              password: demoPassword,
            ),
          ),
        ),
        appVersionProvider.overrideWith((ref) async => '1.0.0'),
        fakeFinanceApiOverride,
      ],
      retry: (_, _) => null,
    );
  }

  /// Signs in as [deviceId] (or out, with null), keeping the database.
  void reopen(String? deviceId) {
    container.dispose();
    _open(deviceId);
  }

  AccountRepository get accounts => container.read(accountRepositoryProvider);
  TransactionRepository get transactions =>
      container.read(transactionRepositoryProvider);
  CategoryRepository get categories =>
      container.read(categoryRepositoryProvider);
  SettingsRepository get settings => container.read(settingsRepositoryProvider);
  RuleRepository get rules => container.read(ruleRepositoryProvider);
  ArrivalProcessor get arrival => container.read(arrivalProcessorProvider);

  /// Applies [page] as a page of the Plaid pull does: the rows inserted, the overrides
  /// held for them laid over them, the rules run on them as stored.
  Future<void> pullPage(List<Transaction> page) => database.transaction(
    () async => arrival.onArrived(
      await DriftPlaidPullStore(
        database,
        store,
      ).materializeHeld(await transactions.applyPlaid(page)),
    ),
  );
  DriftSyncStore get store => container.read(driftSyncStoreProvider);

  /// Runs a session to the end and returns the status after it.
  Future<SyncStatus> sync() async {
    final SyncController controller = container.read(
      syncControllerProvider.notifier,
    );
    await controller.syncNow();
    // The session the controller started when it was built may still be running.
    while (container.read(syncControllerProvider).phase != SyncPhase.idle) {
      await Future<void>.delayed(Duration.zero);
    }
    await controller.syncNow();
    return container.read(syncControllerProvider);
  }

  Future<void> close() async {
    container.dispose();
    await database.close();
  }

  /// The entity tables, without the audit columns each device stamps for itself on
  /// accounts, categories and rules (they are not in the synced records).
  Future<Map<String, List<Map<String, Object?>>>> dump() async {
    Future<List<Map<String, Object?>>> rows(String sql) async => [
      for (final QueryRow row in await database.customSelect(sql).get())
        row.data,
    ];
    return {
      'accounts': await rows(
        'SELECT id, item_id, type, subtype, name, official_name, mask, currency, '
        'current_balance_minor, available_balance_minor, credit_limit_minor, '
        'balances_as_of, is_hidden, display_order, deleted_at, sync_version '
        'FROM accounts ORDER BY id',
      ),
      'transactions': await rows('SELECT * FROM transactions ORDER BY id'),
      'transaction_tags': await rows(
        'SELECT * FROM transaction_tags ORDER BY transaction_id, position',
      ),
      'transaction_splits': await rows(
        'SELECT * FROM transaction_splits ORDER BY transaction_id, position',
      ),
      'categories': await rows(
        'SELECT id, name, parent_id, is_system, icon, color, plaid_category, '
        'deleted_at, sync_version FROM categories ORDER BY id',
      ),
      'rules': await rows(
        'SELECT id, name, position, conditions, actions, deleted_at '
        'FROM rules ORDER BY id',
      ),
      'app_settings': await rows('SELECT * FROM app_settings ORDER BY key'),
      'held_records': await rows(
        'SELECT * FROM held_records ORDER BY entity_type, entity_id',
      ),
    };
  }

  /// Every sync record, canonical, by key.
  Future<Map<String, String>> records() async {
    final Map<String, String> out = {};
    for (final QueryRow row
        in await database
            .customSelect(
              'SELECT DISTINCT entity_type, entity_id FROM record_clocks '
              'ORDER BY entity_type, entity_id',
            )
            .get()) {
      final EntityType type = enumFromSnakeName(
        EntityType.values,
        row.read<String>('entity_type'),
      );
      final String id = row.read<String>('entity_id');
      out['${type.name}/$id'] = (await store.read(type, id))!.toCanonicalJson();
    }
    return out;
  }
}

/// Syncs every device until a whole round changes nothing, then checks they converged.
Future<void> expectConverged(List<Device> devices) async {
  for (int round = 0; round < 3; round++) {
    for (final Device d in devices) {
      expect((await d.sync()).failure, isNull, reason: '${d.name} failed');
    }
  }
  final Map<String, List<Map<String, Object?>>> first = await devices.first
      .dump();
  final Map<String, String> records = await devices.first.records();
  for (final Device d in devices.skip(1)) {
    expect(await d.dump(), first, reason: '${d.name} tables');
    expect(await d.records(), records, reason: '${d.name} records');
  }
  for (final Device d in devices) {
    expect(await d.store.unsynced(), isEmpty, reason: '${d.name} outbox');
  }
}

Transaction txn(String id, String account, int minor, World world) {
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(
    world.tick(),
    isUtc: true,
  );
  return testTransaction(id, account, minor, createdAt: at);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late World world;
  late SwappableRelay relay;
  late List<Device> devices;

  setUp(() {
    world = World();
    relay = SwappableRelay(InMemorySyncRelay(nowWallMillis: () => world.now));
    devices = [];
  });
  tearDown(() async {
    for (final Device d in devices) {
      await d.close();
    }
  });

  Device device(
    String name, {
    Duration skew = Duration.zero,
    String? deviceId,
  }) {
    final Device d = Device(
      name,
      relay,
      SkewedClock(world, skew),
      deviceId: deviceId,
    );
    devices.add(d);
    return d;
  }

  Future<void> shared(Device a, List<Device> others) async {
    await a.categories.ensureSeeded();
    for (final Device d in others) {
      await d.categories.ensureSeeded();
    }
    await a.accounts.create(
      testAccount('acc'),
      openingBalance: txn('t-open', 'acc', 100000, world),
    );
    for (final String id in ['t1', 't2', 't3']) {
      await a.transactions.upsert(txn(id, 'acc', -1000, world));
    }
    await a.sync();
    for (final Device d in others) {
      await d.sync();
    }
  }

  test('offline edits on both devices merge field by field', () async {
    final Device a = device('dev-a');
    final Device b = device('dev-b');
    await shared(a, [b]);

    final Transaction t1 = (await a.transactions.watchById('t1').first)!;
    await a.transactions.upsert(t1.copyWith(notes: 'from A'));
    final Transaction t1b = (await b.transactions.watchById('t1').first)!;
    await b.transactions.upsert(
      t1b.copyWith(amount: Money(-2500, 'USD'), tags: ['b']),
    );
    await expectConverged([a, b]);

    final Transaction merged = (await b.transactions.watchById('t1').first)!;
    expect(merged.notes, 'from A');
    expect(merged.amount, Money(-2500, 'USD'));
    expect(merged.tags, ['b']);
    expect(
      await b.accounts.watchDerivedBalance('acc').first,
      Money(100000 - 2500 - 2000, 'USD'),
    );
  });

  test(
    'a delete wins over a later concurrent edit; a restore then shows it',
    () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await shared(a, [b]);

      await a.transactions.delete('t2');
      final Transaction t2 = (await b.transactions.watchById('t2').first)!;
      await b.transactions.upsert(
        t2.copyWith(notes: 'edited after the delete'),
      );
      await expectConverged([a, b]);
      expect(await a.transactions.watchById('t2').first, isNull);
      expect(await b.transactions.watchById('t2').first, isNull);

      await a.transactions.restore('t2');
      await expectConverged([a, b]);
      expect(
        (await b.transactions.watchById('t2').first)!.notes,
        'edited after the delete',
      );
    },
  );

  test('delete versus restore resolves by clock', () async {
    final Device a = device('dev-a');
    final Device b = device('dev-b');
    await shared(a, [b]);
    await a.transactions.delete('t3');
    await expectConverged([a, b]);

    // Both restore; B then deletes again, later: the delete stands.
    await a.transactions.restore('t3');
    await b.transactions.restore('t3');
    await b.transactions.delete('t3');
    await expectConverged([a, b]);
    expect(await a.transactions.watchById('t3').first, isNull);

    // B restores and deletes again; A restores, later: the restore stands.
    await b.transactions.restore('t3');
    await b.transactions.delete('t3');
    await a.transactions.restore('t3');
    await expectConverged([a, b]);
    expect(await b.transactions.watchById('t3').first, isNotNull);
  });

  test(
    "an account's cascade against a concurrent edit of one of its transactions",
    () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await shared(a, [b]);

      await a.accounts.delete('acc');
      final Transaction t1 = (await b.transactions.watchById('t1').first)!;
      await b.transactions.upsert(t1.copyWith(notes: 'while it was deleted'));
      await expectConverged([a, b]);
      expect(await b.accounts.watchById('acc').first, isNull);
      expect(await b.transactions.watchById('t1').first, isNull);

      await b.accounts.restore('acc');
      await expectConverged([a, b]);
      expect(
        (await a.transactions.watchById('t1').first)!.notes,
        'while it was deleted',
      );
      expect(
        await a.accounts.watchDerivedBalance('acc').first,
        Money(100000 - 3000, 'USD'),
      );
    },
  );

  test('settings saved on both devices merge field by field', () async {
    final Device a = device('dev-a');
    final Device b = device('dev-b');
    await a.settings.save(
      const Settings(themeMode: AppThemeMode.dark, useDynamicColor: true),
    );
    await b.settings.save(
      const Settings(themeMode: AppThemeMode.system, useDynamicColor: false),
    );
    await expectConverged([a, b]);
    const Settings both = Settings(
      themeMode: AppThemeMode.dark,
      useDynamicColor: false,
    );
    expect(await a.settings.read(), both);
    expect(await b.settings.read(), both);
  });

  test(
    "a system category's icon edited on both: the later edit wins",
    () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await shared(a, [b]);
      Future<Category> food(Device d) async =>
          (await d.categories.watchById('plaid:FOOD_AND_DRINK').first)!;
      await a.categories.upsert((await food(a)).copyWith(icon: 'cake'));
      await b.categories.upsert((await food(b)).copyWith(icon: 'local_pizza'));
      await expectConverged([a, b]);
      expect((await food(a)).icon, 'local_pizza');
    },
  );

  test('clock skew: the greater clock wins, whatever the real order', () async {
    final Device a = device('dev-a', skew: const Duration(minutes: 5));
    final Device b = device('dev-b', skew: const Duration(minutes: -5));
    await shared(a, [b]);
    final Transaction t1 = (await a.transactions.watchById('t1').first)!;
    await a.transactions.upsert(t1.copyWith(notes: 'A, earlier but ahead'));
    await b.transactions.upsert(t1.copyWith(notes: 'B, later but behind'));
    await expectConverged([a, b]);
    expect(
      (await b.transactions.watchById('t1').first)!.notes,
      'A, earlier but ahead',
    );
  });

  test(
    'a relay whose log was wiped: the devices pull again and keep syncing',
    () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await shared(a, [b]);
      relay.inner = InMemorySyncRelay(nowWallMillis: () => world.now);
      final Transaction t1 = (await a.transactions.watchById('t1').first)!;
      await a.transactions.upsert(t1.copyWith(notes: 'after the wipe'));
      await expectConverged([a, b]);
      expect(await b.store.pullCursor(), lessThan(10));
      expect(
        (await b.transactions.watchById('t1').first)!.notes,
        'after the wipe',
      );
    },
  );

  test('changes made before sign-in sync under the server device id', () async {
    final Device a = device('dev-a', deviceId: null)..reopen(null);
    await a.accounts.upsert(testAccount('offline'));
    a.reopen('dev-a');
    final Device b = device('dev-b');
    await expectConverged([a, b]);
    expect(await b.accounts.watchById('offline').first, isNotNull);
    final InMemorySyncRelay inner = relay.inner as InMemorySyncRelay;
    expect(inner.entries.map((e) => e.deviceId).toSet(), {'dev-a'});

    // A new sign-in is a new device id: the next changes move to it.
    a.reopen('dev-a2');
    await a.accounts.upsert(testAccount('offline', name: 'Renamed'));
    await expectConverged([a, b]);
    expect((await b.accounts.watchById('offline').first)!.name, 'Renamed');
  });

  test('an amount moved to another currency against new splits in the old one: '
      'the same row on both devices', () async {
    final Device a = device('dev-a');
    final Device b = device('dev-b');
    await a.accounts.upsert(testAccount('acc'));
    await expectConverged([a, b]);

    final Transaction t1 = txn('t1', 'acc', -1000, world).copyWith(
      splits: [TransactionSplit(categoryId: 'c1', amount: Money(-1000, 'USD'))],
    );
    await b.transactions.upsert(t1);
    await b.sync();
    // A moves the account to EUR (no transactions there yet), then receives t1.
    await a.accounts.upsert(testAccount('acc', currency: 'EUR'));
    await a.sync();
    final Transaction onA = (await a.transactions.watchById('t1').first)!;
    await a.transactions.upsert(
      onA.copyWith(
        amount: Money(-900, 'EUR'),
        splits: [
          TransactionSplit(categoryId: 'c1', amount: Money(-900, 'EUR')),
        ],
      ),
    );
    // B, offline, re-splits t1 in USD, later.
    await b.transactions.upsert(
      t1.copyWith(
        splits: [
          TransactionSplit(categoryId: 'c1', amount: Money(-600, 'USD')),
          TransactionSplit(categoryId: 'c2', amount: Money(-400, 'USD')),
        ],
      ),
    );
    await expectConverged([a, b]);

    for (final Device d in [a, b]) {
      final Transaction row = (await d.transactions.watchById('t1').first)!;
      expect(row.amount, Money(-900, 'EUR'), reason: d.name);
      expect(row.splits, isEmpty, reason: d.name);
      final EntityRecord record = (await d.store.read(
        EntityType.transaction,
        't1',
      ))!;
      expect(record.fields['splits'], hasLength(2), reason: d.name);
    }
  });

  group('rules', () {
    Rule rule(String id, {int position = 0, String name = 'Coffee'}) => Rule(
      id: id,
      name: name,
      position: position,
      conditions: const [
        RuleCondition(kind: RuleConditionKind.merchantContains, text: 'Coffee'),
      ],
      actions: const [
        RuleAction(
          kind: RuleActionKind.setCategory,
          value: 'plaid:FOOD_AND_DRINK_COFFEE',
        ),
      ],
    );

    Future<List<Rule>> live(Device d) => d.rules.watchAll().first;

    Future<void> sharedRules(Device a, Device b) async {
      await a.rules.upsert(rule('r1'));
      await a.rules.upsert(rule('r2', position: 1, name: 'Groceries'));
      await a.rules.upsert(rule('r3', position: 2, name: 'Rides'));
      await expectConverged([a, b]);
    }

    test('concurrent edits of different rules, and of one rule\'s fields, '
        'merge', () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await sharedRules(a, b);

      await a.rules.upsert(rule('r1', name: 'Coffee shops'));
      await b.rules.upsert(rule('r2', position: 1, name: 'Food shopping'));
      await b.rules.upsert(
        rule('r1').copyWith(
          actions: const [RuleAction(kind: RuleActionKind.addTag, value: 'x')],
        ),
      );
      await expectConverged([a, b]);

      final List<Rule> merged = await live(b);
      expect(merged[0].name, 'Coffee shops');
      expect(merged[0].actions.single.kind, RuleActionKind.addTag);
      expect(merged[1].name, 'Food shopping');
    });

    test('a reorder against an edit keeps both', () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await sharedRules(a, b);

      await a.rules.reorder(['r3', 'r1', 'r2']);
      await b.rules.upsert(rule('r2', position: 1, name: 'Food shopping'));
      await expectConverged([a, b]);
      expect(
        [for (final Rule r in await live(b)) r.name],
        ['Rides', 'Coffee', 'Food shopping'],
      );
    });

    test('concurrent reorders converge on one order', () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await sharedRules(a, b);

      await a.rules.reorder(['r3', 'r2', 'r1']);
      await b.rules.reorder(['r2', 'r1', 'r3']);
      await expectConverged([a, b]);
      expect(
        [for (final Rule r in await live(a)) r.id],
        [for (final Rule r in await live(b)) r.id],
      );
    });

    test(
      'a delete wins over a concurrent edit; a restore shows the edit',
      () async {
        final Device a = device('dev-a');
        final Device b = device('dev-b');
        await sharedRules(a, b);

        await a.rules.delete('r2');
        await b.rules.upsert(rule('r2', position: 1, name: 'Edited'));
        await expectConverged([a, b]);
        expect([for (final Rule r in await live(b)) r.id], ['r1', 'r3']);

        await b.rules.restore('r2');
        await expectConverged([a, b]);
        expect((await live(a))[1].name, 'Edited');
      },
    );

    test('two devices ingesting one bank transaction under a synced rule '
        'file it the same way', () async {
      final Device a = device('dev-a');
      final Device b = device('dev-b');
      await shared(a, [b]);
      await a.rules.upsert(
        rule('r-coffee').copyWith(
          actions: const [
            RuleAction(
              kind: RuleActionKind.setCategory,
              value: 'plaid:FOOD_AND_DRINK_COFFEE',
            ),
            RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
          ],
        ),
      );
      await expectConverged([a, b]);

      // A's Plaid pull brings the row in; the rule files and tags it, recorded as
      // overrides.
      // On the shared account: a linked one would be soft-deleted by each device's
      // pull, since the fake server lists no bank.
      final Transaction bank = testTransaction(
        'p1',
        'acc',
        -450,
        name: 'BLUE BOTTLE COFFEE',
      ).copyWith(source: DataSource.plaid, syncVersion: 1);
      await a.pullPage([bank]);
      final Transaction filed = (await a.transactions.watchById('p1').first)!;
      expect(filed.userCategoryId, 'plaid:FOOD_AND_DRINK_COFFEE');
      expect(filed.tags, ['coffee']);

      // The user clears the category on A. B syncs (the overrides wait, held, for the
      // row) and then its own pull brings the row: the overrides land on it, the rule
      // leaves the category the user cleared, and the tag is already there.
      await a.transactions.upsert(filed.copyWith(userCategoryId: null));
      await a.sync();
      await b.sync();
      expect((await b.store.watchLedger().first).held, 1);
      await b.pullPage([bank]);
      await expectConverged([a, b]);
      for (final Device d in [a, b]) {
        final Transaction row = (await d.transactions.watchById('p1').first)!;
        expect(row.userCategoryId, isNull, reason: d.name);
        expect(row.tags, ['coffee'], reason: d.name);
        expect(row.source, DataSource.plaid);
      }

      // Both devices bringing in a new row each file it the same way.
      final Transaction second = bank.copyWith(id: 'p2', syncVersion: 2);
      await a.pullPage([second]);
      await b.pullPage([second]);
      await expectConverged([a, b]);
      for (final Device d in [a, b]) {
        expect(
          (await d.transactions.watchById('p2').first)!.userCategoryId,
          'plaid:FOOD_AND_DRINK_COFFEE',
        );
      }
    });

    test(
      'a seeded random run of rule edits on three devices converges',
      () async {
        for (int seed = 0; seed < 15; seed++) {
          setUpRandom(seed);
          world = World();
          relay = SwappableRelay(
            InMemorySyncRelay(nowWallMillis: () => world.now),
          );
          final Random random = Random(seed);
          final List<Device> run = [
            for (final (int i, int skew) in [(0, 0), (1, 45), (2, -60)])
              device('dev-$i', skew: Duration(seconds: skew)),
          ];
          final List<String> ids = [];
          for (int step = 0; step < 80; step++) {
            final Device d = run[random.nextInt(run.length)];
            String pick() => ids[random.nextInt(ids.length)];
            try {
              switch (random.nextInt(8)) {
                case 0 || 1:
                  final String id = 'r${ids.length}';
                  ids.add(id);
                  await d.rules.upsert(
                    rule(id, position: random.nextInt(5), name: 'n$step'),
                  );
                case 2 when ids.isNotEmpty:
                  final String id = pick();
                  final Rule? r = (await live(d))
                      .where((r) => r.id == id)
                      .firstOrNull;
                  if (r != null) {
                    await d.rules.upsert(r.copyWith(name: 'e$step'));
                  }
                case 3 when ids.isNotEmpty:
                  await d.rules.delete(pick());
                case 4 when ids.isNotEmpty:
                  await d.rules.restore(pick());
                case 5 when ids.isNotEmpty:
                  await d.rules.reorder([...ids]..shuffle(random));
                default:
                  await d.sync();
              }
            } on EntityDeletedException {
              // An edit of a rule this device already knows is deleted.
            }
          }
          await expectConverged(run);
          for (final Device d in run) {
            await d.close();
            devices.remove(d);
          }
        }
      },
      timeout: const Timeout.factor(3),
    );
  });

  test('a seeded random run on three devices converges', () async {
    const int seeds = 25;
    for (int seed = 0; seed < seeds; seed++) {
      setUpRandom(seed);
      world = World();
      relay = SwappableRelay(InMemorySyncRelay(nowWallMillis: () => world.now));
      final Random random = Random(seed);
      final List<Device> run = [
        for (final (int i, int skew) in [(0, 0), (1, 90), (2, -120)])
          device('dev-$i', skew: Duration(seconds: skew)),
      ];
      await run.first.categories.ensureSeeded();
      for (final Device d in run.skip(1)) {
        await d.categories.ensureSeeded();
      }
      final List<String> accountIds = [];
      final List<String> transactionIds = [];
      for (int step = 0; step < 120; step++) {
        final Device d = run[random.nextInt(run.length)];
        String pick(List<String> ids) => ids[random.nextInt(ids.length)];
        try {
          switch (random.nextInt(10)) {
            case 0:
              final String id = 'a${accountIds.length}';
              accountIds.add(id);
              await d.accounts.upsert(testAccount(id));
            case 1 || 2 || 3 when accountIds.isNotEmpty:
              final String id = 't${transactionIds.length}';
              transactionIds.add(id);
              await d.transactions.upsert(
                txn(id, pick(accountIds), -random.nextInt(5000), world),
              );
            case 4 || 5 when transactionIds.isNotEmpty:
              final Transaction? t = await d.transactions
                  .watchById(pick(transactionIds))
                  .first;
              if (t != null) {
                await d.transactions.upsert(
                  t.copyWith(
                    notes: 'n$step',
                    tags: random.nextBool() ? ['x$step'] : t.tags,
                  ),
                );
              }
            case 6 when transactionIds.isNotEmpty:
              await d.transactions.delete(pick(transactionIds));
            case 7 when transactionIds.isNotEmpty:
              await d.transactions.restore(pick(transactionIds));
            case 8 when accountIds.isNotEmpty:
              final String id = pick(accountIds);
              if (random.nextBool()) {
                await d.accounts.delete(id);
              } else {
                await d.accounts.restore(id);
              }
            default:
              await d.sync();
          }
        } on AccountNotFoundException {
          // A transaction on an account this device has not seen, or a deleted one.
        } on EntityDeletedException {
          // An edit of something this device already knows is deleted.
        }
        if (random.nextInt(4) == 0) {
          await run[random.nextInt(run.length)].sync();
        }
      }
      await expectConverged(run);
      for (final Device d in run) {
        await d.close();
        devices.remove(d);
      }
    }
    // Twenty-five runs of sessions that each end with a Plaid pull: past the default
    // 30 s on a loaded machine.
  }, timeout: const Timeout.factor(3));
}

/// Names the seed in a failure.
void setUpRandom(int seed) => printOnFailure('random run seed $seed');
