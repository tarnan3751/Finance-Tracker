/// What the forecast screen shows (`docs/reference/forecast.md`, **Providers**): the
/// account selection, kept on the device in `app_meta`, the plan of the series shown, and
/// the series for each horizon. The inputs are the accounts with their balances, the
/// merged streams (`mergedStreamsProvider`) with their members in the live ledger
/// (`recurringLedgerProvider`), the bills with their payments (`billPaymentsProvider`),
/// the categories and today.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/forecast/application/forecast_bills.dart';
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_selection.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'forecast_providers.g.dart';

/// Which accounts the forecast covers and which currency it shows, as the user's changes
/// from the default (`ForecastSelection`), kept on this device only under
/// `AppMetaKeys.forecastSelection` (never synced). The changes are applied one at a time,
/// in the order they are made: the state is updated, then written; when the write fails
/// the state goes back and the change's Future fails.
@Riverpod(keepAlive: true)
class ForecastSelectionController extends _$ForecastSelectionController {
  Future<void> _changes = Future<void>.value();

  @override
  Future<ForecastSelection> build() async {
    final String? stored = await ref
        .watch(appMetaStoreProvider)
        .read(AppMetaKeys.forecastSelection);
    if (stored == null) return const ForecastSelection();
    try {
      return ForecastSelection.fromJson(jsonDecode(stored));
    } on FormatException {
      return const ForecastSelection();
    }
  }

  /// Switches [account] on or off.
  Future<void> toggle(Account account) => _change((s) => s.toggled(account));

  /// Shows the series in currency [code].
  Future<void> showCurrency(String code) => _change((s) => s.showing(code));

  Future<void> _change(ForecastSelection Function(ForecastSelection) change) {
    final Future<void> run = _changes.then((_) async {
      final ForecastSelection previous = await future;
      final ForecastSelection next = change(previous);
      state = AsyncData(next);
      try {
        await ref
            .read(appMetaStoreProvider)
            .write(AppMetaKeys.forecastSelection, jsonEncode(next.toJson()));
      } catch (_) {
        state = AsyncData(previous);
        rethrow;
      }
    });
    _changes = run.then((_) {}, onError: (Object _) {});
    return run;
  }
}

/// What the series shown is projected from: the covered accounts in the currency shown,
/// their balance as each is shown (reported, else derived: `shownBalance`), their active,
/// unmuted streams with their live members, the bills (`forecastBills`) over the longest
/// horizon, and the allowance; null when no account is covered.
@riverpod
Future<ForecastPlan?> forecastPlan(Ref ref) async {
  final LocalDate today = ref.watch(todayProvider);
  final ForecastSelection selection = await ref.watch(
    forecastSelectionControllerProvider.future,
  );
  final List<Account> accounts = await ref.watch(accountsProvider.future);
  final String? currency = selection.currencyFor(
    accounts,
    defaultCurrencyCode(),
  );
  if (currency == null) return null;
  final List<Account> covered = [
    for (final Account a in selection.coveredAmong(accounts))
      if (a.currencyCode == currency) a,
  ];
  final Set<String> accountIds = {for (final Account a in covered) a.id};
  final Map<String, Money?> derived = await ref.watch(
    derivedBalancesProvider.future,
  );
  final List<StreamView> streams = await ref.watch(
    mergedStreamsProvider.future,
  );
  final List<Transaction> ledger = await ref.watch(
    recurringLedgerProvider.future,
  );
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<BillReminder> bills = await ref.watch(billsProvider.future);
  final Map<String, LocalDate> liabilityDue = await ref.watch(
    liabilityDueDatesProvider.future,
  );
  final BillPayments payments = await ref.watch(billPaymentsProvider.future);
  final Map<String, String> streamNames = await ref.watch(
    streamNamesProvider.future,
  );
  final Map<String, Transaction> byId = {
    for (final Transaction t in ledger) t.id: t,
  };
  final List<ForecastStream> projected = [
    for (final StreamView v in streams)
      if (v.stream.status == RecurringStatus.active &&
          !v.muted &&
          accountIds.contains(v.stream.accountId) &&
          v.stream.averageAmount.currencyCode == currency)
        ForecastStream(
          stream: v.stream,
          name: v.displayName,
          members: [for (final String id in v.stream.transactionIds) ?byId[id]],
        ),
  ];
  return ForecastPlan(
    today: today,
    start: Money.sum([
      for (final Account a in covered) shownBalance(a, derived).amount,
    ], currencyCode: currency),
    streams: projected,
    bills: forecastBills(
      bills,
      today: today,
      horizonDays: forecastHorizons.last,
      currencyCode: currency,
      accountIds: accountIds,
      projectedStreamIds: {
        for (final ForecastStream s in projected) s.stream.id,
      },
      liabilityDue: liabilityDue,
      payments: payments,
      streamNames: streamNames,
    ),
    allowance: dailyAllowance(
      ledger,
      today: today,
      accountIds: accountIds,
      currencyCode: currency,
      // Every stream's members, muted and ended ones too, and the bill payments: none
      // is everyday spending.
      excludedIds: {
        for (final StreamView v in streams) ...v.stream.transactionIds,
        ...billPaymentIds(payments),
      },
      lookup: categoryLookup(categories),
    ),
  );
}

/// The forecast for [horizonDays] days (30 or 90, `forecastHorizons`), or null when no
/// account is covered.
@riverpod
Future<ForecastSeries?> forecast(Ref ref, int horizonDays) async {
  final ForecastPlan? plan = await ref.watch(forecastPlanProvider.future);
  return plan == null ? null : projectCashFlow(plan, horizonDays);
}
