/// The Plan tab's Budgets segment (`PlanScaffold`): the period selector, the hero card
/// (what the period's budgets spent, of what they make available, with a bar under it;
/// pink when over), then one card
/// per budget in the selected period, by category name (`budget_card.dart`); tap a card
/// for what it counts. When every budget starts its periods on the same day the selector
/// shows the period's dates, else each card shows its own. "Add budget" opens the editor;
/// the bell opens the alerts (`budget_alerts.dart`).
library;

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/core/router/plan_scaffold.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/core/widgets/hero_card.dart';
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
import 'package:shared_models/shared_models.dart';

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
        BudgetsHero(statuses),
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

/// The Budgets segment's hero card: what [statuses] spent, of what they make available
/// (the amounts and what carried in), one figure per currency; a bar under it when the
/// budgets share one currency; a currency's figure pink when it is over, and the bar pink
/// when its one currency is.
class BudgetsHero extends StatelessWidget {
  const BudgetsHero(this.statuses, {super.key});

  final List<BudgetStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, Money> spent = {};
    final Map<String, Money> available = {};
    for (final BudgetStatus s in statuses) {
      final String code = s.spent.currencyCode;
      spent[code] = (spent[code] ?? Money.zero(code)) + s.spent;
      available[code] = (available[code] ?? Money.zero(code)) + s.available;
    }
    final List<String> codes = spent.keys.toList()..sort();
    final bool over = codes.any((c) => spent[c]! > available[c]!);
    final String label = l10n.budgetsHeroLabel;
    final String caption = l10n.budgetsHeroCaption(
      listLine(l10n, [for (final String c in codes) available[c]!.format()]),
    );
    final Money? total = codes.length == 1 ? available[codes.single] : null;
    return Padding(
      padding: const EdgeInsets.all(SpendthriftTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroCard(
            label: label,
            figure: HeroAmounts(
              [for (final String c in codes) spent[c]!],
              tones: [
                for (final String c in codes)
                  spent[c]! > available[c]! ? HeroTone.outflow : HeroTone.plain,
              ],
            ),
            caption: caption,
            semanticsLabel: heroSentence(
              l10n,
              label,
              spokenAmounts(l10n, [for (final String c in codes) spent[c]!]),
              l10n.budgetsHeroCaption(
                spokenAmounts(l10n, [
                  for (final String c in codes) available[c]!,
                ]),
              ),
            ),
          ),
          if (total != null) ...[
            const SizedBox(height: SpendthriftTokens.space12),
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: _fill(spent[codes.single]!, total),
                color: over ? FinanceColors.of(context).outflow : null,
                minHeight: SpendthriftTokens.space8,
                borderRadius: BorderRadius.circular(
                  SpendthriftTokens.barTopRadius,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// [spent] as a fraction of [total], for drawing only (the share is worked in basis
  /// points of integer minor units): full when over, or when something was spent with
  /// nothing available.
  static double _fill(Money spent, Money total) {
    if (!total.isPositive) return spent.isPositive ? 1 : 0;
    if (!spent.isPositive) return 0;
    if (spent >= total) return 1;
    final int basisPoints = spent
        .multipliedBy(10000, total.minorUnits, mode: RoundingMode.down)
        .minorUnits;
    return basisPoints / 10000;
  }
}
