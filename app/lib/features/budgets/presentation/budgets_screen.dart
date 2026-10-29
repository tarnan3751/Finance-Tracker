/// The Plan tab's Budgets segment (`PlanScaffold`): the period selector, then one card
/// per budget in the selected period, by category name (`budget_card.dart`); tap a card
/// for what it counts. When every budget starts its periods on the same day the selector
/// shows the period's dates, else each card shows its own. "Add budget" opens the editor;
/// the bell opens the alerts (`budget_alerts.dart`).
library;

import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_alerts.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_card.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_period_selector.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The list of budgets.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int offset = ref.watch(budgetPeriodOffsetProvider);
    final AsyncValue<List<BudgetStatus>> statuses = ref.watch(
      budgetPeriodStatusesProvider(offset),
    );
    final List<BudgetStatus>? list = statuses.value;
    return PlanScaffold(
      segment: PlanSegment.budgets,
      actions: const [BudgetAlertsButton()],
      floatingActionButton: list == null || list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => const NewBudgetRoute().push<void>(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.budgetAdd),
            ),
      body: switch (list) {
        null when statuses.hasError => Center(child: Text(l10n.loadFailed)),
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          headline: l10n.budgetsEmptyHeadline,
          body: l10n.budgetsEmptyBody,
          action: FilledButton.icon(
            onPressed: () => const NewBudgetRoute().push<void>(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.budgetAdd),
          ),
        ),
        final List<BudgetStatus> list => _BudgetList(list, offset: offset),
      },
    );
  }
}

class _BudgetList extends ConsumerWidget {
  const _BudgetList(this.statuses, {required this.offset});

  final List<BudgetStatus> statuses;
  final int offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    String name(BudgetStatus s) =>
        categories.byId[s.budget.categoryId]?.name ??
        l10n.budgetDeletedCategory;
    final List<BudgetStatus> sorted = [...statuses]
      ..sort((a, b) {
        final int byName = name(a)
            .toLowerCase()
            .compareTo(name(b).toLowerCase());
        return byName != 0 ? byName : a.budget.id.compareTo(b.budget.id);
      });
    final bool oneStartDay =
        statuses.map((s) => s.budget.periodStartDay).toSet().length == 1;
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        BudgetPeriodSelector(
          offset: offset,
          dates: oneStartDay
              ? budgetPeriodLabel(l10n, statuses.first.period)
              : null,
          onSelected: ref.read(budgetPeriodOffsetProvider.notifier).select,
        ),
        for (final BudgetStatus s in sorted)
          BudgetCard(
            key: ValueKey(s.budget.id),
            status: s,
            category: categories.byId[s.budget.categoryId],
            groupSize:
                budgetCategoryIds(s.budget.categoryId, categories).length - 1,
            offset: offset,
            period: oneStartDay ? null : budgetPeriodLabel(l10n, s.period),
            onTap: () =>
                BudgetTransactionsRoute(s.budget.id).push<void>(context),
          ),
      ],
    );
  }
}
