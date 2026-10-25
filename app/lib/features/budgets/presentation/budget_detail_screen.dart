/// A budget's detail, for `/budgets/:id/transactions`: the period selector (the same
/// selection as the Budgets tab's), the budget's card for that period, and the
/// transactions it counts there, newest first; a split counts as its own row, with the
/// split's amount and category. Edit from the app bar.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_card.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_period_selector.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// What budget [budgetId] counts in the selected period.
class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key, required this.budgetId});

  final String budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int offset = ref.watch(budgetPeriodOffsetProvider);
    final List<BudgetStatus>? statuses = ref
        .watch(budgetPeriodStatusesProvider(offset))
        .value;
    final List<BudgetEntry>? entries = ref
        .watch(budgetPeriodEntriesProvider(budgetId, offset))
        .value;
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final LocalDate today = ref.watch(todayProvider);
    if (statuses == null || entries == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final BudgetStatus? status = statuses
        .where((s) => s.budget.id == budgetId)
        .firstOrNull;
    if (status == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.budgetNotFound)),
      );
    }
    final Category? category = categories.byId[status.budget.categoryId];
    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? l10n.budgetDeletedCategory),
        actions: [
          IconButton(
            tooltip: l10n.budgetEditTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => EditBudgetRoute(budgetId).push<void>(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: 2 + (entries.isEmpty ? 1 : entries.length),
        itemBuilder: (context, index) {
          if (index == 0) {
            return BudgetPeriodSelector(
              offset: offset,
              dates: budgetPeriodLabel(l10n, status.period),
              onSelected: ref.read(budgetPeriodOffsetProvider.notifier).select,
            );
          }
          if (index == 1) {
            return BudgetCard(
              status: status,
              category: category,
              groupSize:
                  budgetCategoryIds(
                    status.budget.categoryId,
                    categories,
                  ).length -
                  1,
              offset: offset,
            );
          }
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.budgetTransactionsEmpty,
                textAlign: TextAlign.center,
              ),
            );
          }
          final BudgetEntry entry = entries[index - 2];
          final Transaction t = entry.transaction;
          final TransactionSplit? split = entry.split;
          final String categoryName = split == null
              ? effectiveCategory(t, categories)?.name ?? l10n.uncategorized
              : categories.byId[split.categoryId]?.name ?? l10n.uncategorized;
          return TransactionTile(
            key: ValueKey('${t.id}/${index - 2}'),
            merchant: EnrichedMerchant.resolve(t),
            caption: l10n.captionPair(
              transactionDateLabel(l10n, t.date, today),
              categoryName,
            ),
            amount: split?.amount ?? t.amount,
            pending: t.pending,
            onTap: () => TransactionRoute(t.id).push<void>(context),
          );
        },
      ),
    );
  }
}
