/// The boundary between what the app wants to tell the user and how the platform shows
/// it (`docs/reference/app-core.md`, **Notifications**). The application layer raises an
/// [AppNotification] through a [Notifier]; the in-app implementation
/// (`in_app_notifications.dart`) keeps it in a list the screens show, and the system one
/// (`system_notifier.dart`) posts it to its notification channel. A notification is typed
/// data, never text: whoever shows it localizes it.
///
/// Pure Dart, no Flutter import.
library;

import 'package:shared_models/shared_models.dart';

/// Shows notifications to the user.
abstract interface class Notifier {
  /// Shows [notification].
  Future<void> notify(AppNotification notification);
}

/// Something the app tells the user.
sealed class AppNotification {
  const AppNotification();

  /// What identifies this notification: raising the same one twice shows one.
  String get key;

  /// When it was raised, UTC.
  DateTime get raisedAt;
}

/// A budget reached [thresholdBp] basis points of what was [available] in its period
/// starting [periodStart], having spent [spent].
final class BudgetThresholdNotification extends AppNotification {
  /// The notification.
  const BudgetThresholdNotification({
    required this.budgetId,
    required this.categoryId,
    required this.periodStart,
    required this.thresholdBp,
    required this.spent,
    required this.available,
    required this.raisedAt,
  });

  /// The budget.
  final String budgetId;

  /// The budget's category.
  final String categoryId;

  /// The first day of the period.
  final LocalDate periodStart;

  /// The threshold reached, in basis points of [available] (8000 or 10000).
  final int thresholdBp;

  /// What was spent in the period when it was raised.
  final Money spent;

  /// What was available in the period.
  final Money available;

  @override
  final DateTime raisedAt;

  @override
  String get key => 'budget/$budgetId/$periodStart/$thresholdBp';
}

/// Bill [billId], named [name] (null when it has none), is due on [dueDate], today or
/// tomorrow, expecting [amount] when known (in the app's sign, an outflow negative).
final class BillDueNotification extends AppNotification {
  /// The notification.
  const BillDueNotification({
    required this.billId,
    required this.name,
    required this.dueDate,
    required this.amount,
    required this.raisedAt,
  });

  /// The bill.
  final String billId;

  /// Its name, or its stream's for a bill recorded before bills had names.
  final String? name;

  /// The occurrence that is due.
  final LocalDate dueDate;

  /// The expected amount.
  final Money? amount;

  @override
  final DateTime raisedAt;

  @override
  String get key => 'bill/$billId/$dueDate';
}

/// The summary of the week starting Monday [weekStart] is ready
/// (`features/reports/`).
final class WeeklySummaryNotification extends AppNotification {
  /// The notification.
  const WeeklySummaryNotification({
    required this.weekStart,
    required this.raisedAt,
  });

  /// The Monday the week summarised starts on.
  final LocalDate weekStart;

  @override
  final DateTime raisedAt;

  @override
  String get key => 'weekly/$weekStart';
}

/// The key prefix of a [SyncProblem.failing] notification.
const String failingProblemPrefix = 'sync/failing/';

/// What went wrong with sync, for [SyncProblemNotification].
enum SyncProblem {
  /// Every session has failed for a day.
  failing,

  /// The server ended the session (seen by the background sync).
  signedOut,

  /// A linked bank needs the user to sign in to it again.
  bankNeedsAttention,
}

/// Sync needs the user: [problem], since the last successful sync at [since] (for
/// [SyncProblem.failing]) or for the Item [itemId] (for
/// [SyncProblem.bankNeedsAttention]).
final class SyncProblemNotification extends AppNotification {
  /// The notification.
  const SyncProblemNotification({
    required this.problem,
    required this.raisedAt,
    this.since,
    this.itemId,
  });

  /// What went wrong.
  final SyncProblem problem;

  /// When sync last succeeded, UTC, for [SyncProblem.failing].
  final DateTime? since;

  /// The Item, for [SyncProblem.bankNeedsAttention].
  final String? itemId;

  @override
  final DateTime raisedAt;

  @override
  String get key => switch (problem) {
    SyncProblem.failing =>
      '$failingProblemPrefix${since?.millisecondsSinceEpoch}',
    SyncProblem.signedOut =>
      'sync/signed-out/${raisedAt.millisecondsSinceEpoch}',
    SyncProblem.bankNeedsAttention => 'sync/bank/$itemId',
  };
}
