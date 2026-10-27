/// What the bills screens show and what the reminders are planned from
/// (`docs/reference/bills.md`); the repositories are `billRepositoryProvider` and
/// `billAlertStoreProvider` (`core/di/providers.dart`), the sources of suggestions and
/// due dates the recurring streams and the liabilities.
library;

import 'dart:ui' show PlatformDispatcher;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/bills/application/reminder_planner.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/bills/domain/bill_suggestions.dart';
import 'package:finance_tracker/features/bills/domain/reminder_times.dart';
import 'package:finance_tracker/features/liabilities/application/liabilities_providers.dart';
import 'package:finance_tracker/features/recurring/application/recurring_providers.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'bills_providers.g.dart';

/// How far back a bill's status looks for its last occurrence's payment: past a year,
/// so an annual bill finds it.
const int statusLookbackDays = 370;

/// The live bills, by first due date, then id.
@riverpod
Stream<List<BillReminder>> bills(Ref ref) =>
    ref.watch(billRepositoryProvider).watchAll();

/// The streams' names as the app shows them, by stream id: the name of a bill recorded
/// before bills had one.
@riverpod
Future<Map<String, String>> streamNames(Ref ref) async => {
  for (final StreamView s in await ref.watch(recurringStreamsProvider.future))
    s.stream.id: s.displayName,
};

/// The next payment due date of each liability a live bill follows, by bill id.
@riverpod
Future<Map<String, LocalDate>> liabilityDueDates(Ref ref) async {
  final List<BillReminder> bills = await ref.watch(billsProvider.future);
  if (!bills.any((b) => b.liabilityAccountId != null)) return const {};
  final Map<String, LocalDate> due = {
    for (final Liability l in await ref.watch(liabilitiesProvider.future))
      if (l.nextPaymentDueDate case final LocalDate date) l.accountId: date,
  };
  return {
    for (final BillReminder b in bills)
      if (due[b.liabilityAccountId] case final LocalDate date) b.id: date,
  };
}

/// Which transaction paid which bill occurrence, one assignment across every bill
/// (`assignPayments`): the occurrences due from [statusLookbackDays] days back (or from
/// the oldest one-off bill's date, when that is older: its one occurrence stays its last)
/// to the end of the reminder window and its offsets, among the transactions dated
/// around them.
/// The bill statuses and the reminders both read it, so a payment counts the same way for
/// both. Recomputed when the bills, the followed liabilities' due dates, the transactions
/// in that range or today change.
@riverpod
Stream<BillPayments> billPayments(Ref ref) async* {
  final LocalDate today = ref.watch(todayProvider);
  final List<BillReminder> bills = await ref.watch(billsProvider.future);
  final Map<String, LocalDate> liabilityDue = await ref.watch(
    liabilityDueDatesProvider.future,
  );
  if (bills.isEmpty) {
    yield const {};
    return;
  }
  final List<BillMatchInput> inputs = [
    for (final BillReminder b in bills)
      (
        bill: b,
        schedule: BillSchedule.of(b, liabilityDue: liabilityDue[b.id]),
        band: null,
      ),
  ];
  // A one-off's only occurrence is its last however old it is, so the window reaches
  // back to the oldest one-off's date when that is older than the usual lookback.
  LocalDate from = today.addDays(-statusLookbackDays);
  for (final BillMatchInput input in inputs) {
    final BillSchedule schedule = input.schedule;
    final bool once =
        schedule.cadence == null ||
        schedule.cadence == RecurringCadence.unknown;
    if (once && schedule.anchor.isBefore(from)) from = schedule.anchor;
  }
  final LocalDate to = today.addDays(reminderWindowDays + 31 + 1);
  yield* ref
      .watch(transactionRepositoryProvider)
      .watch(
        TransactionQuery(
          range: LocalDateRange(
            from.addDays(-matchDaysBefore),
            to.addDays(matchDaysAfter),
          ),
        ),
      )
      .map((transactions) => assignPayments(inputs, transactions, from, to));
}

/// Every live bill's status today, in [bills]' order, from [billPayments].
@riverpod
Future<List<BillStatus>> billStatuses(Ref ref) async {
  final LocalDate today = ref.watch(todayProvider);
  final List<BillReminder> bills = await ref.watch(billsProvider.future);
  final Map<String, LocalDate> liabilityDue = await ref.watch(
    liabilityDueDatesProvider.future,
  );
  final BillPayments payments = await ref.watch(billPaymentsProvider.future);
  return [
    for (final BillReminder b in bills)
      billStatus(
        b,
        today,
        paid: payments[b.id] ?? const {},
        liabilityDue: liabilityDue[b.id],
      ),
  ];
}

/// The in-app keys (`bill/<id>/<due>`) of the bill occurrences paid now, by a mark or a
/// payment, so the in-app list can hide a due notice a later pull has paid (the
/// `bill_alerts` row stays, so it is not raised again).
@riverpod
Set<String> paidBillKeys(Ref ref) {
  final BillPayments payments =
      ref.watch(billPaymentsProvider).value ?? const {};
  final List<BillReminder> bills = ref.watch(billsProvider).value ?? const [];
  return {
    for (final MapEntry<String, Map<LocalDate, String>> e in payments.entries)
      for (final LocalDate due in e.value.keys) 'bill/${e.key}/$due',
    for (final BillReminder b in bills)
      for (final LocalDate due in b.paidOccurrences) 'bill/${b.id}/$due',
  };
}

/// What bill suggestions are made from: the active, unmuted recurring streams under the
/// names the app shows, and the liabilities, named by their accounts.
@riverpod
Future<BillSourceData> billSourceData(Ref ref) async {
  final List<StreamView> streams = await ref.watch(
    recurringStreamsProvider.future,
  );
  final List<Liability> liabilities = await ref.watch(
    liabilitiesProvider.future,
  );
  final Map<String, Account> accounts = {
    for (final Account a in await ref.watch(accountsProvider.future)) a.id: a,
  };
  return BillSourceData(
    streams: [
      for (final StreamView s in streams)
        SourceStream(
          id: s.stream.id,
          name: s.displayName,
          accountId: s.stream.accountId,
          cadence: s.stream.cadence,
          amount: s.stream.averageAmount,
          nextExpected: s.stream.nextExpected,
          active: s.stream.status == RecurringStatus.active && !s.muted,
        ),
    ],
    liabilities: [
      for (final Liability l in liabilities)
        if (accounts[l.accountId] case final Account account)
          SourceLiability(
            accountId: l.accountId,
            name: account.name,
            nextPaymentDueDate: l.nextPaymentDueDate,
            minimumPayment: l.minimumPaymentAmount,
          ),
    ],
  );
}

/// The bills the user may add, from [billSourceData], leaving out what a live bill
/// already links.
@riverpod
Future<List<BillSuggestion>> suggestedBills(Ref ref) async => billSuggestions(
  await ref.watch(billSourceDataProvider.future),
  await ref.watch(billsProvider.future),
);

/// What the reminders are planned from: the live bills, the followed liabilities' due
/// dates, the streams' names, and [billPayments]; recomputed when any of them changes.
@riverpod
Future<ReminderInputs> reminderInputs(Ref ref) async => ReminderInputs(
  bills: await ref.watch(billsProvider.future),
  payments: await ref.watch(billPaymentsProvider.future),
  liabilityDue: await ref.watch(liabilityDueDatesProvider.future),
  streamNames: await ref.watch(streamNamesProvider.future),
);

/// The reminders' texts, in the device's language: "Rent is due tomorrow", and the
/// expected amount.
@Riverpod(keepAlive: true)
ReminderText reminderText(Ref ref) {
  final AppLocalizations l10n = lookupAppLocalizations(
    basicLocaleListResolution(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  return (bill, name, due, offset) {
    final String shown = billName(name, l10n);
    final Money? amount = bill.amount;
    return (
      title: switch (offset) {
        0 => l10n.billReminderTitleToday(shown),
        1 => l10n.billReminderTitleTomorrow(shown),
        _ => l10n.billReminderTitleOn(
          shown,
          DateFormat.MMMEd().format(due.toDateTime()),
        ),
      },
      body: amount == null
          ? l10n.billReminderBodyNoAmount
          : l10n.billReminderBody(
              Money(amount.minorUnits.abs(), amount.currencyCode).format(),
            ),
    );
  };
}

/// A bill's [name] as the app shows it: as given, else "Bill".
String billName(String? name, AppLocalizations l10n) => switch (name?.trim()) {
  final String n when n.isNotEmpty => n,
  _ => l10n.billUnnamed,
};

/// The bill actions: saving, deleting with undo, accepting a suggestion and marking an
/// occurrence paid.
@riverpod
BillActions billActions(Ref ref) =>
    BillActions(ref.watch(billRepositoryProvider));

/// Writes bills to a [BillRepository]; it holds the repository, not a ref, so an action
/// begun on a screen finishes after the screen is gone (a delete navigates away first).
final class BillActions {
  BillActions(this._bills);

  final BillRepository _bills;

  /// Saves [bill].
  Future<void> save(BillReminder bill) => _bills.upsert(bill);

  /// Deletes bill [id]; [restore] undoes it.
  Future<void> delete(String id) => _bills.delete(id);

  /// Restores deleted bill [id].
  Future<void> restore(String id) => _bills.restore(id);

  /// Adds the bill [suggestion] makes, with id [id].
  Future<void> accept(BillSuggestion suggestion, String id) =>
      save(suggestion.accept(id));

  /// Marks bill [id]'s occurrence due [due] paid ([paid] true) or not.
  Future<void> setPaid(String id, LocalDate due, {required bool paid}) async {
    final BillReminder? bill = await currentValue(_bills.watchById(id));
    if (bill == null) return;
    await save(paid ? bill.markPaid(due) : bill.unmarkPaid(due));
  }
}
