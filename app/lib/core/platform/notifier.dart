/// The boundary between what the app wants to tell the user and how the platform shows
/// it (`docs/reference/app-core.md`, **Notifications**). The application layer raises an
/// [AppNotification] through a [Notifier]; the in-app implementation
/// (`in_app_notifications.dart`) keeps it in a list the screens show, and Phase 8's
/// Android implementation posts it to a notification channel. A notification is typed
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
