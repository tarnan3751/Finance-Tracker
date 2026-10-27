// Bill status on worked examples: paid by a mark, paid by a matching payment (account,
// band, sign, currency, window, hidden and deleted rows), the nearest-occurrence rule,
// due, the grace days, missed, and autopay never missed.
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
Money usd(int cents) => Money(cents, 'USD');

/// Rent: 1,500.00 on the 1st of each month from checking, from January 2027.
BillReminder rent({
  bool autopay = false,
  String? accountId = 'checking',
  Money? amount,
  List<LocalDate> paid = const [],
  RecurringCadence? cadence = RecurringCadence.monthly,
}) => BillReminder(
  id: 'rent',
  name: 'Rent',
  amount: amount ?? usd(-150000),
  dueDate: d(2027, 1, 1),
  cadence: cadence,
  accountId: accountId,
  autopay: autopay,
  paidOccurrences: paid,
);

Transaction payment(
  String id,
  LocalDate date, {
  int amount = -150000,
  String account = 'checking',
  String currency = 'USD',
  bool hidden = false,
  bool deleted = false,
  bool pending = false,
}) => Transaction(
  id: id,
  accountId: account,
  amount: Money(amount, currency),
  date: date,
  pending: pending,
  name: 'RENT',
  source: DataSource.manual,
  hidden: hidden,
  createdAt: DateTime.utc(2027),
  updatedAt: DateTime.utc(2027),
  deletedAt: deleted ? DateTime.utc(2027, 2) : null,
  syncVersion: 0,
);

void main() {
  group('occurrence by occurrence', () {
    test('a mark pays the occurrence', () {
      final BillStatus s = status(
        rent(paid: [d(2027, 3, 1)]),
        d(2027, 3, 10),
        const [],
      );
      expect(s.lastOccurrence, d(2027, 3, 1));
      expect(s.nextDue, d(2027, 4, 1));
      expect(s.state, BillState.paid);
      expect(s.matchedTransactionId, isNull);
    });

    test('a payment on the account, in the band, in the window pays it', () {
      for (final (LocalDate date, int amount) in [
        (d(2027, 2, 22), -150000), // seven days early
        (d(2027, 3, 4), -150000), // three days late
        (d(2027, 3, 1), -135000), // 10 % under
        (d(2027, 3, 1), -165000), // 10 % over
      ]) {
        final BillStatus s = status(rent(), d(2027, 3, 10), [
          payment('t', date, amount: amount),
        ]);
        expect(s.state, BillState.paid, reason: '$date $amount');
        expect(s.matchedTransactionId, 't');
      }
    });

    test('a pending payment counts', () {
      expect(
        status(rent(), d(2027, 3, 10), [
          payment('t', d(2027, 3, 1), pending: true),
        ]).state,
        BillState.paid,
      );
    });

    test('anything else does not pay it, and the occurrence is missed', () {
      for (final Transaction t in [
        payment('early', d(2027, 2, 21)),
        payment('late', d(2027, 3, 5)),
        payment('under', d(2027, 3, 1), amount: -134999),
        payment('over', d(2027, 3, 1), amount: -165001),
        payment('inflow', d(2027, 3, 1), amount: 150000),
        payment('card', d(2027, 3, 1), account: 'card'),
        payment('eur', d(2027, 3, 1), currency: 'EUR'),
        payment('hidden', d(2027, 3, 1), hidden: true),
        payment('deleted', d(2027, 3, 1), deleted: true),
      ]) {
        final BillStatus s = status(rent(), d(2027, 3, 10), [t]);
        expect(s.state, BillState.missed, reason: t.id);
        expect(s.matchedTransactionId, isNull, reason: t.id);
      }
    });

    test('a bill with no account matches a payment on any account', () {
      expect(
        status(rent(accountId: null), d(2027, 3, 10), [
          payment('t', d(2027, 3, 1), account: 'savings'),
        ]).state,
        BillState.paid,
      );
    });

    test('a stream band replaces the 10 % band', () {
      final AmountBand band = (min: usd(100000), max: usd(200000));
      expect(
        status(rent(), d(2027, 3, 10), [
          payment('t', d(2027, 3, 1), amount: -190000),
        ], band: band).state,
        BillState.paid,
      );
    });

    test('with no amount and no band only a mark pays', () {
      final BillReminder bill = BillReminder(
        id: 'b',
        dueDate: d(2027, 1, 1),
        cadence: RecurringCadence.monthly,
      );
      expect(
        status(bill, d(2027, 3, 10), [payment('t', d(2027, 3, 1))]).state,
        BillState.missed,
      );
    });

    test('a payment pays the nearest occurrence only', () {
      // Weekly on Fridays; one payment on Wednesday 2027-03-10, two days before the
      // 12th and five after the 5th: it pays the 12th, so the 5th stays unpaid.
      final BillReminder gym = BillReminder(
        id: 'gym',
        amount: usd(-2000),
        dueDate: d(2027, 1, 1),
        cadence: RecurringCadence.weekly,
      );
      final List<Transaction> paid = [
        payment('t', d(2027, 3, 10), amount: -2000),
      ];
      expect(
        occurrenceState(
          gym,
          d(2027, 3, 5),
          d(2027, 3, 10),
          paidBy: payments([gym], paid)['gym']?[d(2027, 3, 5)],
        ),
        BillState.missed,
      );
      final BillStatus s = status(gym, d(2027, 3, 10), paid);
      expect(s.nextDue, d(2027, 3, 12));
      expect(s.state, BillState.paid);
      expect(s.matchedTransactionId, 't');
    });
  });

  group('across bills', () {
    BillReminder fifty(String id, int day, {String? accountId}) => BillReminder(
      id: id,
      name: id,
      amount: usd(-5000),
      dueDate: d(2027, 1, day),
      cadence: RecurringCadence.monthly,
      accountId: accountId,
    );

    test('one payment pays one occurrence of one bill', () {
      // Two any-account bills of 50.00 due the 1st and the 2nd; one 50.00 payment on
      // 03-29, three days before the 1st and four before the 2nd: it pays the 1st.
      final BillReminder phone = fifty('phone', 1);
      final BillReminder internet = fifty('internet', 2);
      final List<Transaction> paid = [
        payment('t', d(2027, 3, 29), amount: -5000),
      ];
      final BillPayments found = payments([internet, phone], paid);
      expect(found['phone'], {d(2027, 4, 1): 't'});
      expect(found['internet'] ?? const {}, isEmpty);
      expect(
        billStatus(
          phone,
          d(2027, 3, 30),
          paid: found['phone'] ?? const {},
        ).state,
        BillState.paid,
      );
      expect(
        billStatus(
          internet,
          d(2027, 3, 30),
          paid: found['internet'] ?? const {},
        ).state,
        BillState.due,
      );
      expect(payments([phone, internet], paid), found);
    });

    test(
      'at equal distance a bill on the account wins over an any-account one',
      () {
        final BillReminder any = fifty('a-any', 1);
        final BillReminder mine = fifty('z-mine', 1, accountId: 'checking');
        final List<Transaction> paid = [
          payment('t', d(2027, 3, 30), amount: -5000),
        ];
        final BillPayments found = payments([any, mine], paid);
        expect(found['z-mine'], {d(2027, 4, 1): 't'});
        expect(found['a-any'] ?? const {}, isEmpty);
      },
    );

    test('an inactive bill takes no payment from an active one', () {
      final BillReminder paused = fifty(
        'a-paused',
        1,
        accountId: 'checking',
      ).copyWith(active: false);
      final BillReminder live = fifty('z-live', 1);
      final BillPayments found = payments(
        [paused, live],
        [payment('t', d(2027, 4, 1), amount: -5000)],
      );
      expect(found['z-live'], {d(2027, 4, 1): 't'});
      expect(found['a-paused'] ?? const {}, isEmpty);
    });

    test('the nearest due date wins, whatever the account', () {
      final BillReminder any = fifty('any', 2);
      final BillReminder mine = fifty('mine', 5, accountId: 'checking');
      final List<Transaction> paid = [
        payment('t', d(2027, 4, 2), amount: -5000),
      ];
      final BillPayments found = payments([mine, any], paid);
      expect(found['any'], {d(2027, 4, 2): 't'});
      expect(found['mine'] ?? const {}, isEmpty);
    });

    test('an occurrence takes one payment; the second pays the next one', () {
      final BillReminder gym = BillReminder(
        id: 'gym',
        amount: usd(-2000),
        dueDate: d(2027, 1, 1),
        cadence: RecurringCadence.weekly,
      );
      final BillPayments found = payments(
        [gym],
        [
          payment('a', d(2027, 3, 12), amount: -2000),
          payment('b', d(2027, 3, 13), amount: -2000),
        ],
      );
      expect(found['gym'], {d(2027, 3, 12): 'a', d(2027, 3, 19): 'b'});
    });
  });

  group('the bill', () {
    test('is upcoming before its first occurrence, due seven days ahead', () {
      expect(
        status(rent(), d(2026, 12, 24), const []).state,
        BillState.upcoming,
      );
      expect(status(rent(), d(2026, 12, 25), const []).state, BillState.due);
    });

    test('stays due for three days past, then is missed', () {
      for (final int day in [1, 2, 3, 4]) {
        expect(
          status(rent(), d(2027, 3, day), const []).state,
          BillState.due,
          reason: '$day',
        );
      }
      expect(status(rent(), d(2027, 3, 5), const []).state, BillState.missed);
    });

    test('stays missed until the next occurrence is due', () {
      expect(status(rent(), d(2027, 3, 24), const []).state, BillState.missed);
      expect(status(rent(), d(2027, 3, 25), const []).state, BillState.due);
    });

    test('is paid while its last occurrence is and the next is not due', () {
      final BillReminder bill = rent(paid: [d(2027, 3, 1)]);
      expect(status(bill, d(2027, 3, 24), const []).state, BillState.paid);
      expect(status(bill, d(2027, 3, 25), const []).state, BillState.due);
    });

    test('is paid early when its next occurrence already is', () {
      final BillStatus s = status(rent(), d(2027, 3, 28), [
        payment('t', d(2027, 3, 27)),
      ]);
      expect(s.nextDue, d(2027, 4, 1));
      expect(s.state, BillState.paid);
      expect(s.matchedTransactionId, 't');
    });

    test('an autopay bill is never missed', () {
      expect(
        status(rent(autopay: true), d(2027, 3, 10), const []).state,
        BillState.upcoming,
      );
      expect(
        status(rent(autopay: true), d(2027, 3, 2), const []).state,
        BillState.due,
      );
    });

    test('a one-off is upcoming, due, then missed or paid for good', () {
      final BillReminder once = rent(cadence: null);
      expect(status(once, d(2026, 12, 1), const []).state, BillState.upcoming);
      expect(status(once, d(2026, 12, 28), const []).state, BillState.due);
      final BillStatus missed = status(once, d(2027, 6, 1), const []);
      expect(missed.state, BillState.missed);
      expect(missed.nextDue, isNull);
      // Years later it is still the missed last occurrence, not a dateless upcoming.
      final BillStatus later = status(once, d(2030, 6, 1), const []);
      expect(later.state, BillState.missed);
      expect(later.lastOccurrence, d(2027, 1, 1));
      expect(
        status(once, d(2027, 6, 1), [payment('t', d(2027, 1, 2))]).state,
        BillState.paid,
      );
    });
  });
}

/// The assignment of [transactions] to [bills]' occurrences of the last year and a
/// half and the next months.
BillPayments payments(
  List<BillReminder> bills,
  List<Transaction> transactions, {
  AmountBand? band,
}) => assignPayments(
  [
    for (final BillReminder b in bills)
      (bill: b, schedule: BillSchedule.of(b), band: band),
  ],
  transactions,
  d(2025, 1, 1),
  d(2028, 1, 1),
);

/// [bill]'s status on [today], its payments assigned among [transactions] alone.
BillStatus status(
  BillReminder bill,
  LocalDate today,
  List<Transaction> transactions, {
  AmountBand? band,
}) => billStatus(
  bill,
  today,
  paid: payments([bill], transactions, band: band)[bill.id] ?? const {},
);
