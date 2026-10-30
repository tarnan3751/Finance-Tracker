/// The home screen widgets' snapshot from what the app shows (`docs/reference/widgets.md`,
/// **The snapshot**): pure functions of the screens' own values, formatted in the device
/// locale (`Money.format`, intl's default locale) with the app's strings.
///
/// - **Net worth** is the latest point of the observed series of the currency the Net
///   worth segment shows first (the device's when held, else the first): the full
///   history's last point is always that one, since the reconstruction only reaches back
///   before the first snapshot; `estimated` follows the point's `derived` flag.
/// - **Accounts** are the visible live accounts: those in the device's currency first,
///   the largest balances as shown (`shownBalance`: reported, else from transactions) by
///   absolute minor units, the display order breaking ties; then those in other
///   currencies by name (minor units of two currencies do not compare);
///   [widgetRowLimit] of them.
/// - **Budgets** are every live budget's current period, over-limit ones first (over, or
///   something spent with nothing available), then by how full the bar is; the bar and
///   the texts are the budget card's.
/// - **Bills** are the active bills' occurrences a bill row shows (`billFocus`), paid
///   ones left out, missed ones first, then by due date.
/// - **Locked**: while the app lock is enabled the snapshot is `locked`, every row's
///   spoken sentence says its amount is hidden, and the order says nothing of the
///   amounts: accounts and budgets by name, bills by due date alone; the widgets mask
///   the amounts themselves.
library;

import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// The snapshot of a signed-in install on [today], written at [now] (see the library
/// comment). [netWorth] is the observed series per currency, [categories] the live ones
/// by id, [payments] the bill payment assignment and [streamNames] the recurring
/// streams' names by id. [deviceCurrency] is the currency the device's locale uses;
/// [locked] whether the app lock is enabled.
WidgetData buildWidgetData({
  required List<Account> accounts,
  required Map<String, Money?> derived,
  required Map<String, List<NetWorthPoint>> netWorth,
  required List<BudgetStatus> budgets,
  required Map<String, Category> categories,
  required List<BillStatus> bills,
  required BillPayments payments,
  required Map<String, String> streamNames,
  required LocalDate today,
  required DateTime now,
  required tz.Location location,
  required String deviceCurrency,
  required bool locked,
  required AppLocalizations l10n,
}) => WidgetData(
  signedIn: true,
  locked: locked,
  netWorth: _netWorth(netWorth, deviceCurrency, l10n, locked),
  accounts: _accounts(accounts, derived, deviceCurrency, l10n, locked),
  budgets: _budgets(budgets, categories, l10n, locked),
  bills: _bills(bills, payments, streamNames, today, l10n, locked),
  updatedAt: now,
  updatedText: widgetUpdatedText(now, location, l10n),
);

/// "Updated 2:41 PM": [now] (UTC) as a time of day in [location].
String widgetUpdatedText(
  DateTime now,
  tz.Location location,
  AppLocalizations l10n,
) => l10n.widgetUpdated(
  // intl's narrow no-break space before AM and PM, as formatDateTime replaces it.
  DateFormat.jm()
      .format(tz.TZDateTime.from(now, location))
      .replaceAll(' ', ' '),
);

WidgetNetWorth? _netWorth(
  Map<String, List<NetWorthPoint>> series,
  String deviceCurrency,
  AppLocalizations l10n,
  bool locked,
) {
  final List<String> held = [
    for (final MapEntry<String, List<NetWorthPoint>> e in series.entries)
      if (e.value.isNotEmpty) e.key,
  ]..sort();
  if (held.isEmpty) return null;
  final String currency = held.contains(deviceCurrency)
      ? deviceCurrency
      : held.first;
  final NetWorthPoint point = series[currency]!.last;
  final String text = point.netWorth.format();
  final String basis = point.derived
      ? l10n.netWorthEstimated
      : l10n.widgetNetWorthObserved;
  return WidgetNetWorth(
    amount: point.netWorth,
    text: text,
    estimated: point.derived,
    basisText: basis,
    spokenText: locked
        ? l10n.widgetNetWorthSpokenHidden
        : l10n.widgetNetWorthSpoken(text, basis),
  );
}

List<WidgetAccount> _accounts(
  List<Account> accounts,
  Map<String, Money?> derived,
  String deviceCurrency,
  AppLocalizations l10n,
  bool locked,
) {
  final List<(Account, ShownBalance)> shown = [
    for (final Account a in accounts)
      if (!a.isHidden) (a, shownBalance(a, derived)),
  ];
  bool local((Account, ShownBalance) e) =>
      e.$2.amount.currencyCode == deviceCurrency;
  int byName((Account, ShownBalance) x, (Account, ShownBalance) y) {
    final int name = x.$1.name.compareTo(y.$1.name);
    return name != 0 ? name : x.$1.id.compareTo(y.$1.id);
  }

  shown.sort((x, y) {
    // Locked: which accounts show and in what order says nothing of their balances.
    if (locked) return byName(x, y);
    if (local(x) != local(y)) return local(x) ? -1 : 1;
    if (!local(x)) return byName(x, y);
    final int bySize = y.$2.amount.minorUnits.abs().compareTo(
      x.$2.amount.minorUnits.abs(),
    );
    return bySize != 0
        ? bySize
        : x.$1.displayOrder.compareTo(y.$1.displayOrder);
  });
  return [
    for (final (Account a, ShownBalance b) in shown.take(widgetRowLimit))
      () {
        final String text = b.amount.format();
        final String basis = b.reported
            ? l10n.balanceReported
            : l10n.balanceFromTransactions;
        return WidgetAccount(
          id: a.id,
          name: a.name,
          balance: b.amount,
          text: text,
          reported: b.reported,
          basisText: basis,
          spokenText: locked
              ? l10n.widgetAccountSpokenHidden(a.name)
              : l10n.widgetAccountSpoken(a.name, text, basis),
        );
      }(),
  ];
}

List<WidgetBudget> _budgets(
  List<BudgetStatus> statuses,
  Map<String, Category> categories,
  AppLocalizations l10n,
  bool locked,
) {
  final List<WidgetBudget> rows = [
    for (final BudgetStatus s in statuses)
      () {
        final String name =
            categories[s.budget.categoryId]?.name ?? l10n.budgetDeletedCategory;
        final int? basisPoints = s.progress.percentBasisPoints;
        final Money remaining = s.remaining;
        final bool over = basisPoints == null || remaining.isNegative;
        return WidgetBudget(
          id: s.budget.id,
          name: name,
          spent: s.spent,
          available: s.available,
          // As the budget card fills it: full when over, or when something was spent
          // with nothing available.
          fillBasisPoints: basisPoints == null
              ? (s.spent.isPositive ? 10000 : 0)
              : basisPoints.clamp(0, 10000),
          over: over,
          percentText: basisPoints == null
              ? l10n.budgetNothingAvailable
              : l10n.budgetPercent(basisPoints ~/ 100),
          detailText: remaining.isNegative
              ? l10n.budgetOver((-remaining).format())
              : l10n.budgetLeft(remaining.format()),
          spokenText: switch (basisPoints) {
            _ when locked => l10n.widgetBudgetSpokenHidden(name),
            null => l10n.budgetProgressNothingSemantics(name, s.spent.format()),
            _ when remaining.isNegative => l10n.budgetProgressOverSemantics(
              name,
              basisPoints ~/ 100,
              s.available.format(),
              (-remaining).format(),
            ),
            _ => l10n.budgetProgressSemantics(
              name,
              basisPoints ~/ 100,
              s.available.format(),
              remaining.format(),
            ),
          },
        );
      }(),
  ];
  final List<int> order = List.generate(rows.length, (i) => i)
    ..sort((a, b) {
      final WidgetBudget x = rows[a];
      final WidgetBudget y = rows[b];
      // Locked: by name, so the order shows no budget is over.
      if (locked) {
        final int byName = x.name.compareTo(y.name);
        return byName != 0 ? byName : a.compareTo(b);
      }
      if (x.over != y.over) return x.over ? -1 : 1;
      final int byFill = y.fillBasisPoints.compareTo(x.fillBasisPoints);
      return byFill != 0 ? byFill : a.compareTo(b);
    });
  return [for (final int i in order.take(widgetRowLimit)) rows[i]];
}

List<WidgetBill> _bills(
  List<BillStatus> statuses,
  BillPayments payments,
  Map<String, String> streamNames,
  LocalDate today,
  AppLocalizations l10n,
  bool locked,
) {
  final List<WidgetBill> rows = [];
  for (final BillStatus s in statuses) {
    final BillReminder bill = s.bill;
    if (!bill.active) continue;
    final BillOccurrence focus = billFocus(
      s,
      today,
      payments[bill.id] ?? const {},
    );
    final LocalDate? due = focus.due;
    if (due == null || focus.state == BillState.paid) continue;
    final bool overdue = focus.state == BillState.missed;
    final String name = billName(bill.name ?? streamNames[bill.streamId], l10n);
    final String when = _dueText(l10n, due, today);
    final String dueText = overdue ? l10n.widgetBillMissed(when) : when;
    final Money? expected = bill.amount;
    final Money? amount = expected == null
        ? null
        : Money(expected.minorUnits.abs(), expected.currencyCode);
    final String? amountText = amount?.format();
    rows.add(
      WidgetBill(
        id: bill.id,
        name: name,
        due: due,
        dueText: dueText,
        overdue: overdue,
        amount: amount,
        amountText: amountText,
        spokenText: switch (amountText) {
          null => l10n.widgetBillSpokenNoAmount(name, dueText),
          _ when locked => l10n.widgetBillSpokenHidden(name, dueText),
          final String amount => l10n.widgetBillSpoken(name, dueText, amount),
        },
      ),
    );
  }
  rows.sort((x, y) {
    // Locked: by due date alone.
    if (!locked && x.overdue != y.overdue) return x.overdue ? -1 : 1;
    final int byDue = x.due.compareTo(y.due);
    return byDue != 0 ? byDue : x.id.compareTo(y.id);
  });
  return rows.take(widgetRowLimit).toList(growable: false);
}

// As the Bills segment says a due date: relative within a week, else the date (its
// month and day, for the widget's width).
String _dueText(AppLocalizations l10n, LocalDate due, LocalDate today) {
  final int days = today.daysUntil(due);
  if (days >= 0 && days <= dueWindowDays) return l10n.billDueIn(days);
  if (days < 0 && days > -7) return l10n.billDueAgo(-days);
  return l10n.billDueOn(DateFormat.MMMd().format(due.toDateTime()));
}
