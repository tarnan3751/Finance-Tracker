/// Whether a bill was paid, is due or was missed (`docs/reference/bills.md`, **Status**;
/// `PLAN.md` §12 "Bills"): computed from the bill, its schedule and the transactions,
/// never stored. Pure Dart.
///
/// An occurrence due on `D` is **paid** when the user marked it, or when a payment
/// matches it: a live, non-hidden transaction (pending included) on the bill's account
/// (any account when it has none), an outflow in the bill's currency whose size is within
/// the band (the linked stream's, else 10 % either side of the expected amount), dated
/// [matchDaysBefore] days before `D` to [matchDaysAfter] after. Payments are assigned
/// across every bill at once ([assignPayments]): one transaction pays one occurrence of
/// one bill at most, the nearest. A bill with no expected amount and no band is paid only
/// by a mark. An unpaid occurrence is **due** from
/// [dueWindowDays] days ahead until [graceDays] days past, **missed** once more than
/// [graceDays] days past (never for an autopay bill), and **upcoming** otherwise.
library;

import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:shared_models/shared_models.dart';

/// How many days ahead an unpaid occurrence is due.
const int dueWindowDays = 7;

/// How many days past its date an unpaid occurrence is still due rather than missed.
const int graceDays = 3;

/// How many days before its due date a payment can be.
const int matchDaysBefore = 7;

/// How many days after its due date a payment can be.
const int matchDaysAfter = 3;

/// What an occurrence, or a bill, is now.
enum BillState { paid, due, missed, upcoming }

/// The sizes a payment may have, inclusive, as positive amounts in one currency.
typedef AmountBand = ({Money min, Money max});

/// The band of a bill with no stream band: 10 % either side of [expected]'s size, in
/// minor units (rounded toward the expected amount).
AmountBand expectedBand(Money expected) {
  final int size = expected.minorUnits.abs();
  final int tolerance = size ~/ 10;
  return (
    min: Money(size - tolerance, expected.currencyCode),
    max: Money(size + tolerance, expected.currencyCode),
  );
}

/// A bill as it stands on a day.
final class BillStatus {
  /// The status.
  const BillStatus({
    required this.bill,
    required this.nextDue,
    required this.lastOccurrence,
    required this.state,
    required this.matchedTransactionId,
  });

  /// The bill.
  final BillReminder bill;

  /// Its first occurrence on or after the day, or null (a one-off already past).
  final LocalDate? nextDue;

  /// Its last occurrence before the day, or null.
  final LocalDate? lastOccurrence;

  /// What the bill is: [BillState.paid] when its next occurrence is already paid or its
  /// last one was (and nothing is due), [BillState.due] when an occurrence is due,
  /// [BillState.missed] when its last occurrence was missed and the next is not due yet,
  /// else [BillState.upcoming].
  final BillState state;

  /// The transaction that paid the occurrence [state] is about, when one did.
  final String? matchedTransactionId;

  @override
  bool operator ==(Object other) =>
      other is BillStatus &&
      other.bill == bill &&
      other.nextDue == nextDue &&
      other.lastOccurrence == lastOccurrence &&
      other.state == state &&
      other.matchedTransactionId == matchedTransactionId;

  @override
  int get hashCode =>
      Object.hash(bill, nextDue, lastOccurrence, state, matchedTransactionId);

  @override
  String toString() =>
      'BillStatus(${bill.id}, next $nextDue, last $lastOccurrence, $state)';
}

/// One bill as payment matching reads it: its schedule, and its linked stream's band
/// (null: the expected amount's, [expectedBand]).
typedef BillMatchInput = ({
  BillReminder bill,
  BillSchedule schedule,
  AmountBand? band,
});

/// Which transaction paid which occurrence: by bill id, then by due date, the
/// transaction's id.
typedef BillPayments = Map<String, Map<LocalDate, String>>;

/// The payments among [transactions] of the occurrences of [bills] due from [from] to
/// [to] (exclusive), one assignment across every active bill (`PLAN.md` §12, "5c review
/// rulings"; an inactive bill takes no payment): a transaction pays at most one
/// occurrence of any bill, and an occurrence
/// takes at most one transaction. Every match (the bill's account or any account when it
/// has none, an outflow in the band's currency within the band, dated [matchDaysBefore]
/// days before the due date to [matchDaysAfter] after; a bill with no expected amount and
/// no band matches nothing) is a candidate; candidates are taken in order of the distance
/// between the payment and the due date, then a bill on the transaction's account before
/// an any-account bill, then the earlier due date, then the bill id, then the
/// transaction id, each taken when neither its transaction nor its occurrence is taken
/// yet. The result does not depend on the order of [bills] or [transactions].
BillPayments assignPayments(
  List<BillMatchInput> bills,
  List<Transaction> transactions,
  LocalDate from,
  LocalDate to,
) {
  final List<
    ({
      int distance,
      bool anyAccount,
      LocalDate due,
      String billId,
      String transactionId,
    })
  >
  candidates = [];
  for (final BillMatchInput input in bills) {
    final BillReminder bill = input.bill;
    // A paused bill takes no payment, so it never takes one from an active bill.
    if (!bill.active) continue;
    final Money? amount = bill.amount;
    final AmountBand? sizes =
        input.band ?? (amount == null ? null : expectedBand(amount));
    if (sizes == null) continue;
    final List<LocalDate> dues = input.schedule.between(from, to);
    if (dues.isEmpty) continue;
    final String currency = sizes.min.currencyCode;
    for (final Transaction t in transactions) {
      if (t.deletedAt != null || t.hidden) continue;
      if (bill.accountId case final String account
          when t.accountId != account) {
        continue;
      }
      final int size = -t.amount.minorUnits;
      if (t.amount.currencyCode != currency ||
          size < sizes.min.minorUnits ||
          size > sizes.max.minorUnits) {
        continue;
      }
      for (final LocalDate due in dues) {
        final int offset = due.daysUntil(t.date); // positive: paid late
        if (offset < -matchDaysBefore || offset > matchDaysAfter) continue;
        candidates.add((
          distance: offset.abs(),
          anyAccount: bill.accountId == null,
          due: due,
          billId: bill.id,
          transactionId: t.id,
        ));
      }
    }
  }
  candidates.sort((a, b) {
    int c = a.distance.compareTo(b.distance);
    if (c != 0) return c;
    if (a.anyAccount != b.anyAccount) return a.anyAccount ? 1 : -1;
    c = a.due.compareTo(b.due);
    if (c != 0) return c;
    c = a.billId.compareTo(b.billId);
    return c != 0 ? c : a.transactionId.compareTo(b.transactionId);
  });
  final Set<String> spent = {};
  final BillPayments payments = {};
  for (final c in candidates) {
    if (spent.contains(c.transactionId)) continue;
    final Map<LocalDate, String> paid = payments.putIfAbsent(
      c.billId,
      () => {},
    );
    if (paid.containsKey(c.due)) continue;
    paid[c.due] = c.transactionId;
    spent.add(c.transactionId);
  }
  return payments;
}

/// The state of [bill]'s occurrence due [due] on [today], given the payment that matched
/// it ([paidBy], null when none did).
BillState occurrenceState(
  BillReminder bill,
  LocalDate due,
  LocalDate today, {
  String? paidBy,
}) {
  if (paidBy != null || bill.paidOccurrences.contains(due)) {
    return BillState.paid;
  }
  final int ahead = today.daysUntil(due);
  if (ahead >= -graceDays && ahead <= dueWindowDays) return BillState.due;
  if (ahead < -graceDays && !bill.autopay) return BillState.missed;
  return BillState.upcoming;
}

/// The status of [bill] on [today], given the payments [assignPayments] found for it
/// ([paid], by due date) and [liabilityDue], the next payment due date of the liability
/// the bill follows.
BillStatus billStatus(
  BillReminder bill,
  LocalDate today, {
  Map<LocalDate, String> paid = const {},
  LocalDate? liabilityDue,
}) {
  final BillSchedule schedule = BillSchedule.of(
    bill,
    liabilityDue: liabilityDue,
  );
  final LocalDate? next = schedule.nextOnOrAfter(today);
  final LocalDate? last = schedule.previousBefore(today);
  BillStatus status(BillState state, LocalDate? about) => BillStatus(
    bill: bill,
    nextDue: next,
    lastOccurrence: last,
    state: state,
    matchedTransactionId: about == null ? null : paid[about],
  );
  final BillState? nextState = next == null
      ? null
      : occurrenceState(bill, next, today, paidBy: paid[next]);
  final BillState? lastState = last == null
      ? null
      : occurrenceState(bill, last, today, paidBy: paid[last]);
  if (nextState == BillState.paid) return status(BillState.paid, next);
  if (lastState == BillState.due) return status(BillState.due, last);
  if (nextState == BillState.due) return status(BillState.due, next);
  if (lastState == BillState.missed) return status(BillState.missed, last);
  if (lastState == BillState.paid) return status(BillState.paid, last);
  return status(BillState.upcoming, next);
}
