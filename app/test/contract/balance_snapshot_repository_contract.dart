// The contract every BalanceSnapshotRepository implementation passes: the in-memory,
// demo and Drift ones, each from its own test file under test/features/net_worth/data/.
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// Account [accountId]'s snapshot on [date] of [current] cents.
BalanceSnapshot testSnapshot(
  String accountId,
  LocalDate date, {
  int current = 120000,
  Money? available,
  Money? limit,
  DataSource source = DataSource.plaid,
}) => BalanceSnapshot(
  accountId: accountId,
  date: date,
  current: Money(current, 'USD'),
  available: available,
  limit: limit,
  source: source,
);

/// Registers the contract tests for the fixtures [create] builds.
void runBalanceSnapshotRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('BalanceSnapshotRepository contract', () {
    late BalanceSnapshotRepository snapshots;
    final LocalDate day1 = LocalDate(2026, 10, 23);
    final LocalDate day2 = LocalDate(2026, 10, 24);

    setUp(() async => snapshots = (await create()).snapshots);
    if (dispose != null) tearDown(dispose);

    test('a fresh repository has none', () async {
      expect(await snapshots.watchAll().first, isEmpty);
      expect(await snapshots.watchByAccount('a').first, isEmpty);
      expect(await snapshots.latestDate(), isNull);
    });

    test('every field and every source round-trips', () async {
      final List<BalanceSnapshot> day = [
        testSnapshot(
          'card',
          day1,
          current: -41027,
          available: Money(158973, 'USD'),
          limit: Money(200000, 'USD'),
        ),
        for (final DataSource s in DataSource.values)
          testSnapshot('acc-${s.name}', day1, source: s),
      ];
      await snapshots.writeDay(day1, day);
      expect(
        await snapshots.watchAll().first,
        [...day]..sort((a, b) => a.accountId.compareTo(b.accountId)),
      );
    });

    test(
      'orders by date, then account; one account by date; the latest date',
      () async {
        await snapshots.writeDay(day2, [
          testSnapshot('b', day2),
          testSnapshot('a', day2),
        ]);
        await snapshots.writeDay(day1, [testSnapshot('b', day1)]);
        expect(
          [
            for (final BalanceSnapshot s in await snapshots.watchAll().first)
              '${s.date} ${s.accountId}',
          ],
          ['2026-10-23 b', '2026-10-24 a', '2026-10-24 b'],
        );
        expect(
          [
            for (final BalanceSnapshot s
                in await snapshots.watchByAccount('b').first)
              s.date,
          ],
          [day1, day2],
        );
        expect(await snapshots.latestDate(), day2);
      },
    );

    test(
      'a day replaces that day\'s rows and leaves every other day',
      () async {
        await snapshots.writeDay(day1, [
          testSnapshot('a', day1),
          testSnapshot('b', day1),
        ]);
        await snapshots.writeDay(day2, [testSnapshot('a', day2)]);
        await snapshots.writeDay(day2, [testSnapshot('b', day2, current: 5)]);
        final List<BalanceSnapshot> all = await snapshots.watchAll().first;
        expect(all, [
          testSnapshot('a', day1),
          testSnapshot('b', day1),
          testSnapshot('b', day2, current: 5),
        ]);
        await snapshots.writeDay(day2, const []);
        expect(await snapshots.watchAll().first, hasLength(2));
        expect(await snapshots.latestDate(), day1);
      },
    );

    test(
      'watchers see a day that changes and nothing for the same day again',
      () async {
        final List<List<BalanceSnapshot>> seen = [];
        final sub = snapshots.watchByAccount('a').listen(seen.add);
        addTearDown(sub.cancel);
        await pumpEventQueue();
        await snapshots.writeDay(day1, [testSnapshot('a', day1)]);
        await pumpEventQueue();
        await snapshots.writeDay(day1, [testSnapshot('a', day1)]);
        await pumpEventQueue();
        expect(seen, hasLength(2));
      },
    );

    test('a day that breaks the rules writes nothing', () async {
      await snapshots.writeDay(day1, [testSnapshot('a', day1)]);
      await expectLater(
        snapshots.writeDay(day2, [testSnapshot('a', day1)]),
        throwsArgumentError,
      );
      await expectLater(
        snapshots.writeDay(day1, [
          testSnapshot('a', day1),
          testSnapshot('a', day1),
        ]),
        throwsArgumentError,
      );
      await expectLater(
        snapshots.writeDay(day1, [
          testSnapshot('a', day1, available: Money(1, 'EUR')),
        ]),
        throwsA(isA<CurrencyMismatchException>()),
      );
      await expectLater(
        snapshots.writeDay(day1, [
          testSnapshot('a', day1, limit: Money(1, 'EUR')),
        ]),
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(await snapshots.watchAll().first, [testSnapshot('a', day1)]);
    });
  });
}
