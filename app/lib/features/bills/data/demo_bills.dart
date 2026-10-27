/// The demo flavor's bills: two per persona, derived from the persona's recurring
/// expectations in its demo seed, so the bills, the in-app alerts and the forecast have
/// something to show (`PLAN.md` §12, the 5c rulings). The housing bill is the largest
/// fixed monthly outflow (rent or a mortgage: a monthly expectation whose amount never
/// varies), its previous occurrence marked paid; the other is the largest subscription.
/// Each is linked to its demo stream (`demo-stream-<key>`), on its account, at its
/// amount (a varying one at the middle of its range), with the default reminder, and its
/// first due date the expectation's first nominal date from two months back, so a
/// monthly bill has history (an annual one may fall due later in the year). The suggestions offer the rest.
/// Data only, deterministic for a seed and a day.
library;

import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:persona_engine/persona_engine.dart'
    show DemoSeed, RecurringExpectation;
import 'package:shared_models/shared_models.dart';

/// The demo bills of [seed] as of [today]: the housing bill first, then the
/// subscription; fewer when the persona has neither.
List<BillReminder> demoBills(DemoSeed seed, LocalDate today) {
  final List<RecurringExpectation> outflows = [
    for (final RecurringExpectation r in seed.household.recurring)
      if (!r.isInflow) r,
  ];
  final RecurringExpectation? housing = _largest([
    for (final RecurringExpectation r in outflows)
      if (r.cadence == RecurringCadence.monthly && r.minAmount == r.maxAmount)
        r,
  ]);
  final RecurringExpectation? subscription = _largest([
    for (final RecurringExpectation r in outflows)
      if (r.isSubscription && r.key != housing?.key) r,
  ]);
  return [
    if (housing != null) _paidLast(_bill(housing, today), today),
    if (subscription != null) _bill(subscription, today),
  ];
}

// The expectation with the largest amount, the first key on a tie.
RecurringExpectation? _largest(List<RecurringExpectation> candidates) {
  RecurringExpectation? best;
  for (final RecurringExpectation r in candidates) {
    if (best == null ||
        r.maxAmount.minorUnits > best.maxAmount.minorUnits ||
        (r.maxAmount.minorUnits == best.maxAmount.minorUnits &&
            r.key.compareTo(best.key) < 0)) {
      best = r;
    }
  }
  return best;
}

BillReminder _bill(RecurringExpectation r, LocalDate today) {
  // The first nominal date (before any weekend adjustment) from two months back.
  LocalDate first = today.addMonths(-2);
  while (!r.schedule.isNominal(first)) {
    first = first.addDays(1);
  }
  final int amount = (r.minAmount.minorUnits + r.maxAmount.minorUnits) ~/ 2;
  return BillReminder(
    id: 'demo-bill-${r.key}',
    name: r.merchantName ?? r.name,
    amount: Money(-amount, r.maxAmount.currencyCode),
    dueDate: first,
    cadence: r.cadence,
    accountId: r.accountId,
    streamId: 'demo-stream-${r.key}',
  );
}

BillReminder _paidLast(BillReminder bill, LocalDate today) =>
    switch (BillSchedule.of(bill).previousBefore(today)) {
      final LocalDate last => bill.markPaid(last),
      null => bill,
    };
