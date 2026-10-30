/// The budget alerts in the app: the bell on the Budgets screen's app bar, badged with
/// the unread count, and the sheet it opens over the whole app, listing `inAppNotificationsProvider`'s
/// notifications newest first ("Groceries reached 80 % of $500.00 on Oct 20", the day in
/// the device zone; "Rent is due Nov 1", hidden once that occurrence is paid), with "Mark
/// all read". Tapping one marks it read
/// and opens its budget's transactions in the period it was raised for, or its bill.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// The in-app notifications as the bell and the sheet show them: a bill's due notice is
/// left out once its occurrence is paid.
List<InAppNotification> shownNotifications(WidgetRef ref) {
  final Set<String> paid = ref.watch(paidBillKeysProvider);
  return [
    for (final InAppNotification n in ref.watch(inAppNotificationsProvider))
      if (!paid.contains(n.notification.key)) n,
  ];
}

/// The bell that opens the alerts, badged with how many are unread.
class BudgetAlertsButton extends ConsumerWidget {
  const BudgetAlertsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int unread = shownNotifications(ref).where((n) => !n.read).length;
    return IconButton(
      tooltip: l10n.alertsTooltip(unread),
      icon: Badge(
        isLabelVisible: unread > 0,
        // The tooltip says the count; the badge would say it twice.
        label: ExcludeSemantics(
          child: Text(NumberFormat.decimalPattern().format(unread)),
        ),
        child: Icon(
          unread > 0 ? Icons.notifications : Icons.notifications_none,
        ),
      ),
      onPressed: () => showModalBottomSheet<void>(
        // On the router's root navigator, over the whole app with its navigation bar,
        // as a modal sheet is (the app's own root, even when the app is nested).
        context: GoRouter.of(context)
            .routerDelegate
            .navigatorKey
            .currentContext!,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => _AlertsSheet(
          onOpen: (notification) {
            Navigator.of(sheetContext).pop();
            _open(context, ref, notification);
          },
          onOpenBill: (notification) {
            Navigator.of(sheetContext).pop();
            _openBill(context, ref, notification);
          },
          onOpenSummary: (notification) {
            Navigator.of(sheetContext).pop();
            _openSummary(context, ref, notification);
          },
        ),
      ),
    );
  }

  // Marks [notification] read and opens its budget in the period it was raised for.
  void _open(
    BuildContext context,
    WidgetRef ref,
    BudgetThresholdNotification notification,
  ) {
    ref.read(inAppNotificationsProvider.notifier).markRead(notification.key);
    final Budget? budget = ref
        .read(budgetsProvider)
        .value
        ?.where((b) => b.id == notification.budgetId)
        .firstOrNull;
    if (budget != null) {
      final LocalDate current = periodContaining(
        ref.read(todayProvider),
        budget.periodStartDay,
      ).start;
      final LocalDate raised = notification.periodStart;
      ref
          .read(budgetPeriodOffsetProvider.notifier)
          .select(
            (raised.year - current.year) * 12 + raised.month - current.month,
          );
    }
    BudgetTransactionsRoute(notification.budgetId).push<void>(context);
  }

  // Marks [notification] read and opens its bill.
  void _openBill(
    BuildContext context,
    WidgetRef ref,
    BillDueNotification notification,
  ) {
    ref.read(inAppNotificationsProvider.notifier).markRead(notification.key);
    EditBillRoute(notification.billId).push<void>(context);
  }

  // Marks [notification] read and opens the weekly summary.
  void _openSummary(
    BuildContext context,
    WidgetRef ref,
    WeeklySummaryNotification notification,
  ) {
    ref.read(inAppNotificationsProvider.notifier).markRead(notification.key);
    const WeeklySummaryRoute().push<void>(context);
  }
}

class _AlertsSheet extends ConsumerWidget {
  const _AlertsSheet({
    required this.onOpen,
    required this.onOpenBill,
    required this.onOpenSummary,
  });

  final ValueChanged<BudgetThresholdNotification> onOpen;
  final ValueChanged<BillDueNotification> onOpenBill;
  final ValueChanged<WeeklySummaryNotification> onOpenSummary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<InAppNotification> notifications = shownNotifications(ref);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final Clock clock = ref.watch(clockProvider);
    final bool anyUnread = notifications.any((n) => !n.read);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.alertsTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: anyUnread
                    ? ref.read(inAppNotificationsProvider.notifier).markAllRead
                    : null,
                child: Text(l10n.alertsMarkAllRead),
              ),
            ],
          ),
        ),
        if (notifications.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Text(
              l10n.alertsEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                for (final InAppNotification n in notifications)
                  switch (n.notification) {
                    final BudgetThresholdNotification alert => _AlertTile(
                      text: l10n.alertBudgetThreshold(
                        categories.byId[alert.categoryId]?.name ??
                            l10n.budgetDeletedCategory,
                        alert.thresholdBp ~/ 100,
                        alert.available.format(),
                        DateFormat.MMMd().format(
                          tz.TZDateTime.from(alert.raisedAt, clock.location),
                        ),
                      ),
                      full: alert.thresholdBp >= 10000,
                      read: n.read,
                      onTap: () => onOpen(alert),
                    ),
                    final BillDueNotification due => _AlertTile(
                      text: l10n.alertBillDue(
                        billName(due.name, l10n),
                        DateFormat.MMMd().format(due.dueDate.toDateTime()),
                      ),
                      full: false,
                      read: n.read,
                      onTap: () => onOpenBill(due),
                    ),
                    final WeeklySummaryNotification summary => _AlertTile(
                      text: l10n.alertWeeklySummary,
                      full: false,
                      read: n.read,
                      onTap: () => onOpenSummary(summary),
                    ),
                  },
              ],
            ),
          ),
      ],
    );
  }
}

/// One alert: an icon by threshold, its text (bold while unread) and an unread dot.
class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.text,
    required this.full,
    required this.read,
    required this.onTap,
  });

  final String text;

  /// Whether the threshold was 100 %.
  final bool full;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        full ? Icons.error_outline : Icons.notifications_active_outlined,
        color: full ? colors.error : colors.tertiary,
      ),
      title: Text(
        text,
        style: read ? null : const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: read
          ? null
          : Semantics(
              label: l10n.alertUnread,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 10),
              ),
            ),
      onTap: onTap,
    );
  }
}
