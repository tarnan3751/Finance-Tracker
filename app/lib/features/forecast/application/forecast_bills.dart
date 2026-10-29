/// The bills the forecast counts (`docs/reference/forecast.md`, **Bills**): each active
/// bill's occurrences from [overdueDays] days ago to the horizon, from its schedule
/// (`BillSchedule`, a followed liability's due date its anchor), less the ones already
/// paid, by a mark or by the payment assignment the bill statuses read (`BillPayments`).
/// Pure Dart.
///
/// A bill is left out when it is paused, when it follows a stream the forecast already
/// projects (the stream wins, so it is not counted twice), or when it is paid from an
/// account the series does not cover; a bill with no account counts in every series in
/// its amount's currency (`PLAN.md` §12 "5d plan rulings", D4). Its amount is an outflow
/// whatever its sign; a bill with no amount is listed among a day's events only. It is
/// named by its own name, else by the stream it follows.
library;

import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:shared_models/shared_models.dart';

/// The bills of [bills] the series in [currencyCode] over [accountIds] counts, as of
/// [today], for [horizonDays] days.
List<ForecastBill> forecastBills(
  List<BillReminder> bills, {
  required LocalDate today,
  required int horizonDays,
  required String currencyCode,
  required Set<String> accountIds,
  required Set<String> projectedStreamIds,
  required Map<String, LocalDate> liabilityDue,
  required BillPayments payments,
  required Map<String, String> streamNames,
}) => [
  for (final BillReminder b in bills)
    if (b.active &&
        !projectedStreamIds.contains(b.streamId) &&
        (b.accountId == null || accountIds.contains(b.accountId)) &&
        (b.amount == null || b.amount!.currencyCode == currencyCode))
      ForecastBill(
        id: b.id,
        name: switch (b.name?.trim()) {
          final String n when n.isNotEmpty => n,
          _ => streamNames[b.streamId],
        },
        amount: b.amount == null ? null : -b.amount!.abs(),
        dates: [
          for (final LocalDate due
              in BillSchedule.of(b, liabilityDue: liabilityDue[b.id]).between(
                today.addDays(-overdueDays),
                today.addDays(horizonDays + 1),
              ))
            if (!b.paidOccurrences.contains(due) &&
                !(payments[b.id]?.containsKey(due) ?? false))
              due,
        ],
      ),
];

/// The transactions [payments] assigned to a bill occurrence.
Set<String> billPaymentIds(BillPayments payments) => {
  for (final Map<LocalDate, String> paid in payments.values) ...paid.values,
};
