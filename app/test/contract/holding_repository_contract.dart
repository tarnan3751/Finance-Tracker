// The contract every HoldingRepository implementation passes: the in-memory, demo and
// Drift ones, each from its own test file under test/features/investments/data/.
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A holding of [securityId] on [accountId], every field set, in [currency].
Holding testHolding(
  String accountId,
  String securityId, {
  String quantity = '10.5',
  String currency = 'USD',
  Money? costBasis,
  DataSource source = DataSource.plaid,
}) => Holding(
  accountId: accountId,
  securityId: securityId,
  quantity: Decimal.parse(quantity),
  institutionPrice: Decimal.parse('42.1234'),
  institutionPriceAsOf: LocalDate(2026, 10, 23),
  institutionValue: Money(44230, currency),
  costBasis: costBasis ?? Money(40000, currency),
  source: source,
);

/// A security [id] named [name], every field set.
Security testSecurity(
  String id, {
  String? name,
  DataSource source = DataSource.plaid,
}) => Security(
  id: id,
  name: name,
  tickerSymbol: id.toUpperCase(),
  type: 'etf',
  isCashEquivalent: false,
  closePrice: Decimal.parse('42.1200'),
  closePriceAsOf: LocalDate(2026, 10, 23),
  currencyCode: 'USD',
  source: source,
);

/// Registers the contract tests for the fixtures [create] builds.
void runHoldingRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('HoldingRepository contract', () {
    late HoldingRepository holdings;

    setUp(() async => holdings = (await create()).holdings);
    if (dispose != null) tearDown(dispose);

    test('a fresh repository has none', () async {
      expect(await holdings.watchAll().first, isEmpty);
      expect(await holdings.watchByAccount('ira').first, isEmpty);
    });

    test('every field round-trips, the decimals with their scales', () async {
      final Holding bare = Holding(
        accountId: 'ira',
        securityId: 'cash',
        quantity: Decimal.parse('0'),
        institutionPrice: Decimal.parse('1'),
        institutionValue: Money(0, 'USD'),
        source: DataSource.demo,
      );
      const Security unnamed = Security(
        id: 'cash',
        currencyCode: 'USD',
        source: DataSource.demo,
      );
      await holdings.applyPlaid(
        [testHolding('ira', 'vti'), bare],
        [testSecurity('vti', name: 'Total Stock'), unnamed],
      );
      final List<HoldingView> stored = await holdings.watchAll().first;
      expect(stored, [
        (holding: bare, security: unnamed),
        (
          holding: testHolding('ira', 'vti'),
          security: testSecurity('vti', name: 'Total Stock'),
        ),
      ]);
      expect(stored.last.holding.institutionPrice.toString(), '42.1234');
      expect(stored.last.security!.closePrice.toString(), '42.1200');
    });

    test('orders by account, then security name ignoring case, then id; a '
        'holding of an unlisted security has none', () async {
      await holdings.applyPlaid(
        [
          testHolding('b', 'zeta'),
          testHolding('a', 'vxus'),
          testHolding('a', 'bnd'),
          testHolding('a', 'missing'),
          testHolding('a', 'vti'),
        ],
        [
          testSecurity('vxus', name: 'beta international'),
          testSecurity('bnd', name: 'Bond'),
          testSecurity('vti', name: 'Alpha'),
          testSecurity('zeta'),
        ],
      );
      final List<HoldingView> all = await holdings.watchAll().first;
      expect(
        [for (final HoldingView v in all) v.holding.securityId],
        ['vti', 'vxus', 'bnd', 'missing', 'zeta'],
      );
      expect(all[3].security, isNull);
      expect(
        [
          for (final HoldingView v in await holdings.watchByAccount('a').first)
            v.holding.securityId,
        ],
        ['vti', 'vxus', 'bnd', 'missing'],
      );
    });

    test('a pull replaces every holding and security', () async {
      await holdings.applyPlaid(
        [testHolding('ira', 'vti'), testHolding('old', 'bnd')],
        [testSecurity('vti'), testSecurity('bnd')],
      );
      await holdings.applyPlaid(
        [testHolding('ira', 'vti', quantity: '11')],
        [testSecurity('vti', name: 'Renamed')],
      );
      final List<HoldingView> all = await holdings.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.holding.quantity, Decimal.parse('11'));
      expect(all.single.security!.name, 'Renamed');
      await holdings.applyPlaid(const [], const []);
      expect(await holdings.watchAll().first, isEmpty);
    });

    test(
      'watchers see a pull and nothing more when it changes nothing',
      () async {
        final List<List<HoldingView>> seen = [];
        final sub = holdings.watchByAccount('ira').listen(seen.add);
        addTearDown(sub.cancel);
        await pumpEventQueue();
        await holdings.applyPlaid(
          [testHolding('ira', 'vti')],
          [testSecurity('vti')],
        );
        await pumpEventQueue();
        await holdings.applyPlaid(
          [testHolding('ira', 'vti')],
          [testSecurity('vti')],
        );
        await pumpEventQueue();
        expect(seen, hasLength(2));
        expect(seen.last.single.holding.securityId, 'vti');
      },
    );

    test('a batch that breaks the rules writes nothing', () async {
      await holdings.applyPlaid(
        [testHolding('ira', 'vti')],
        [testSecurity('vti')],
      );
      final List<HoldingView> before = await holdings.watchAll().first;
      for (final (List<Holding>, List<Security>) bad in [
        ([testHolding('ira', 'x', source: DataSource.manual)], const []),
        ([testHolding('ira', 'x', source: DataSource.derived)], const []),
        (const [], [testSecurity('x', source: DataSource.import)]),
        ([testHolding('ira', 'x'), testHolding('ira', 'x')], const []),
        (const [], [testSecurity('x'), testSecurity('x')]),
      ]) {
        await expectLater(
          holdings.applyPlaid(bad.$1, bad.$2),
          throwsArgumentError,
        );
      }
      await expectLater(
        holdings.applyPlaid([
          testHolding('ira', 'x', costBasis: Money(100, 'EUR')),
        ], const []),
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(await holdings.watchAll().first, before);
    });
  });
}
