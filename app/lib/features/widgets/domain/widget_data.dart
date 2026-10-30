/// What the home screen widgets show (`docs/reference/widgets.md`, **The snapshot**;
/// `PLAN.md` §12 "Phase 8 package pins and platform rulings"): one snapshot the app
/// writes and the Android side only renders. Every amount is a `Money` (integer minor
/// units and a currency code) beside the text the app formatted for it in the device
/// locale, since RemoteViews cannot format money; every row carries its own spoken text.
/// Pure Dart.
///
/// The snapshot is JSON under one key ([widgetSnapshotKey]) so the three widgets always
/// read one consistent write; [widgetSnapshotVersion] lets the Kotlin side refuse a
/// layout it does not know.
library;

import 'package:shared_models/shared_models.dart';

/// The key the snapshot is stored under.
const String widgetSnapshotKey = 'snapshot';

/// The snapshot's format version.
const int widgetSnapshotVersion = 1;

/// What a locked snapshot writes for an amount: no digits, no length, no sign.
const String widgetMask = '\u2022\u2022\u2022\u2022';

/// How many accounts, budgets and bills a snapshot holds at most.
const int widgetRowLimit = 3;

/// Net worth today: [amount], formatted as [text], [estimated] when the latest point
/// was reconstructed from transactions (`source: derived`), labelled by [basisText].
final class WidgetNetWorth {
  const WidgetNetWorth({
    required this.amount,
    required this.text,
    required this.estimated,
    required this.basisText,
    required this.spokenText,
  });

  final Money amount;
  final String text;
  final bool estimated;
  final String basisText;
  final String spokenText;

  /// The JSON form; [locked], with no amount in it.
  Map<String, Object?> toJson({bool locked = false}) => {
    'minor': locked ? null : amount.minorUnits,
    'currency': locked ? null : amount.currencyCode,
    'text': locked ? widgetMask : text,
    'estimated': estimated,
    'basis': basisText,
    'spoken': spokenText,
  };
}

/// An account with the balance it is shown with: [reported] by its institution or
/// derived from its transactions, which [basisText] says.
final class WidgetAccount {
  const WidgetAccount({
    required this.id,
    required this.name,
    required this.balance,
    required this.text,
    required this.reported,
    required this.basisText,
    required this.spokenText,
  });

  final String id;
  final String name;
  final Money balance;
  final String text;
  final bool reported;
  final String basisText;
  final String spokenText;

  /// The JSON form; [locked], with no amount in it.
  Map<String, Object?> toJson({bool locked = false}) => {
    'id': id,
    'name': name,
    'minor': locked ? null : balance.minorUnits,
    'currency': locked ? null : balance.currencyCode,
    'text': locked ? widgetMask : text,
    'reported': reported,
    'basis': basisText,
    'spoken': spokenText,
  };
}

/// A budget in its current period: [spent] of [available], the bar filled to
/// [fillBasisPoints] (0 to 10000), [over] when it is over or nothing is available,
/// [percentText] beside the bar and [detailText] (left or over) under it.
final class WidgetBudget {
  const WidgetBudget({
    required this.id,
    required this.name,
    required this.spent,
    required this.available,
    required this.fillBasisPoints,
    required this.over,
    required this.percentText,
    required this.detailText,
    required this.spokenText,
  });

  final String id;
  final String name;
  final Money spent;
  final Money available;
  final int fillBasisPoints;
  final bool over;
  final String percentText;
  final String detailText;
  final String spokenText;

  /// The JSON form; [locked], with no amount, fill or standing in it.
  Map<String, Object?> toJson({bool locked = false}) => {
    'id': id,
    'name': name,
    'spent_minor': locked ? null : spent.minorUnits,
    'available_minor': locked ? null : available.minorUnits,
    'currency': locked ? null : spent.currencyCode,
    'fill_bp': locked ? 0 : fillBasisPoints,
    'over': !locked && over,
    'percent': locked ? null : percentText,
    'detail': locked ? null : detailText,
    'spoken': spokenText,
  };
}

/// A bill's occurrence [due], [overdue] when it was missed, with its expected [amount]
/// (null when the bill has none) and the texts for both.
final class WidgetBill {
  const WidgetBill({
    required this.id,
    required this.name,
    required this.due,
    required this.dueText,
    required this.overdue,
    required this.amount,
    required this.amountText,
    required this.spokenText,
  });

  final String id;
  final String name;
  final LocalDate due;
  final String dueText;
  final bool overdue;
  final Money? amount;
  final String? amountText;
  final String spokenText;

  /// The JSON form; [locked], with no amount in it.
  Map<String, Object?> toJson({bool locked = false}) => {
    'id': id,
    'name': name,
    'due': due.toIso(),
    'due_text': dueText,
    'overdue': overdue,
    'minor': locked ? null : amount?.minorUnits,
    'currency': locked ? null : amount?.currencyCode,
    'amount': locked && amountText != null ? widgetMask : amountText,
    'spoken': spokenText,
  };
}

/// The snapshot: [signedIn] false (nothing else shown: every widget offers to set the app
/// up) or the data, each list at most [widgetRowLimit] long; written at [updatedAt] (UTC),
/// which [updatedText] says in the device's zone. While the app lock is enabled it is
/// [locked]: the widgets mask every amount, percent and bar, and the spoken sentences say
/// the amounts are hidden.
final class WidgetData {
  const WidgetData({
    required this.signedIn,
    this.locked = false,
    required this.netWorth,
    required this.accounts,
    required this.budgets,
    required this.bills,
    required this.updatedAt,
    required this.updatedText,
  });

  /// The snapshot of an install nobody is signed in to.
  const WidgetData.signedOut({
    required this.updatedAt,
    required this.updatedText,
  }) : signedIn = false,
       locked = false,
       netWorth = null,
       accounts = const [],
       budgets = const [],
       bills = const [];

  final bool signedIn;
  final bool locked;
  final WidgetNetWorth? netWorth;
  final List<WidgetAccount> accounts;
  final List<WidgetBudget> budgets;
  final List<WidgetBill> bills;
  final DateTime updatedAt;
  final String updatedText;

  /// This snapshot written at [at], which [text] says.
  WidgetData stamped(DateTime at, String text) => WidgetData(
    signedIn: signedIn,
    locked: locked,
    netWorth: netWorth,
    accounts: accounts,
    budgets: budgets,
    bills: bills,
    updatedAt: at,
    updatedText: text,
  );

  /// The snapshot as the Kotlin side reads it. A [locked] one holds no amount: each is
  /// [widgetMask] or left out, so the preference file it is stored in has no balances
  /// (the widgets mask them as well, as a fallback).
  Map<String, Object?> toJson() => {
    'v': widgetSnapshotVersion,
    'signed_in': signedIn,
    'locked': locked,
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'updated': updatedText,
    'net_worth': netWorth?.toJson(locked: locked),
    'accounts': [
      for (final WidgetAccount a in accounts) a.toJson(locked: locked),
    ],
    'budgets': [for (final WidgetBudget b in budgets) b.toJson(locked: locked)],
    'bills': [for (final WidgetBill b in bills) b.toJson(locked: locked)],
  };
}
