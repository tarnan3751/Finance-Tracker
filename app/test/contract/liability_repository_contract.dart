// The contract every LiabilityRepository implementation passes: the in-memory, demo and
// Drift ones, each from its own test file under test/features/liabilities/data/.
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A card's liability on [accountId] with every credit field set, in [currency].
Liability testCard(
  String accountId, {
  String currency = 'USD',
  DataSource source = DataSource.plaid,
}) => Liability(
  accountId: accountId,
  kind: LiabilityKind.credit,
  source: source,
  nextPaymentDueDate: LocalDate(2026, 10, 28),
  minimumPaymentAmount: Money(2500, currency),
  lastStatementBalance: Money(38980, currency),
  lastStatementIssueDate: LocalDate(2026, 9, 28),
  lastPaymentAmount: Money(16825, currency),
  lastPaymentDate: LocalDate(2026, 9, 22),
  isOverdue: false,
  aprs: [
    LiabilityApr(
      type: 'purchase_apr',
      percentageBasisPoints: 1250,
      balanceSubjectToApr: Money(41027, currency),
    ),
    const LiabilityApr(type: 'cash_apr', percentageBasisPoints: 2499),
  ],
  payload: {
    'account_id': accountId,
    'source': source.name,
    'aprs': [
      {'apr_percentage': '12.5', 'apr_type': 'purchase_apr'},
    ],
    'minimum_payment_amount': {'minor_units': 2500, 'currency': currency},
  },
);

/// A mortgage on [accountId] with every loan field set.
Liability testMortgage(String accountId) => Liability(
  accountId: accountId,
  kind: LiabilityKind.mortgage,
  source: DataSource.plaid,
  nextPaymentDueDate: LocalDate(2026, 11, 1),
  lastPaymentAmount: Money(310050, 'USD'),
  lastPaymentDate: LocalDate(2026, 10, 1),
  interestRateBasisPoints: 388,
  originationDate: LocalDate(2019, 6, 14),
  originationPrincipal: Money(42500000, 'USD'),
  loanTerm: '30 year',
  nextMonthlyPayment: Money(310050, 'USD'),
  ytdInterestPaid: Money(1205000, 'USD'),
  ytdPrincipalPaid: Money(1895500, 'USD'),
  payload: const {'interest_rate_percentage': '3.875', 'loan_term': '30 year'},
);

/// Registers the contract tests for the fixtures [create] builds.
void runLiabilityRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('LiabilityRepository contract', () {
    late LiabilityRepository liabilities;

    setUp(() async => liabilities = (await create()).liabilities);
    if (dispose != null) tearDown(dispose);

    test('a fresh repository has none', () async {
      expect(await liabilities.watchAll().first, isEmpty);
      expect(await liabilities.watchByAccount('card').first, isEmpty);
    });

    test(
      'every field round-trips, the payload and the APRs included',
      () async {
        final List<Liability> all = [
          testCard('card', currency: 'EUR', source: DataSource.demo),
          testMortgage('home'),
          const Liability(
            accountId: 'loan',
            kind: LiabilityKind.student,
            source: DataSource.plaid,
            payload: {},
          ),
        ];
        await liabilities.applyPlaid(all);
        expect(await liabilities.watchAll().first, all);
        expect(await liabilities.watchByAccount('home').first, [
          testMortgage('home'),
        ]);
      },
    );

    test('ordered by account, then kind', () async {
      await liabilities.applyPlaid([
        testMortgage('b'),
        testCard('b'),
        testMortgage('a'),
        const Liability(
          accountId: 'b',
          kind: LiabilityKind.student,
          source: DataSource.plaid,
          payload: {},
        ),
      ]);
      expect(
        [
          for (final Liability l in await liabilities.watchAll().first)
            '${l.accountId}/${l.kind.name}',
        ],
        ['a/mortgage', 'b/credit', 'b/mortgage', 'b/student'],
      );
      expect(
        [
          for (final Liability l in await liabilities.watchByAccount('b').first)
            l.kind,
        ],
        [LiabilityKind.credit, LiabilityKind.mortgage, LiabilityKind.student],
      );
    });

    test('applyPlaid replaces the whole list', () async {
      await liabilities.applyPlaid([testCard('card'), testMortgage('home')]);
      await liabilities.applyPlaid([testCard('card', currency: 'CAD')]);
      expect(await liabilities.watchAll().first, [
        testCard('card', currency: 'CAD'),
      ]);
      await liabilities.applyPlaid(const []);
      expect(await liabilities.watchAll().first, isEmpty);
    });

    test('a refused list writes nothing', () async {
      await liabilities.applyPlaid([testCard('card')]);
      for (final DataSource wrong in [
        DataSource.manual,
        DataSource.import,
        DataSource.derived,
      ]) {
        await expectLater(
          liabilities.applyPlaid([
            testMortgage('home'),
            testCard('other', source: wrong),
          ]),
          throwsArgumentError,
        );
      }
      await expectLater(
        liabilities.applyPlaid([testCard('card'), testCard('card')]),
        throwsArgumentError,
      );
      await expectLater(
        liabilities.applyPlaid([
          testMortgage('home'),
          testCard('card').copyWith(minimumPaymentAmount: Money(2500, 'EUR')),
        ]),
        throwsA(isA<CurrencyMismatchException>()),
      );
      expect(await liabilities.watchAll().first, [testCard('card')]);
    });
  });
}
