// The recurring detector on worked examples (docs/reference/recurring.md, **The
// detector**): each cadence, short months, weekend rolls, a missed occurrence, a price
// change, a seasonal bill, merchants and lenders that share a name, the excluded rows,
// the status boundary and the guards against chance runs; then its determinism.
import 'dart:math';

import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart'
    show Biweekly, BusinessDayRule, SemiMonthly;
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
Money usd(int minor) => Money(minor, 'USD');

final CategoryLookup lookup = categoryLookup(systemCategories);
int _serial = 0;

Transaction tx(
  LocalDate date,
  int minor, {
  String name = 'NETFLIX.COM',
  String? merchant,
  String account = 'acc-1',
  String? code,
  String? userCategoryId,
  bool hidden = false,
  bool pending = false,
  String? id,
  String currency = 'USD',
}) {
  final DateTime at = DateTime.utc(date.year, date.month, date.day);
  return Transaction(
    id: id ?? 't${(_serial++).toString().padLeft(5, '0')}',
    accountId: account,
    amount: Money(minor, currency),
    date: date,
    pending: pending,
    name: name,
    merchantName: merchant,
    plaidDetailedCategory: code,
    userCategoryId: userCategoryId,
    hidden: hidden,
    source: DataSource.import,
    createdAt: at,
    updatedAt: at,
    syncVersion: 0,
  );
}

/// [count] monthly rows from [first] on its day (clamped), [minor] each.
List<Transaction> monthly(
  LocalDate first,
  int count,
  int minor, {
  String name = 'NETFLIX.COM',
  String account = 'acc-1',
  String? code,
  Set<int> skip = const {},
}) => [
  for (int i = 0; i < count; i++)
    if (!skip.contains(i))
      tx(_clamped(first, i), minor, name: name, account: account, code: code),
];

LocalDate _clamped(LocalDate first, int months) {
  final LocalDate m = first.firstOfMonth.addMonths(months);
  final int last = LocalDate.daysInMonth(m.year, m.month);
  return LocalDate(m.year, m.month, first.day < last ? first.day : last);
}

List<RecurringStream> detect(List<Transaction> rows, LocalDate today) =>
    detectStreams(
      rows,
      today: today,
      lookup: lookup,
      merchantKey: recurringMerchantKey,
    );

void main() {
  group('cadences', () {
    test('monthly on the 31st across February and the 30-day months', () {
      final List<Transaction> rows = monthly(d(2026, 1, 31), 5, -1549);
      expect(rows.map((t) => t.date.toIso()), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
        '2026-05-31',
      ]);
      final RecurringStream s = detect(rows, d(2026, 6, 10)).single;
      expect(s.cadence, RecurringCadence.monthly);
      expect(s.merchantName, 'Netflix');
      expect(s.averageAmount, usd(-1549));
      expect(s.lastExpected, d(2026, 5, 31));
      expect(s.nextExpected, d(2026, 6, 30));
      expect(s.status, RecurringStatus.active);
      expect(s.source, RecurringSource.detected);
      expect(s.isSubscription, isFalse);
      expect(s.transactionIds, [for (final t in rows) t.id]);
      expect(s.id, matches(RegExp(r'^detected-[0-9a-f]{16}$')));
    });

    test('biweekly payroll rolled back over weekends', () {
      final List<LocalDate> dates = Biweekly(
        d(2026, 1, 3), // a Saturday
        businessDay: BusinessDayRule.rollBack,
      ).occurrences(d(2026, 1, 1), d(2026, 4, 30));
      expect(dates.first, d(2026, 1, 2)); // rolled back to Friday
      final List<Transaction> rows = [
        for (final LocalDate date in dates)
          tx(date, 318000, name: 'LAKESHORE MEDICAL GRP PAYROLL'),
      ];
      final RecurringStream s = detect(rows, d(2026, 5, 1)).single;
      expect(s.cadence, RecurringCadence.biweekly);
      expect(s.averageAmount, usd(318000));
      expect(s.transactionIds, hasLength(dates.length));
      // Every Saturday rolled back: the run is on Fridays, and so is the next date.
      expect(s.nextExpected, d(2026, 5, 8));
    });

    test('semimonthly on the 1st and the 15th', () {
      final List<Transaction> rows = [
        for (final LocalDate date in const SemiMonthly(
          1,
          15,
        ).occurrences(d(2026, 1, 1), d(2026, 4, 20)))
          tx(date, 264000, name: 'BRIGHTPATH SCHOOLS DIR DEP'),
      ];
      final RecurringStream s = detect(rows, d(2026, 4, 20)).single;
      expect(s.cadence, RecurringCadence.semiMonthly);
      expect(s.lastExpected, d(2026, 4, 15));
      expect(s.nextExpected, d(2026, 5, 1));
    });

    test('weekly from four occurrences, not from three', () {
      List<Transaction> rows(int n) => [
        for (int i = 0; i < n; i++)
          tx(d(2026, 3, 2).addDays(7 * i), 9000, name: 'WYZANT TUTOR PAYMENT'),
      ];
      expect(detect(rows(3), d(2026, 3, 20)), isEmpty);
      final RecurringStream s = detect(rows(4), d(2026, 3, 30)).single;
      expect(s.cadence, RecurringCadence.weekly);
      expect(s.nextExpected, d(2026, 3, 30));
    });

    test('quarterly on a fixed amount', () {
      final List<Transaction> rows = [
        for (final LocalDate date in [
          d(2025, 7, 10),
          d(2025, 10, 10),
          d(2026, 1, 12),
          d(2026, 4, 10),
        ])
          tx(date, -45000, name: 'LEMONADE INSURANCE'),
      ];
      final RecurringStream s = detect(rows, d(2026, 5, 1)).single;
      expect(s.cadence, RecurringCadence.quarterly);
      expect(s.nextExpected, d(2026, 7, 10));
    });

    test('annual from two occurrences of a fixed amount', () {
      final List<Transaction> rows = [
        tx(d(2025, 3, 3), -13900, name: 'AMAZON PRIME*2K4'),
        tx(d(2026, 3, 3), -13900, name: 'AMAZON PRIME*7Q1'),
      ];
      final RecurringStream s = detect(rows, d(2026, 10, 24)).single;
      expect(s.cadence, RecurringCadence.annually);
      expect(s.merchantName, 'Amazon Prime');
      expect(s.nextExpected, d(2027, 3, 3));
      expect(s.status, RecurringStatus.active);
    });

    test('annual is refused when the amounts differ by more than 5 %', () {
      final List<Transaction> rows = [
        tx(d(2025, 3, 3), -13900, name: 'AMAZON PRIME'),
        tx(d(2026, 3, 3), -15900, name: 'AMAZON PRIME'),
      ];
      expect(detect(rows, d(2026, 10, 24)), isEmpty);
    });

    test('annual seen twice is refused among a merchant\'s other rows', () {
      final List<Transaction> rows = [
        tx(d(2025, 3, 3), -8000, name: 'SAFEWAY #1234'),
        tx(d(2026, 3, 3), -8000, name: 'SAFEWAY #1234'),
        for (int i = 0; i < 4; i++)
          tx(d(2025, 5, 1).addDays(53 * i), -2000 - 900 * i, name: 'SAFEWAY'),
      ];
      expect(detect(rows, d(2026, 10, 24)), isEmpty);
    });
  });

  group('runs', () {
    test('one missed month is tolerated', () {
      final List<Transaction> rows = monthly(
        d(2026, 1, 7),
        8,
        -1549,
        skip: {3},
      );
      final RecurringStream s = detect(rows, d(2026, 8, 20)).single;
      expect(s.transactionIds, hasLength(7));
    });

    test('a second miss ends the run; the longer run is the stream', () {
      final List<Transaction> rows = monthly(
        d(2025, 1, 7),
        14,
        -1549,
        skip: {2, 5},
      );
      final RecurringStream s = detect(rows, d(2026, 3, 1)).single;
      // Runs: Jan 2025..May (March missed), then May..Feb 2026 (June missed).
      expect(s.lastExpected, d(2026, 2, 7));
      expect(s.transactionIds, hasLength(9));
    });

    test('a run among a merchant\'s many other purchases is not a stream', () {
      final Random random = Random(7);
      final List<Transaction> rows = [
        ...monthly(d(2026, 1, 5), 6, -1500, name: 'STARBUCKS STORE 1'),
        for (int i = 0; i < 40; i++)
          tx(
            d(2026, 1, 1).addDays(random.nextInt(170)),
            -(400 + random.nextInt(1400)),
            name: 'STARBUCKS STORE 1',
          ),
      ];
      expect(detect(rows, d(2026, 6, 20)), isEmpty);
    });
  });

  group('amounts', () {
    test('a price change keeps one stream at the new price', () {
      final List<Transaction> rows = [
        ...monthly(d(2025, 1, 7), 12, -1549),
        ...monthly(d(2026, 1, 7), 6, -1799),
      ];
      final RecurringStream s = detect(rows, d(2026, 7, 1)).single;
      expect(s.transactionIds, hasLength(18));
      expect(s.averageAmount, usd(-1799));
      final StreamBand band = StreamBand.of(rows)!;
      expect(
        band,
        StreamBand(median: usd(-1799), min: usd(-1799), max: usd(-1799)),
      );
    });

    test('a seasonal bill is one stream with the whole range as its band', () {
      const List<int> amounts = [
        -23890, -17171, -15515, -12714, -16422, -20020, //
        -23002, -16597, -13321, -16452, -24235, -25142,
      ];
      final List<Transaction> rows = [
        for (int i = 0; i < amounts.length; i++)
          tx(
            _clamped(d(2025, 1, 10), i),
            amounts[i],
            name: 'PGANDE WEB ONLINE',
            merchant: 'PG&E',
          ),
      ];
      final RecurringStream s = detect(rows, d(2026, 1, 1)).single;
      expect(s.cadence, RecurringCadence.monthly);
      expect(s.averageAmount, usd(-16597));
      expect(
        StreamBand.of(rows),
        StreamBand(median: usd(-16597), min: usd(-25142), max: usd(-12714)),
      );
    });

    test('two amounts at one lender on one account are two streams', () {
      final List<Transaction> rows = [
        ...monthly(d(2026, 1, 15), 6, -48000, name: 'GINGHAM CU AUTO LOAN PMT'),
        ...monthly(d(2026, 1, 22), 6, -31000, name: 'GINGHAM CU AUTO LOAN PMT'),
      ];
      final List<RecurringStream> streams = detect(rows, d(2026, 7, 1));
      expect(streams, hasLength(2));
      expect(streams.map((s) => s.averageAmount).toSet(), {
        usd(-48000),
        usd(-31000),
      });
      expect(streams[0].id, isNot(streams[1].id));
    });

    test('one merchant on two accounts is two streams', () {
      final List<Transaction> rows = [
        ...monthly(d(2026, 1, 7), 5, -1549, account: 'acc-1'),
        ...monthly(d(2026, 1, 7), 5, -1549, account: 'acc-2'),
      ];
      final List<RecurringStream> streams = detect(rows, d(2026, 6, 1));
      expect(streams.map((s) => s.accountId).toSet(), {'acc-1', 'acc-2'});
      expect(streams[0].id, isNot(streams[1].id));
    });
  });

  group('input', () {
    test('hidden, pending and deleted rows are left out', () {
      final List<Transaction> rows = monthly(d(2026, 1, 7), 3, -1549);
      expect(detect(rows, d(2026, 4, 1)), hasLength(1));
      for (final Transaction Function(Transaction) change in [
        (t) => t.copyWith(hidden: true),
        (t) => t.copyWith(pending: true),
        (t) => t.copyWith(deletedAt: DateTime.utc(2026, 4)),
      ]) {
        expect(
          detect([...rows.take(2), change(rows[2])], d(2026, 4, 1)),
          isEmpty,
        );
      }
    });

    test('transfers between own accounts, card payments and interest are '
        'left out; a recategorized row is not', () {
      for (final String code in detectorExcludedCodes) {
        expect(
          detect(
            monthly(d(2026, 1, 5), 6, -25000, name: 'X', code: code),
            d(2026, 7, 1),
          ),
          isEmpty,
          reason: code,
        );
      }
      final List<Transaction> received = monthly(
        d(2026, 1, 5),
        6,
        41000,
        name: 'PAYMENT RECEIVED - THANK YOU',
        code: 'LOAN_PAYMENTS_CAR_PAYMENT',
      );
      expect(detect(received, d(2026, 7, 1)), isEmpty);
      final List<Transaction> rent = [
        for (final Transaction t in monthly(
          d(2026, 1, 5),
          6,
          -25000,
          name: 'ONLINE TRANSFER TO SAVINGS',
          code: 'TRANSFER_OUT_SAVINGS',
        ))
          t.copyWith(userCategoryId: 'plaid:RENT_AND_UTILITIES_RENT'),
      ];
      expect(detect(rent, d(2026, 7, 1)), hasLength(1));
    });
  });

  test('a stream is active through two cadence lengths after its last '
      'occurrence', () {
    final List<Transaction> rows = monthly(d(2026, 1, 7), 4, -1549);
    final LocalDate last = d(2026, 4, 7);
    expect(
      detect(rows, last.addDays(62)).single.status,
      RecurringStatus.active,
    );
    expect(detect(rows, last.addDays(63)).single.status, RecurringStatus.ended);
  });

  group('anchors and ids', () {
    /// The ids [rows] give in date order, for every prefix that is a stream.
    List<String> idsOfPrefixes(List<Transaction> rows, int from) => [
      for (int n = from; n <= rows.length; n++)
        detect(rows.sublist(0, n), rows[n - 1].date).single.id,
    ];

    test('a bill on the last day keeps one id and lands on the month end', () {
      final List<Transaction> rows = monthly(d(2025, 3, 31), 12, -8000);
      expect(rows.map((t) => t.date.day).take(4), [31, 30, 31, 30]);
      expect(idsOfPrefixes(rows, 3).toSet(), hasLength(1));
      for (int n = 3; n <= rows.length; n++) {
        final RecurringStream s = detect(
          rows.sublist(0, n),
          rows[n - 1].date,
        ).single;
        final LocalDate after = rows[n - 1].date.firstOfMonth.addMonths(1);
        expect(s.nextExpected, after.lastOfMonth, reason: '$n rows');
      }
    });

    test('a 28-day February counts as the last day', () {
      final List<Transaction> rows = monthly(d(2025, 12, 31), 5, -8000);
      expect(rows[2].date, d(2026, 2, 28));
      expect(idsOfPrefixes(rows, 3).toSet(), hasLength(1));
      expect(detect(rows, d(2026, 5, 1)).single.nextExpected, d(2026, 5, 31));
    });

    test('a stream on the 28th is anchored to the last day too', () {
      final List<Transaction> rows = monthly(d(2026, 1, 28), 4, -8000);
      final RecurringStream s = detect(rows, d(2026, 5, 1)).single;
      expect(s.cadence, RecurringCadence.monthly);
      expect(s.nextExpected, d(2026, 5, 31));
      expect(
        s.id,
        detect(monthly(d(2026, 1, 31), 4, -8000), d(2026, 5, 1)).single.id,
      );
    });

    test('a salary on the 15th and the last day keeps one id across the '
        'year end', () {
      final List<Transaction> rows = [
        for (final LocalDate date in const SemiMonthly(
          15,
          31,
        ).occurrences(d(2025, 10, 1), d(2026, 4, 30)))
          tx(date, 264000, name: 'BRIGHTPATH SCHOOLS DIR DEP'),
      ];
      expect(idsOfPrefixes(rows, 3).toSet(), hasLength(1));
      final RecurringStream s = detect(rows, d(2026, 4, 30)).single;
      expect(s.cadence, RecurringCadence.semiMonthly);
      expect(s.lastExpected, d(2026, 4, 30));
      expect(s.nextExpected, d(2026, 5, 15));
      expect(
        detect(
          rows.sublist(0, rows.length - 1),
          d(2026, 4, 15),
        ).single.nextExpected,
        d(2026, 4, 30),
      );
    });

    test(
      'two currencies or two directions at one merchant are two streams',
      () {
        final List<Transaction> rows = [
          ...monthly(d(2026, 1, 7), 4, -1549),
          for (int i = 0; i < 4; i++)
            tx(d(2026, 1, 7).addMonths(i), -1549, currency: 'EUR'),
          for (int i = 0; i < 4; i++) tx(d(2026, 1, 7).addMonths(i), 1549),
        ];
        final List<RecurringStream> streams = detect(rows, d(2026, 5, 1));
        expect(streams, hasLength(3));
        expect(streams.map((s) => s.id).toSet(), hasLength(3));
        expect(
          streams.map(
            (s) => (s.averageAmount.currencyCode, s.averageAmount.sign),
          ),
          unorderedEquals([('USD', -1), ('EUR', -1), ('USD', 1)]),
        );
      },
    );
  });

  group('determinism', () {
    final List<Transaction> ledger = [
      ...monthly(d(2025, 1, 7), 12, -1549),
      ...monthly(d(2025, 1, 1), 12, -165000, name: 'OAKWOOD APARTMENTS RENT'),
      ...monthly(d(2025, 1, 15), 12, -48000, name: 'GINGHAM CU AUTO LOAN PMT'),
      ...monthly(d(2025, 1, 22), 12, -31000, name: 'GINGHAM CU AUTO LOAN PMT'),
      for (final LocalDate date in Biweekly(
        d(2025, 1, 3),
        businessDay: BusinessDayRule.rollBack,
      ).occurrences(d(2025, 1, 1), d(2025, 12, 31)))
        tx(date, 318000, name: 'LAKESHORE MEDICAL GRP PAYROLL'),
    ];

    test('the output is identical under any input order', () {
      final List<RecurringStream> expected = detect(ledger, d(2026, 1, 1));
      expect(expected, hasLength(5));
      final Random random = Random(42);
      for (int i = 0; i < 50; i++) {
        final List<Transaction> shuffled = [...ledger]..shuffle(random);
        expect(detect(shuffled, d(2026, 1, 1)), expected);
      }
    });

    test('ids are stable when unrelated rows are added', () {
      final Set<String> ids = {
        for (final s in detect(ledger, d(2026, 1, 1))) s.id,
      };
      final Random random = Random(3);
      final List<Transaction> noise = [
        for (int i = 0; i < 200; i++)
          tx(
            d(2025, 1, 1).addDays(random.nextInt(365)),
            -(300 + random.nextInt(9000)),
            name: [
              'TRADER JOE S #552',
              'SHELL OIL 5741',
              'CHIPOTLE 1123',
            ][i % 3],
          ),
      ];
      expect({
        for (final s in detect([...ledger, ...noise], d(2026, 1, 1))) s.id,
      }, ids);
    });
  });
}
