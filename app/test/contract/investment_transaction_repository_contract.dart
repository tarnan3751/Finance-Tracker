// The contract every InvestmentTransactionRepository implementation passes: the
// in-memory, demo and Drift ones, each from its own test file under
// test/features/investments/data/.
import 'package:finance_tracker/features/investments/domain/investment_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A buy [id] on [accountId] dated [date], every field set.
InvestmentTransaction testInvestmentTransaction(
  String id, {
  String accountId = 'ira',
  LocalDate? date,
  int amount = -27000,
  Money? fees,
  DateTime? deletedAt,
  int syncVersion = 1,
  DataSource source = DataSource.plaid,
}) => InvestmentTransaction(
  id: id,
  accountId: accountId,
  securityId: 'vti',
  date: date ?? LocalDate(2026, 10, 7),
  name: 'BUY VTI',
  type: 'buy',
  subtype: 'buy',
  quantity: Decimal.parse('0.9643'),
  price: Decimal.parse('280.00'),
  amount: Money(amount, 'USD'),
  fees: fees ?? Money(0, 'USD'),
  deletedAt: deletedAt,
  syncVersion: syncVersion,
  source: source,
);

/// Registers the contract tests for the fixtures [create] builds.
void runInvestmentTransactionRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('InvestmentTransactionRepository contract', () {
    late InvestmentTransactionRepository investments;

    setUp(() async => investments = (await create()).investmentTransactions);
    if (dispose != null) tearDown(dispose);

    test('a fresh repository has none', () async {
      expect(await investments.watchByAccount('ira').first, isEmpty);
    });

    test('every field round-trips', () async {
      final InvestmentTransaction cash = InvestmentTransaction(
        id: 'c1',
        accountId: 'ira',
        date: LocalDate(2026, 10, 6),
        name: 'PAYROLL CONTRIBUTION',
        type: 'cash',
        quantity: Decimal.parse('0'),
        price: Decimal.parse('0'),
        amount: Money(45000, 'USD'),
        syncVersion: 4,
        source: DataSource.demo,
      );
      await investments.applyPage([testInvestmentTransaction('b1'), cash]);
      expect(await investments.watchByAccount('ira').first, [
        testInvestmentTransaction('b1'),
        cash,
      ]);
    });

    test('lists one account\'s live rows, newest date first, then id '
        'descending', () async {
      await investments.applyPage([
        testInvestmentTransaction('a', date: LocalDate(2026, 9, 7)),
        testInvestmentTransaction('b', date: LocalDate(2026, 10, 7)),
        testInvestmentTransaction('c', date: LocalDate(2026, 10, 7)),
        testInvestmentTransaction('other', accountId: 'brokerage'),
      ]);
      expect(
        [
          for (final InvestmentTransaction t
              in await investments.watchByAccount('ira').first)
            t.id,
        ],
        ['c', 'b', 'a'],
      );
    });

    test('a page replaces rows by id; a tombstone leaves the list and a live '
        'row brings it back', () async {
      await investments.applyPage([
        testInvestmentTransaction('a'),
        testInvestmentTransaction('b'),
      ]);
      await investments.applyPage([
        testInvestmentTransaction('a', amount: -1, syncVersion: 3),
        testInvestmentTransaction(
          'b',
          deletedAt: DateTime.utc(2026, 10, 24, 9, 30),
          syncVersion: 4,
        ),
      ]);
      List<InvestmentTransaction> live = await investments
          .watchByAccount('ira')
          .first;
      expect(live, [
        testInvestmentTransaction('a', amount: -1, syncVersion: 3),
      ]);
      await investments.applyPage([
        testInvestmentTransaction('b', syncVersion: 5),
      ]);
      live = await investments.watchByAccount('ira').first;
      expect([for (final InvestmentTransaction t in live) t.id], ['b', 'a']);
    });

    test('watchers see each page that changes their account', () async {
      final List<List<InvestmentTransaction>> seen = [];
      final sub = investments.watchByAccount('ira').listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await investments.applyPage([testInvestmentTransaction('a')]);
      await pumpEventQueue();
      await investments.applyPage([
        testInvestmentTransaction('x', accountId: 'brokerage'),
      ]);
      await pumpEventQueue();
      expect(seen, hasLength(2));
      expect(seen.last.single.id, 'a');
    });

    test('a page that breaks the rules writes nothing', () async {
      await investments.applyPage([testInvestmentTransaction('a')]);
      for (final List<InvestmentTransaction> bad in [
        [testInvestmentTransaction('x', source: DataSource.manual)],
        [testInvestmentTransaction('x', source: DataSource.derived)],
        [testInvestmentTransaction('x'), testInvestmentTransaction('x')],
      ]) {
        await expectLater(investments.applyPage(bad), throwsArgumentError);
      }
      await expectLater(
        investments.applyPage([
          testInvestmentTransaction('x', fees: Money(1, 'EUR')),
        ]),
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(await investments.watchByAccount('ira').first, [
        testInvestmentTransaction('a'),
      ]);
    });
  });
}
