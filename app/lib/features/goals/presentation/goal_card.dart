/// A goal as a card (`docs/reference/goals.md`, **Screens**): its name and target date,
/// a progress bar with the progress of the target, the status ("On track", "Behind by
/// $150.00" in the error colour, "Done"; none without a target date) and the suggestion
/// ("Set aside $175.00 a month"). The goals list shows one per goal; the detail shows
/// the same summary at its top ([GoalSummary]). A card reads as one sentence, each part
/// once: "Holiday, By Apr 24, 2027, 41 percent of the target, $750.00 of $1,800.00,
/// Behind by $152.46, Set aside $175.00 a month".
library;

import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/goals/domain/goal_math.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// [view]'s card, opening [onTap].
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.view, this.onTap});

  final GoalView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    clipBehavior: Clip.antiAlias,
    child: MergeSemantics(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GoalSummary(view: view),
        ),
      ),
    ),
  );
}

/// [view]'s name, target date, progress, status and suggestion.
class GoalSummary extends StatelessWidget {
  const GoalSummary({super.key, required this.view, this.showName = true});

  final GoalView view;

  /// Whether the name heads the summary (the detail has it in its app bar).
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final Goal goal = view.goal;
    final LocalDate? targetDate = goal.targetDate;
    final GoalStatus status = view.status;
    final Money? suggestion = view.suggestion;
    final String? statusText = switch (status) {
      GoalDone() => l10n.goalDone,
      GoalOnTrack() => l10n.goalOnTrack,
      GoalBehind(:final Money shortfall) => l10n.goalBehind(shortfall.format()),
      GoalOpen() => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showName) Text(goal.name, style: theme.textTheme.titleMedium),
        if (targetDate != null)
          Text(
            l10n.goalTargetDateCaption(shortDateLabel(targetDate)),
            style: caption,
          ),
        const SizedBox(height: 12),
        GoalProgressBar(view: view),
        const SizedBox(height: 8),
        Text(
          l10n.goalProgressOf(view.progress.format(), goal.target.format()),
          style: theme.textTheme.bodyLarge,
        ),
        if (statusText != null) ...[
          const SizedBox(height: 4),
          Text(
            statusText,
            style: theme.textTheme.labelLarge?.copyWith(
              color: switch (status) {
                GoalBehind() => colors.error,
                GoalDone() => colors.primary,
                _ => null,
              },
            ),
          ),
        ],
        if (suggestion != null) ...[
          const SizedBox(height: 4),
          Text(l10n.goalSuggestion(suggestion.format()), style: caption),
        ],
      ],
    );
  }
}

/// The share of [target] that [progress] is, in whole percent, never below zero.
int goalPercent(Money progress, Money target) {
  if (!target.isPositive) return progress.isPositive ? 100 : 0;
  if (progress.isNegative) return 0;
  return progress.minorUnits * 100 ~/ target.minorUnits;
}

/// [view]'s progress bar, read as "36 percent of the target": the name and the amounts
/// beside it are read once, from their own text, in the card's merged label. The bar's
/// fill is a fraction for drawing only.
class GoalProgressBar extends StatelessWidget {
  const GoalProgressBar({super.key, required this.view});

  final GoalView view;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Goal goal = view.goal;
    final int percent = goalPercent(view.progress, goal.target);
    return Semantics(
      label: l10n.goalProgressPercent(percent),
      excludeSemantics: true,
      child: LinearProgressIndicator(
        value: percent.clamp(0, 100) / 100,
        color: view.status is GoalBehind ? colors.error : colors.primary,
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
