// The balance snapshot writer: one row per live account per day, valued as the account
// is shown (an unreported investment account adding its holdings), the source by
// evidence; once per day at launch, today replaced after a pull or a session, earlier
// days never touched, nothing written when the clock moved back; and the runner, inert
// until listened, writing at launch and after every pull and every sync session.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart';
import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/net_worth/data/in_memory_balance_snapshot_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../contract/repository_fixture.dart';
import '../../../helpers/pump_app.dart';

final LocalDate _day1 = LocalDate(2026, 10, 23);
final LocalDate _day2 = LocalDate(2026, 10, 24);

Money _usd(int cents) => Money(cents, 'USD');

Account _account(
  String id, {
  String? itemId,
  AccountType type = AccountType.depository,
  Money? current,
  Money? available,
  Money? limit,
}) => Account(
  id: id,
  itemId: itemId,
  type: type,
  name: id,
  currencyCode: 'USD',
  currentBalance: current,
  availableBalance: available,
  creditLimit: limit,
  isHidden: false,
  displayOrder: 0,
);

Holding _holding(String accountId, int value, {DataSource? source}) => Holding(
  accountId: accountId,
  securityId: 'sec-$value',
  quantity: Decimal.parse('1'),
  institutionPrice: Decimal.parse('1'),
  institutionValue: _usd(value),
  source: source ?? DataSource.plaid,
);

/// A clock in UTC the test moves, whose date can be made to fail.
final class _TestClock implements Clock {
  _TestClock(this.now);

  DateTime now;
  bool failToday = false;

  Clock get _at => FixedClock(now, tz.UTC);

  @override
  DateTime nowUtc() => _at.nowUtc();

  @override
  DateTime todayLocalMidnight() => _at.todayLocalMidnight();

  @override
  LocalDate today() {
    if (failToday) throw StateError('no date');
    return _at.today();
  }

  @override
  tz.Location get location => tz.UTC;
}

/// A sync controller whose sessions the test finishes.
final class _FinishingSync extends SyncController {
  @override
  SyncStatus build() => SyncStatus.signedOut;

  /// A session finished [at].
  void finish(DateTime at) =>
      state = SyncStatus(phase: SyncPhase.idle, lastSyncAt: at);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryStore store;
  late InMemoryHoldingRepository holdings;
  late InMemoryLiabilityRepository liabilities;
  late InMemoryBalanceSnapshotRepository snapshots;
  late InMemoryAppMetaStore meta;

  setUp(() {
    store = InMemoryStore(SteppingClock());
    holdings = InMemoryHoldingRepository();
    liabilities = InMemoryLiabilityRepository();
    snapshots = InMemoryBalanceSnapshotRepository();
    meta = InMemoryAppMetaStore();
  });
  tearDown(() async {
    await store.close();
    await holdings.close();
    await liabilities.close();
    await snapshots.close();
  });

  SnapshotWriter writer({bool demo = false}) => SnapshotWriter(
    accounts: InMemoryAccountRepository(
      store,
      recorder: const NoChangeRecorder(),
    ),
    transactions: InMemoryTransactionRepository(
      store,
      recorder: const NoChangeRecorder(),
    ),
    holdings: holdings,
    liabilities: liabilities,
    snapshots: snapshots,
    meta: meta,
    demo: demo,
  );

  void spend(
    String accountId,
    int cents, {
    DataSource source = DataSource.manual,
  }) => store.upsertTransaction(
    testTransaction(
      't-$accountId-${store.count(TransactionQuery.all)}',
      accountId,
      cents,
    ).copyWith(source: source),
  );

  Future<Map<String, BalanceSnapshot>> day(LocalDate date) async => {
    for (final BalanceSnapshot s in await snapshots.watchAll().first)
      if (s.date == date) s.accountId: s,
  };

  test('values each live account as it is shown, with its source', () async {
    store
      ..upsertAccount(_account('wallet'))
      ..upsertAccount(
        _account(
          'card',
          itemId: 'item',
          type: AccountType.credit,
          current: _usd(-41027),
          available: _usd(158973),
          limit: _usd(200000),
        ),
      )
      ..upsertAccount(
        _account(
          'ira',
          itemId: 'item',
          type: AccountType.investment,
          current: _usd(554763),
        ),
      )
      ..upsertAccount(
        _account('unreported', itemId: 'item', type: AccountType.investment),
      )
      ..upsertAccount(_account('gone'));
    spend('wallet', -1250);
    spend('wallet', 50000);
    spend('unreported', 2500, source: DataSource.plaid);
    await InMemoryAccountRepository(
      store,
      recorder: const NoChangeRecorder(),
    ).delete('gone');
    await holdings.applyPlaid([
      _holding('ira', 554763),
      _holding('unreported', 100000),
      _holding('unreported', 20000),
    ], const []);

    expect(await writer().write(_day2, firstOfDay: true), isTrue);
    final Map<String, BalanceSnapshot> rows = await day(_day2);
    expect(rows.keys, unorderedEquals(['wallet', 'card', 'ira', 'unreported']));
    expect(
      rows['wallet'],
      BalanceSnapshot(
        accountId: 'wallet',
        date: _day2,
        current: _usd(48750),
        source: DataSource.manual,
      ),
    );
    expect(
      rows['card'],
      BalanceSnapshot(
        accountId: 'card',
        date: _day2,
        current: _usd(-41027),
        available: _usd(158973),
        limit: _usd(200000),
        source: DataSource.plaid,
      ),
    );
    // A reported investment balance already includes the holdings.
    expect(rows['ira']!.current, _usd(554763));
    // An unreported one is its cash from transactions plus its holdings' value.
    expect(rows['unreported']!.current, _usd(122500));
    expect(await meta.read(AppMetaKeys.snapshotsWrittenOn), '2026-10-24');
  });

  test('a linked account is demo by the evidence of its rows, or in the demo '
      'flavor', () async {
    store
      ..upsertAccount(_account('checking', itemId: 'item', current: _usd(1)))
      ..upsertAccount(_account('ira', itemId: 'item', current: _usd(2)))
      ..upsertAccount(_account('card', itemId: 'item', current: _usd(3)))
      ..upsertAccount(_account('bank', itemId: 'item', current: _usd(4)))
      ..upsertAccount(_account('cash'));
    spend('checking', -100, source: DataSource.demo);
    spend('bank', -100, source: DataSource.plaid);
    await holdings.applyPlaid([
      _holding('ira', 2, source: DataSource.demo),
    ], const []);
    await liabilities.applyPlaid([
      const Liability(
        accountId: 'card',
        kind: LiabilityKind.credit,
        source: DataSource.demo,
        payload: {},
      ),
    ]);
    await writer().write(_day2, firstOfDay: false);
    expect(
      {
        for (final BalanceSnapshot s in (await day(_day2)).values)
          s.accountId: s.source,
      },
      {
        'checking': DataSource.demo,
        'ira': DataSource.demo,
        'card': DataSource.demo,
        'bank': DataSource.plaid,
        'cash': DataSource.manual,
      },
    );
    await writer(demo: true).write(_day2, firstOfDay: false);
    expect((await day(_day2))['bank']!.source, DataSource.demo);
    expect((await day(_day2))['cash']!.source, DataSource.manual);
  });

  test('once per day at launch; after a pull today is replaced', () async {
    store.upsertAccount(_account('wallet'));
    spend('wallet', 1000);
    expect(await writer().write(_day2, firstOfDay: true), isTrue);
    spend('wallet', 500);
    expect(await writer().write(_day2, firstOfDay: true), isFalse);
    expect((await day(_day2))['wallet']!.current, _usd(1000));
    expect(await writer().write(_day2, firstOfDay: false), isTrue);
    expect((await day(_day2))['wallet']!.current, _usd(1500));
    expect(await snapshots.watchAll().first, hasLength(1));
  });

  test(
    'at launch, today\'s rows gone with their store are written again',
    () async {
      store.upsertAccount(_account('wallet'));
      spend('wallet', 1000);
      await writer().write(_day2, firstOfDay: true);
      // The demo's persona switch: a new snapshot store, the same app_meta.
      await snapshots.close();
      snapshots = InMemoryBalanceSnapshotRepository();
      expect(await writer().write(_day2, firstOfDay: true), isTrue);
      expect((await day(_day2))['wallet']!.current, _usd(1000));
    },
  );

  test('a new day leaves the earlier days as they were', () async {
    store.upsertAccount(_account('wallet'));
    spend('wallet', 1000);
    await writer().write(_day1, firstOfDay: true);
    spend('wallet', 500);
    await writer().write(_day2, firstOfDay: true);
    await writer().write(_day2, firstOfDay: false);
    expect((await day(_day1))['wallet']!.current, _usd(1000));
    expect((await day(_day2))['wallet']!.current, _usd(1500));
  });

  test('a clock moved back writes nothing over the later day', () async {
    store.upsertAccount(_account('wallet'));
    spend('wallet', 1000);
    await writer().write(_day2, firstOfDay: true);
    spend('wallet', 500);
    expect(await writer().write(_day1, firstOfDay: true), isFalse);
    expect(await writer().write(_day1, firstOfDay: false), isFalse);
    final List<BalanceSnapshot> all = await snapshots.watchAll().first;
    expect(all.single.date, _day2);
    expect(all.single.current, _usd(1000));
    expect(await meta.read(AppMetaKeys.snapshotsWrittenOn), '2026-10-24');
  });

  group('the runner', () {
    test('writes nothing until listened to, then today at once', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: testOverrides(config: AppConfig.demo()),
      );
      addTearDown(container.dispose);
      await container
          .read(accountRepositoryProvider)
          .create(_account('wallet'));
      await pumpEventQueue();
      expect(
        await container
            .read(balanceSnapshotRepositoryProvider)
            .watchAll()
            .first,
        isEmpty,
      );
      container.listen(snapshotWriterRunnerProvider, (_, _) {});
      await container.read(snapshotWriterRunnerProvider.notifier).settled();
      expect(container.read(snapshotWriterRunnerProvider), testClock.today());
      final List<BalanceSnapshot> written = await container
          .read(balanceSnapshotRepositoryProvider)
          .watchAll()
          .first;
      expect(written.single.accountId, 'wallet');
      expect(written.single.date, testClock.today());
      expect(written.single.source, DataSource.manual);
    });

    test('replaces today after every whole Plaid pull', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: testOverrides(),
      );
      addTearDown(container.dispose);
      container.listen(snapshotWriterRunnerProvider, (_, _) {});
      await container.read(snapshotWriterRunnerProvider.notifier).settled();
      expect(
        await container
            .read(balanceSnapshotRepositoryProvider)
            .watchAll()
            .first,
        isEmpty,
      );
      await container
          .read(accountRepositoryProvider)
          .create(_account('wallet'));
      await container.read(plaidPullProvider).run();
      await pumpEventQueue();
      await container.read(snapshotWriterRunnerProvider.notifier).settled();
      final List<BalanceSnapshot> written = await container
          .read(balanceSnapshotRepositoryProvider)
          .watchAll()
          .first;
      // The pull brought the fake's linked accounts, demo by their rows' evidence.
      expect(
        {for (final BalanceSnapshot s in written) s.accountId: s.source},
        {
          'sample-card': DataSource.demo,
          'sample-checking': DataSource.demo,
          'sample-savings': DataSource.demo,
          'wallet': DataSource.manual,
        },
      );
    });

    test(
      'replaces today after every sync session, not for the same one again',
      () async {
        final _FinishingSync sync = _FinishingSync();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            ...testOverrides(config: AppConfig.demo()),
            syncControllerProvider.overrideWith(() => sync),
          ],
        );
        addTearDown(container.dispose);
        container.listen(snapshotWriterRunnerProvider, (_, _) {});
        await container.read(snapshotWriterRunnerProvider.notifier).settled();
        Future<List<String>> written() async => [
          for (final BalanceSnapshot s
              in await container
                  .read(balanceSnapshotRepositoryProvider)
                  .watchAll()
                  .first)
            s.accountId,
        ];
        expect(await written(), isEmpty);
        final AccountRepository accounts = container.read(
          accountRepositoryProvider,
        );
        await accounts.create(_account('wallet'));
        container.read(syncControllerProvider);
        sync.finish(DateTime.utc(2026, 10, 24, 15));
        await pumpEventQueue();
        await container.read(snapshotWriterRunnerProvider.notifier).settled();
        expect(await written(), ['wallet']);

        await accounts.create(_account('purse'));
        sync.finish(DateTime.utc(2026, 10, 24, 15));
        await pumpEventQueue();
        await container.read(snapshotWriterRunnerProvider.notifier).settled();
        expect(await written(), ['wallet'], reason: 'the same session again');
        sync.finish(DateTime.utc(2026, 10, 24, 16));
        await pumpEventQueue();
        await container.read(snapshotWriterRunnerProvider.notifier).settled();
        expect(await written(), ['purse', 'wallet']);
      },
    );

    Future<List<BalanceSnapshot>> stored(ProviderContainer container) async {
      await container.read(snapshotWriterRunnerProvider.notifier).settled();
      return container.read(balanceSnapshotRepositoryProvider).watchAll().first;
    }

    test('a write that fails leaves the next one to run', () async {
      final _TestClock clock = _TestClock(DateTime.utc(2026, 10, 24, 15));
      final ProviderContainer container = ProviderContainer(
        overrides: testOverrides(clock: clock),
      );
      addTearDown(container.dispose);
      container.listen(snapshotWriterRunnerProvider, (_, _) {});
      expect(await stored(container), isEmpty);
      await container
          .read(accountRepositoryProvider)
          .create(_account('wallet'));
      clock.failToday = true;
      await container.read(plaidPullProvider).run();
      await pumpEventQueue();
      expect(await stored(container), isEmpty);
      clock.failToday = false;
      await container.read(plaidPullProvider).run();
      await pumpEventQueue();
      expect([
        for (final BalanceSnapshot s in await stored(container)) s.accountId,
      ], contains('wallet'));
    });

    test('a pull that lands after local midnight writes the new day', () async {
      final _TestClock clock = _TestClock(
        DateTime.utc(2026, 10, 24, 23, 59, 59, 900),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: testOverrides(clock: clock),
      );
      addTearDown(container.dispose);
      await container
          .read(accountRepositoryProvider)
          .create(_account('wallet'));
      container.listen(snapshotWriterRunnerProvider, (_, _) {});
      expect((await stored(container)).map((s) => s.date).toSet(), {
        LocalDate(2026, 10, 24),
      });
      // The clock crosses midnight before todayProvider's timer ticks.
      clock.now = DateTime.utc(2026, 10, 25, 0, 0, 1);
      await container.read(plaidPullProvider).run();
      await pumpEventQueue();
      final List<BalanceSnapshot> all = await stored(container);
      expect({
        for (final BalanceSnapshot s in all) '${s.date} ${s.accountId}',
      }, containsAll(['2026-10-24 wallet', '2026-10-25 wallet']));
      expect(
        container.read(snapshotWriterRunnerProvider),
        LocalDate(2026, 10, 25),
      );
    });
  });
}
