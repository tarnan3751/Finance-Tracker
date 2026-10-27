// Suggestions from streams and liabilities: what is offered, what is left out (linked,
// inactive, income, no date, unknown cadence), the order, and the accepted bill.
import 'package:finance_tracker/features/bills/domain/bill_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);
Money usd(int cents) => Money(cents, 'USD');

SourceStream stream(
  String id, {
  String name = 'Netflix',
  int amount = -1549,
  LocalDate? next,
  bool active = true,
  RecurringCadence cadence = RecurringCadence.monthly,
}) => SourceStream(
  id: id,
  name: name,
  accountId: 'checking',
  cadence: cadence,
  amount: usd(amount),
  nextExpected: next ?? d(2026, 11, 5),
  active: active,
);

void main() {
  test('offers unlinked active expense streams and liabilities by date', () {
    final List<BillSuggestion> found = billSuggestions(
      BillSourceData(
        streams: [
          stream('s1', name: 'Netflix', next: d(2026, 11, 5)),
          stream('s2', name: 'Gym', next: d(2026, 11, 1)),
          stream('linked', name: 'Linked'),
          stream('ended', active: false),
          stream('salary', amount: 250000),
          stream('weird', cadence: RecurringCadence.unknown),
        ],
        liabilities: [
          SourceLiability(
            accountId: 'card',
            name: 'Visa',
            nextPaymentDueDate: d(2026, 11, 3),
            minimumPayment: usd(2500),
          ),
          const SourceLiability(
            accountId: 'loan',
            name: 'Loan',
            nextPaymentDueDate: null,
          ),
          SourceLiability(
            accountId: 'linkedcard',
            name: 'Linked card',
            nextPaymentDueDate: d(2026, 11, 3),
          ),
        ],
      ),
      [
        BillReminder(id: 'b1', dueDate: d(2026, 1, 1), streamId: 'linked'),
        BillReminder(
          id: 'b2',
          dueDate: d(2026, 1, 1),
          liabilityAccountId: 'linkedcard',
        ),
      ],
    );
    expect([for (final s in found) s.name], ['Gym', 'Visa', 'Netflix']);
  });

  test('a stream nextExpected of null is left out', () {
    expect(
      billSuggestions(
        BillSourceData(
          streams: [
            SourceStream(
              id: 's',
              name: 'n',
              accountId: 'a',
              cadence: RecurringCadence.monthly,
              amount: usd(-1),
              nextExpected: null,
              active: true,
            ),
          ],
        ),
        const [],
      ),
      isEmpty,
    );
  });

  test('accepting a stream links it and takes its values', () {
    final BillReminder bill = StreamBillSuggestion(
      stream('s1', next: d(2026, 11, 5)),
    ).accept('new');
    expect(bill.id, 'new');
    expect(bill.name, 'Netflix');
    expect(bill.amount, usd(-1549));
    expect(bill.dueDate, d(2026, 11, 5));
    expect(bill.cadence, RecurringCadence.monthly);
    expect(bill.accountId, 'checking');
    expect(bill.streamId, 's1');
    expect(bill.reminderOffsetDays, [2]);
    expect(bill.reminderMinutes, 540);
  });

  test(
    'accepting a liability follows it monthly at its minimum, as an outflow',
    () {
      final BillReminder bill = LiabilityBillSuggestion(
        SourceLiability(
          accountId: 'card',
          name: 'Visa',
          nextPaymentDueDate: d(2026, 10, 28),
          minimumPayment: usd(2500),
        ),
      ).accept('new');
      expect(bill.liabilityAccountId, 'card');
      expect(bill.accountId, isNull);
      expect(bill.amount, usd(-2500));
      expect(bill.dueDate, d(2026, 10, 28));
      expect(bill.cadence, RecurringCadence.monthly);
    },
  );
}
