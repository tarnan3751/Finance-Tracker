/// What a forecast is projected from (`docs/reference/forecast.md`, **The inputs**): the
/// start balance of the chosen accounts in one currency, the streams and bill
/// occurrences on them, and the allowance for everyday spending. Pure Dart.
///
/// The **allowance** is the average daily outflow of the last [allowanceWindowDays]
/// whole days that no schedule explains: the sum of the outflows on the accounts, in the
/// currency, dated from [allowanceWindowDays] days before today to yesterday, live and
/// not hidden (pending ones included), less every stream's members, the bill payments and
/// the transfers to the user's own accounts ([allowanceExcludedCodes] by effective
/// category; card payments stay in), divided by [allowanceWindowDays], rounded half-even.
library;

import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:shared_models/shared_models.dart';

/// How many whole days before today the allowance is averaged over.
const int allowanceWindowDays = 90;

/// The effective-category codes whose outflows the allowance leaves out: money moved to
/// the user's own accounts, which the balance of all of them does not lose. A transfer to
/// a savings account the app does not hold is left out too, a known limit.
const Set<String> allowanceExcludedCodes = {
  'TRANSFER_OUT_ACCOUNT_TRANSFER',
  'TRANSFER_OUT_SAVINGS',
};

/// A stream the forecast projects: the stream, the name the app shows it by, and its
/// live member transactions, whose band ([StreamBand]) gives each occurrence's amount.
final class ForecastStream {
  /// The stream [stream], shown as [name], with [members].
  const ForecastStream({
    required this.stream,
    required this.name,
    this.members = const [],
  });

  /// The stream, in the app's sign (income positive).
  final RecurringStream stream;

  /// The name the app shows.
  final String name;

  /// Its live member transactions; with none, an occurrence is the stream's
  /// `averageAmount` with no band.
  final List<Transaction> members;
}

/// A bill's occurrences the forecast counts: the unpaid ones, already expanded from its
/// schedule.
final class ForecastBill {
  /// Bill [id], shown as [name], due on [dates], each for [amount].
  const ForecastBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dates,
  });

  /// The bill's id.
  final String id;

  /// The name the app shows, or null for the screen's own word for a bill.
  final String? name;

  /// What each occurrence takes, negative; null for a bill with no expected amount,
  /// which is listed among a day's events and moves nothing.
  final Money? amount;

  /// The unpaid due dates.
  final List<LocalDate> dates;
}

/// Everything one forecast series is projected from.
final class ForecastPlan {
  /// The plan as of [today], from [start].
  const ForecastPlan({
    required this.today,
    required this.start,
    required this.allowance,
    this.streams = const [],
    this.bills = const [],
  });

  /// The day the forecast starts on.
  final LocalDate today;

  /// The chosen accounts' balance today, in the series' currency.
  final Money start;

  /// The everyday spending taken off each day, zero or positive ([dailyAllowance]).
  final Money allowance;

  /// The streams on the chosen accounts in the currency.
  final List<ForecastStream> streams;

  /// The bills counted in the currency.
  final List<ForecastBill> bills;

  /// The series' currency.
  String get currencyCode => start.currencyCode;
}

/// The allowance over [ledger] on [accountIds] in [currencyCode] as of [today], leaving
/// out [excludedIds] (the streams' members and the bill payments) and the transfers
/// [allowanceExcludedCodes] names, by their effective category in [lookup].
Money dailyAllowance(
  Iterable<Transaction> ledger, {
  required LocalDate today,
  required Set<String> accountIds,
  required String currencyCode,
  required Set<String> excludedIds,
  required CategoryLookup lookup,
}) {
  final LocalDate from = today.addDays(-allowanceWindowDays);
  Money spent = Money.zero(currencyCode);
  for (final Transaction t in ledger) {
    if (t.deletedAt != null ||
        t.hidden ||
        !t.amount.isNegative ||
        t.amount.currencyCode != currencyCode ||
        !accountIds.contains(t.accountId) ||
        t.date.isBefore(from) ||
        !t.date.isBefore(today) ||
        excludedIds.contains(t.id) ||
        allowanceExcludedCodes.contains(
          effectiveCategory(t, lookup)?.plaidCategory,
        )) {
      continue;
    }
    spent -= t.amount;
  }
  return spent.multipliedBy(1, allowanceWindowDays);
}
