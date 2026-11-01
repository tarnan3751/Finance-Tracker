/// The goals (`docs/reference/goals.md`, **Screens**), at `/goals`, the Insights tab's
/// Goals segment (an `InsightsScaffold`): the hero card (what is saved toward the goals
/// not archived, per currency, captioned by how many are on track), a card per live goal
/// (`goal_card.dart`), then a folded "Archived" section of the archived ones; an empty
/// state with New goal when there are none. Tapping a goal opens its detail; the app bar's
/// action opens a new goal.
library;

import 'package:finance_tracker/core/router/insights_scaffold.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/core/widgets/hero_card.dart';
import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/goals/domain/goal_math.dart';
import 'package:finance_tracker/features/goals/presentation/goal_card.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The goals screen.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<GoalView>> views = ref.watch(goalViewsProvider);
    void create() => const NewGoalRoute().push<void>(context);
    return InsightsScaffold(
      segment: InsightsSegment.goals,
      actions: [
        IconButton(
          tooltip: l10n.goalsNew,
          icon: const Icon(Icons.add),
          onPressed: create,
        ),
      ],
      body: switch (views.value) {
        null when views.hasError => Center(child: Text(l10n.loadFailed)),
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(
          icon: Icons.savings_outlined,
          headline: l10n.goalsEmptyTitle,
          body: l10n.goalsEmptyBody,
          action: FilledButton.icon(
            onPressed: create,
            icon: const Icon(Icons.add),
            label: Text(l10n.goalsNew),
          ),
        ),
        final List<GoalView> list => _GoalList(views: list),
      },
    );
  }
}

class _GoalList extends StatelessWidget {
  const _GoalList({required this.views});

  final List<GoalView> views;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<GoalView> archived = [
      for (final GoalView v in views)
        if (v.archived) v,
    ];
    final List<GoalView> live = [
      for (final GoalView v in views)
        if (!v.archived) v,
    ];
    Widget card(GoalView v) => GoalCard(
      key: ValueKey(v.goal.id),
      view: v,
      onTap: () => GoalDetailRoute(v.goal.id).push<void>(context),
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (live.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(SpendthriftTokens.space16),
            child: GoalsHero(live),
          ),
        for (final GoalView v in live) card(v),
        if (archived.isNotEmpty)
          ExpansionTile(
            title: Text(l10n.goalsArchived(archived.length)),
            children: [for (final GoalView v in archived) card(v)],
          ),
      ],
    );
  }
}

/// The Goals segment's hero card: what is saved toward [views] (the goals not archived),
/// one figure per currency, captioned by how many of them are on track or done.
class GoalsHero extends StatelessWidget {
  const GoalsHero(this.views, {super.key});

  final List<GoalView> views;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, Money> saved = {};
    for (final GoalView v in views) {
      final String code = v.progress.currencyCode;
      saved[code] = (saved[code] ?? Money.zero(code)) + v.progress;
    }
    final List<Money> totals = [
      for (final String code in saved.keys.toList()..sort()) saved[code]!,
    ];
    final int onTrack = views
        .where((v) => v.status is GoalOnTrack || v.status is GoalDone)
        .length;
    final String label = l10n.goalsHeroLabel;
    final String caption = l10n.goalsHeroOnTrack(onTrack, views.length);
    return HeroCard(
      label: label,
      figure: HeroAmounts(totals),
      caption: caption,
      semanticsLabel: heroSentence(
        l10n,
        label,
        spokenAmounts(l10n, totals),
        caption,
      ),
    );
  }
}
