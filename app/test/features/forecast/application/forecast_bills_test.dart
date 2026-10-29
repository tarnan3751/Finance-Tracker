// The bills the forecast counts (forecast_bills.dart), as of 24 October 2026 over 90
// days: occurrences from three days back to the horizon, paid ones left out (a mark or an
// assigned payment), paused bills and bills following a projected stream left out, the
// account and currency rules, the amount as an outflow, a bill with no amount, the name
// fallback, a followed liability's due date, and the payment ids.
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/forecast/application/forecast_bills.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../domain/forecast_fixtures.dart';

List<ForecastBill> counted(
  List<BillReminder> bills, {
  String currency = 'USD',
  Set<String> projected = const {},
  Map<String, LocalDate> liabilityDue = const {},
  BillPayments payments = const {},
  Map<String, String> streamNames = const {},
}) => forecastBills(
  bills,
  today: today,
  horizonDays: 90,
  currencyCode: currency,
  accountIds: const {'checking'},
  projectedStreamIds: projected,
  liabilityDue: liabilityDue,
  payments: payments,
  streamNames: streamNames,
);

BillReminder bill(
  String id, {
  int? cents = -10000,
  String currency = 'USD',
  LocalDate? due,
  RecurringCadence? cadence = RecurringCadence.monthly,
  String? accountId = 'checking',
  String? name = 'Bill name',
  String? streamId,
  bool active = true,
  List<LocalDate> paid = const [],
}) => BillReminder(
  id: id,
  name: name,
  amount: cents == null ? null : Money(cents, currency),
  dueDate: due ?? LocalDate(2026, 9, 21),
  cadence: cadence,
  accountId: accountId,
  streamId: streamId,
  active: active,
  paidOccurrences: paid,
);

void main() {
  test('occurrences from three days back to the horizon', () {
    final ForecastBill b = counted([bill('water')]).single;
    expect(b.dates, [
      LocalDate(2026, 10, 21),
      LocalDate(2026, 11, 21),
      LocalDate(2026, 12, 21),
      LocalDate(2027, 1, 21),
    ]);
    expect(b.amount, usd(-10000));
    expect(b.name, 'Bill name');
  });

  test('paid occurrences are left out, by a mark or a payment', () {
    expect(
      counted(
        [
          bill('water', paid: [LocalDate(2026, 10, 21)]),
        ],
        payments: {
          'water': {LocalDate(2026, 11, 21): 't'},
        },
      ).single.dates,
      [LocalDate(2026, 12, 21), LocalDate(2027, 1, 21)],
    );
  });

  test('paused bills and bills following a projected stream are left out', () {
    expect(
      counted(
        [
          bill('paused', active: false),
          bill('followed', streamId: 'rent'),
          bill('other', streamId: 'muted'),
        ],
        projected: {'rent'},
      ).map((b) => b.id),
      ['other'],
    );
  });

  test('another account, or another currency, is left out', () {
    expect(
      counted([
        bill('card', accountId: 'card'),
        bill('any', accountId: null),
        bill('euro', accountId: null, currency: 'EUR'),
      ]).map((b) => b.id),
      ['any'],
    );
    expect(
      counted([
        bill('any', accountId: null),
        bill('euro', accountId: null, currency: 'EUR'),
        bill('blank', accountId: null, cents: null),
      ], currency: 'EUR').map((b) => b.id),
      ['euro', 'blank'],
    );
  });

  test('an amount entered as positive still counts as an outflow', () {
    expect(counted([bill('typed', cents: 2500)]).single.amount, usd(-2500));
  });

  test('a bill with no amount is listed with none', () {
    expect(counted([bill('blank', cents: null)]).single.amount, isNull);
  });

  test('a bill with no name takes the name of the stream it follows', () {
    expect(
      counted(
        [bill('a', name: '  ', streamId: 'netflix'), bill('b', name: null)],
        streamNames: {'netflix': 'Netflix'},
      ).map((b) => b.name),
      ['Netflix', null],
    );
  });

  test('a one-off counts once, a followed liability on its due date', () {
    expect(
      counted([bill('once', cadence: null, due: LocalDate(2026, 12, 2))])
          .single
          .dates,
      [LocalDate(2026, 12, 2)],
    );
    expect(
      counted(
        [bill('card bill', due: LocalDate(2025, 1, 5))],
        liabilityDue: {'card bill': LocalDate(2026, 11, 9)},
      ).single.dates,
      [LocalDate(2026, 11, 9), LocalDate(2026, 12, 9), LocalDate(2027, 1, 9)],
    );
  });

  test('the payment ids are every assigned transaction', () {
    expect(
      billPaymentIds({
        'a': {LocalDate(2026, 10, 1): 't1', LocalDate(2026, 9, 1): 't2'},
        'b': {LocalDate(2026, 10, 3): 't3'},
      }),
      {'t1', 't2', 't3'},
    );
  });
}
