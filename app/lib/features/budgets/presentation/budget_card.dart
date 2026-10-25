/// One budget in a period, as a card: its category's icon and name (and how many
/// categories its group includes, when it budgets a parent), the amount with what
/// carried in, then by period:
///
/// - **current**: a progress bar with the percent spent ("Nothing available" when
///   nothing is), styled as over past 100 %; spent and left (or over); the projection
///   to the period's end, in the error colour when it ends above what is available;
/// - **past**: the same without the projection;
/// - **future**: what will be available, with no spending.
///
/// A badge under the name names the highest alert threshold reached in the period. Built from plain
/// values; the screen computes the status (`budget_math.dart`).
library;

import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// [status]'s card, [offset] periods from the current one.
class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.status,
    required this.category,
    required this.groupSize,
    required this.offset,
    this.period,
    this.onTap,
  });

  final BudgetStatus status;

  /// The budget's category, or null when it has been deleted.
  final Category? category;

  /// How many categories are under [category] (0 when it has none).
  final int groupSize;

  /// Which period [status] is of: 0 the current one, negative a past one, positive a
  /// future one.
  final int offset;

  /// The period's dates, shown under the name when given.
  final String? period;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final Category? category = this.category;
    final String name = category?.name ?? l10n.budgetDeletedCategory;
    final Budget budget = status.budget;
    final Money carried = status.carried;
    final String amount = !budget.rollover || carried.isZero
        ? budget.amount.format()
        : carried.isNegative
        ? l10n.budgetAmountDeficit(budget.amount.format(), (-carried).format())
        : l10n.budgetAmountCarried(budget.amount.format(), carried.format());
    final int? threshold = offset > 0
        ? null
        : status.thresholdsCrossed.lastOrNull;
    final String? period = this.period;
    return Card.outlined(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      category == null
                          ? fallbackCategoryIcon
                          : categoryIconFor(category.icon),
                      color: category == null
                          ? colors.outline
                          : categoryColor(context, category.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: theme.textTheme.titleMedium),
                          if (groupSize > 0)
                            Text(
                              l10n.budgetGroupIncludes(groupSize),
                              style: caption,
                            ),
                          if (period != null) Text(period, style: caption),
                          if (threshold != null) ...[
                            const SizedBox(height: 4),
                            _ThresholdBadge(threshold),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(amount, style: theme.textTheme.bodyLarge),
                if (offset > 0)
                  Text(
                    l10n.budgetAvailable(status.available.format()),
                    style: caption,
                  )
                else ...[
                  const SizedBox(height: 8),
                  _Progress(status: status, name: name),
                  const SizedBox(height: 8),
                  _SpentAndLeft(status),
                  if (offset == 0) ...[
                    const SizedBox(height: 4),
                    _Projection(status),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The progress bar and the percent beside it, read as one sentence.
class _Progress extends StatelessWidget {
  const _Progress({required this.status, required this.name});

  final BudgetStatus status;
  final String name;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int? basisPoints = status.progress.percentBasisPoints;
    final bool over = basisPoints == null || status.remaining.isNegative;
    final Color color = over ? colors.error : colors.primary;
    final String label = switch (basisPoints) {
      null => l10n.budgetProgressNothingSemantics(name, status.spent.format()),
      _ when status.remaining.isNegative => l10n.budgetProgressOverSemantics(
        name,
        basisPoints ~/ 100,
        status.available.format(),
        (-status.remaining).format(),
      ),
      _ => l10n.budgetProgressSemantics(
        name,
        basisPoints ~/ 100,
        status.available.format(),
        status.remaining.format(),
      ),
    };
    // The bar's fill, as a fraction of what is available: full when over or when
    // something was spent with nothing available.
    final double fill = basisPoints == null
        ? (status.spent.isPositive ? 1 : 0)
        : basisPoints.clamp(0, 10000) / 10000;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: fill,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              basisPoints == null
                  ? l10n.budgetNothingAvailable
                  : l10n.budgetPercent(basisPoints ~/ 100),
              style: theme.textTheme.labelLarge?.copyWith(
                color: over ? colors.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What was spent, and what is left or how far over.
class _SpentAndLeft extends StatelessWidget {
  const _SpentAndLeft(this.status);

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Money remaining = status.remaining;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      children: [
        Text(
          l10n.budgetSpent(status.spent.format()),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          remaining.isNegative
              ? l10n.budgetOver((-remaining).format())
              : l10n.budgetLeft(remaining.format()),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: remaining.isNegative ? theme.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}

/// Where spending is heading by the end of the period.
class _Projection extends StatelessWidget {
  const _Projection(this.status);

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool over = status.projectedOverspend;
    final Color color = over
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          over ? Icons.warning_amber : Icons.trending_flat,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            over
                ? l10n.budgetProjectedOver(
                    (status.projected - status.available).format(),
                  )
                : l10n.budgetOnPace(status.projected.format()),
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// The highest alert threshold reached, as a small label.
class _ThresholdBadge extends StatelessWidget {
  const _ThresholdBadge(this.basisPoints);

  final int basisPoints;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool full = basisPoints >= 10000;
    final Color background = full
        ? colors.errorContainer
        : colors.tertiaryContainer;
    final Color foreground = full
        ? colors.onErrorContainer
        : colors.onTertiaryContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active, size: 16, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.budgetThresholdReached(basisPoints ~/ 100),
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
