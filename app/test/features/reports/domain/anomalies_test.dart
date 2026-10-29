// The anomaly rule on worked examples (docs/reference/reports.md, **Anomalies**): the
// modified z-score on both sides of 3.5, the twice-the-median guard, MAD = 0 with its
// 20 % and 5-unit edges, fewer than six priors with and without the category fallback,
// the twelve-month window, new merchants with and without six months of history, and the
// rows left out (transfers, hidden rows, scheduled payments, a rule's merchant).
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
Money usd(int minor) => Money(minor, 'USD');

final CategoryLookup lookup = categoryLookup(systemCategories);

int _n = 0;
Transaction txn(
  LocalDate date,
  int minor, {
  String merchant = 'Corner Deli',
  String code = 'FOOD_AND_DRINK_RESTAURANT',
  String account = 'a1',
  String currency = 'USD',
  bool hidden = false,
  String? id,
}) => Transaction(
  id: id ?? 't${(_n++).toString().padLeft(4, '0')}',
  accountId: account,
  amount: Money(minor, currency),
  date: date,
  pending: false,
  name: merchant,
  merchantName: merchant,
  plaidDetailedCategory: code,
  hidden: hidden,
  source: DataSource.manual,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  syncVersion: 0,
);

// An account history from January 2025 at another merchant, so "new merchant" can
// apply and the deli's own priors decide.
final List<Transaction> history = [
  txn(d(2025, 1, 2), -100, merchant: 'Gas Stop', code: 'TRANSPORTATION_GAS'),
];

// Six priors at the deli in 2026: 10.00, 11.00, 12.00, 12.00, 13.00, 14.00. The lower
// median is 12.00; the distances 2, 1, 0, 0, 1, 2 (dollars) give a MAD of 1.00.
List<Transaction> deli() => [
  for (final (int day, int minor) in [
    (5, -1000),
    (6, -1100),
    (7, -1200),
    (8, -1200),
    (9, -1300),
    (10, -1400),
  ])
    txn(d(2026, 3, day), minor),
];

List<AnomalyFlag> flags(
  List<Transaction> ts, {
  Set<String> scheduled = const {},
  List<Rule> rules = const [],
}) => detectAnomalies(
  ts,
  window: LocalDateRange(d(2026, 4, 1), d(2026, 5, 1)),
  lookup: lookup,
  scheduledIds: scheduled,
  rules: rules,
  excluded: (t) => t.hidden,
);

void main() {
  group('isUnusualAmount', () {
    test('the z-score of 3.5 is the boundary', () {
      // MAD 1.00, median 12.00: 6745 × d > 35000 × 100 needs d > 518.9 cents, and the
      // guard needs v ≥ 24.00, which binds first.
      expect(isUnusualAmount(usd(2400), usd(1200), usd(100)), isTrue);
      expect(isUnusualAmount(usd(2399), usd(1200), usd(100)), isFalse);
      // With a MAD of 5.00 the score binds: d > 2594.5 cents.
      expect(isUnusualAmount(usd(1200 + 2595), usd(1200), usd(500)), isTrue);
      expect(isUnusualAmount(usd(1200 + 2594), usd(1200), usd(500)), isFalse);
    });

    test('nothing at or below the median', () {
      expect(isUnusualAmount(usd(1200), usd(1200), usd(100)), isFalse);
      expect(isUnusualAmount(usd(100), usd(1200), usd(100)), isFalse);
    });

    test('MAD = 0: more than 20 % above and at least 5 major units', () {
      // Median 30.00: 20 % is 6.00, so 36.01 is the first, and the guard needs 60.00.
      expect(isUnusualAmount(usd(6000), usd(3000), usd(0)), isTrue);
      expect(isUnusualAmount(usd(5999), usd(3000), usd(0)), isFalse);
      // Median 2.00: twice is 4.00, but 5.00 more is needed: 7.00.
      expect(isUnusualAmount(usd(700), usd(200), usd(0)), isTrue);
      expect(isUnusualAmount(usd(699), usd(200), usd(0)), isFalse);
      // In a currency with no minor unit, 5 major units are 5.
      expect(
        isUnusualAmount(Money(10, 'JPY'), Money(4, 'JPY'), Money(0, 'JPY')),
        isTrue,
      );
      expect(
        isUnusualAmount(Money(8, 'JPY'), Money(4, 'JPY'), Money(0, 'JPY')),
        isFalse,
      );
    });
  });

  test('lowerMedian takes the lower middle', () {
    expect(lowerMedian([3, 1, 2]), 2);
    expect(lowerMedian([4, 1, 3, 2]), 2);
    expect(lowerMedian([7]), 7);
  });

  group('unusual amounts', () {
    test(
      'a row far above the merchant\'s history is flagged with its evidence',
      () {
        final Transaction big = txn(d(2026, 4, 2), -6000);
        final List<AnomalyFlag> f = flags([...history, ...deli(), big]);
        expect(f, hasLength(1));
        expect(f.single.kind, AnomalyKind.unusualAmount);
        expect(f.single.transactionId, big.id);
        expect(f.single.basis, AnomalyBasis.merchant);
        expect(f.single.median, usd(1200));
        expect(f.single.mad, usd(100));
      },
    );

    test('an ordinary row is not', () {
      expect(
        flags([...history, ...deli(), txn(d(2026, 4, 2), -1350)]),
        isEmpty,
      );
    });

    test(
      'with fewer than six priors at the merchant, its category decides',
      () {
        final List<Transaction> others = [
          for (int i = 0; i < 6; i++)
            txn(d(2026, 3, 10 + i), -1000 - i * 100, merchant: 'Bistro $i'),
        ];
        final Transaction big = txn(d(2026, 4, 3), -9000, merchant: 'Bistro 0');
        final List<AnomalyFlag> f = flags([...history, ...others, big]);
        expect(f.single.basis, AnomalyBasis.category);
        expect(f.single.median, usd(1200));
      },
    );

    test('with fewer than six priors anywhere, nothing is judged', () {
      final List<Transaction> five = deli().sublist(1);
      expect(
        flags([
          ...history,
          ...five,
          txn(d(2026, 4, 2), -9000, code: 'TRAVEL_FLIGHTS'),
        ]),
        isEmpty,
      );
    });

    test('priors older than twelve months do not count', () {
      final List<Transaction> old = [
        for (final Transaction t in deli())
          t.copyWith(date: t.date.addMonths(-13)),
      ];
      final Transaction big = txn(d(2026, 4, 2), -6000);
      expect(
        flags([...history, ...old, big]).single.kind,
        AnomalyKind.newMerchant,
      );
    });

    test('rows outside the window are priors, never flagged', () {
      expect(
        flags([...history, ...deli(), txn(d(2026, 5, 1), -6000)]),
        isEmpty,
      );
    });
  });

  group('new merchants', () {
    test('a merchant not seen in six months, on an account with six months of history', () {
      final Transaction first = txn(
        d(2026, 4, 20),
        -4500,
        merchant: 'Guitar Center',
      );
      final List<AnomalyFlag> f = flags([...history, first]);
      expect(f.single.kind, AnomalyKind.newMerchant);
      expect(f.single.since, d(2025, 10, 20));
    });

    test('not on an account with less than six months of history', () {
      final Transaction first = txn(
        d(2026, 4, 20),
        -4500,
        merchant: 'Guitar Center',
        account: 'a2',
      );
      expect(
        flags([...history, txn(d(2025, 10, 21), -100, account: 'a2'), first]),
        isEmpty,
      );
      expect(
        flags([...history, txn(d(2025, 10, 20), -100, account: 'a2'), first])
            .single
            .kind,
        AnomalyKind.newMerchant,
      );
    });

    test('not when the merchant was seen in the six months before', () {
      final Transaction again = txn(
        d(2026, 4, 20),
        -4500,
        merchant: 'Guitar Center',
      );
      expect(
        flags([
          ...history,
          txn(d(2025, 10, 20), -100, merchant: 'Guitar Center', account: 'a9'),
          again,
        ]),
        isEmpty,
      );
    });
  });

  group('rows left out', () {
    final Transaction big = txn(d(2026, 4, 2), -6000, id: 'big');

    test('hidden rows are neither flagged nor priors', () {
      expect(
        flags([...history, ...deli(), big.copyWith(hidden: true)]),
        isEmpty,
      );
      final List<Transaction> hiddenPriors = [
        for (final Transaction t in deli()) t.copyWith(hidden: true),
      ];
      // Without priors the big row is judged on nothing; the hidden rows are still
      // rows at the merchant, so it is not new either.
      expect(flags([...history, ...hiddenPriors, big]), isEmpty);
    });

    test('transfers and scheduled payments are skipped', () {
      expect(
        flags([
          ...history,
          txn(
            d(2026, 4, 2),
            -500000,
            code: 'TRANSFER_OUT_SAVINGS',
            merchant: 'Savings',
          ),
          txn(
            d(2026, 4, 3),
            -48935,
            code: 'LOAN_PAYMENTS_CAR_PAYMENT',
            merchant: 'Credit Union',
          ),
          txn(
            d(2026, 4, 5),
            -650000,
            code: 'LOAN_DISBURSEMENTS_STUDENT',
            merchant: 'Student Loan Disbursement',
          ),
          txn(
            d(2026, 4, 4),
            -3000,
            code: 'BANK_FEES_INTEREST_CHARGE',
            merchant: 'Interest',
          ),
        ]),
        isEmpty,
      );
      expect(flags([...history, ...deli(), big], scheduled: {'big'}), isEmpty);
    });

    test('a merchant a rule names is skipped', () {
      const Rule rule = Rule(
        id: 'r1',
        name: 'Deli',
        position: 0,
        conditions: [
          RuleCondition(kind: RuleConditionKind.merchantContains, text: 'deli'),
        ],
        actions: [RuleAction(kind: RuleActionKind.addTag, value: 'lunch')],
      );
      expect(flags([...history, ...deli(), big], rules: [rule]), isEmpty);
    });

    test('inflows are never flagged', () {
      expect(flags([...history, ...deli(), txn(d(2026, 4, 2), 6000)]), isEmpty);
    });
  });

  group('splits', () {
    // Six $40.00 priors at Costco under groceries.
    final List<Transaction> costco = [
      for (int i = 0; i < 6; i++)
        txn(
          d(2026, 3, 5 + i),
          -4000,
          merchant: 'Costco',
          code: 'FOOD_AND_DRINK_GROCERIES',
        ),
    ];
    Transaction thousand({List<TransactionSplit> splits = const []}) => txn(
      d(2026, 4, 2),
      -100000,
      merchant: 'Costco',
      code: 'FOOD_AND_DRINK_GROCERIES',
      id: 'thousand',
    ).copyWith(splits: splits);

    test(
      'a split row is judged split by split, under each split\'s category',
      () {
        // Whole, $1,000.00 against a $40.00 usual stands out.
        expect(
          flags([...history, ...costco, thousand()]).single.amount,
          usd(-100000),
        );
        // Split $960.00 to savings (a transfer, left out) and $40.00 of groceries: the
        // groceries leg is ordinary.
        expect(
          flags([
            ...history,
            ...costco,
            thousand(
              splits: [
                TransactionSplit(
                  categoryId: 'plaid:TRANSFER_OUT_SAVINGS',
                  amount: usd(-96000),
                ),
                TransactionSplit(
                  categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
                  amount: usd(-4000),
                ),
              ],
            ),
          ]),
          isEmpty,
        );
      },
    );

    test('the merchant judges a split row\'s whole outflow, flagged once', () {
      final List<AnomalyFlag> f = flags([
        ...history,
        ...costco,
        thousand(
          splits: [
            TransactionSplit(
              categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
              amount: usd(-50000),
            ),
            TransactionSplit(
              categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
              amount: usd(-50000),
            ),
          ],
        ),
      ]);
      expect(f.single.transactionId, 'thousand');
      expect(f.single.basis, AnomalyBasis.merchant);
      expect(f.single.amount, usd(-100000));
    });

    test('earlier split visits count once each at the merchant', () {
      // Six $40.00 visits, each split $20.00 / $20.00: the usual visit is $40.00, so
      // a $45.00 one is ordinary.
      final List<Transaction> halves = [
        for (int i = 0; i < 6; i++)
          txn(
            d(2026, 3, 5 + i),
            -4000,
            merchant: 'Trader Joes',
            code: 'FOOD_AND_DRINK_GROCERIES',
          ).copyWith(
            splits: [
              for (int j = 0; j < 2; j++)
                TransactionSplit(
                  categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
                  amount: usd(-2000),
                ),
            ],
          ),
      ];
      expect(
        flags([
          ...history,
          ...halves,
          txn(
            d(2026, 4, 2),
            -4500,
            merchant: 'Trader Joes',
            code: 'FOOD_AND_DRINK_GROCERIES',
          ),
        ]),
        isEmpty,
      );
    });

    test(
      'without the merchant\'s history each leg is judged, and unusual wins',
      () {
        // Six $50.00 electronics purchases elsewhere; a first visit to Target split
        // $10.00 of groceries and $590.00 of electronics.
        final List<Transaction> electronics = [
          for (int i = 0; i < 6; i++)
            txn(
              d(2026, 3, 5 + i),
              -5000,
              merchant: 'Shop $i',
              code: 'GENERAL_MERCHANDISE_ELECTRONICS',
            ),
        ];
        final List<AnomalyFlag> f = flags([
          ...history,
          ...electronics,
          txn(
            d(2026, 4, 2),
            -60000,
            merchant: 'Target',
            code: 'GENERAL_MERCHANDISE_SUPERSTORES',
            id: 'target',
          ).copyWith(
            splits: [
              TransactionSplit(
                categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
                amount: usd(-1000),
              ),
              TransactionSplit(
                categoryId: 'plaid:GENERAL_MERCHANDISE_ELECTRONICS',
                amount: usd(-59000),
              ),
            ],
          ),
        ]);
        expect(f.single.transactionId, 'target');
        expect(f.single.kind, AnomalyKind.unusualAmount);
        expect(f.single.basis, AnomalyBasis.category);
        expect(f.single.amount, usd(-59000));
      },
    );
  });

  test('two first visits on one day flag once, the smaller id', () {
    final List<AnomalyFlag> f = flags([
      ...history,
      txn(d(2026, 4, 20), -4500, merchant: 'Guitar Center', id: 'gc-b'),
      txn(d(2026, 4, 20), -2500, merchant: 'Guitar Center', id: 'gc-a'),
    ]);
    expect([for (final x in f) x.transactionId], ['gc-a']);
  });

  test('the flags do not depend on the input order', () {
    final List<Transaction> ts = [
      ...history,
      ...deli(),
      txn(d(2026, 4, 2), -6000),
      txn(d(2026, 4, 20), -4500, merchant: 'Guitar Center'),
    ];
    String ids(List<AnomalyFlag> f) =>
        [for (final x in f) x.transactionId].join();
    expect(ids(flags(ts.reversed.toList())), ids(flags(ts)));
    expect(flags(ts), hasLength(2));
  });
}
