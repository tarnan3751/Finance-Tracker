/// A goal's detail (`docs/reference/goals.md`, **Screens**), at `/goals/:id`: its
/// summary (`goal_card.dart`) and note; for a balance goal, the accounts it counts with
/// the balance each is shown with (reported, or from transactions) and those it leaves
/// out for their currency; for a contribution goal, its contributions newest first (one
/// in another currency marked as not counted), each with Delete and an undo, and Add
/// contribution. The app bar opens the editor.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/goals/presentation/goal_card.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The detail of goal [goalId].
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<GoalView?> view = ref.watch(goalViewByIdProvider(goalId));
    return switch (view.value) {
      null when view.hasError => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.loadFailed)),
      ),
      null when view.isLoading => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      null => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.goalNotFound)),
      ),
      final GoalView v => _GoalDetail(view: v),
    };
  }
}

class _GoalDetail extends ConsumerWidget {
  const _GoalDetail({required this.view});

  final GoalView view;

  Future<void> _deleteContribution(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoalActions actions = ref.read(goalActionsProvider);
    await actions.deleteContribution(id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.contributionDeleted),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => actions.restoreContribution(id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Goal goal = view.goal;
    final String? note = goal.note;
    final bool contributions = goal.kind == GoalKind.contribution;
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Semantics(
        header: true,
        child: Text(text, style: theme.textTheme.titleSmall),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
        actions: [
          IconButton(
            tooltip: l10n.goalEditTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => EditGoalRoute(goal.id).push<void>(context),
          ),
        ],
      ),
      floatingActionButton: contributions
          ? FloatingActionButton.extended(
              onPressed: () =>
                  NewContributionRoute(goal.id).push<void>(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.goalAddContribution),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MergeSemantics(
              child: GoalSummary(view: view, showName: false),
            ),
          ),
          if (note != null && note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(note, style: theme.textTheme.bodyMedium),
            ),
          if (!contributions) ...[
            heading(l10n.goalCountedAccounts),
            for (final a in view.accounts)
              ListTile(
                key: ValueKey('account/${a.account.id}'),
                title: Text(a.account.name),
                subtitle: Text(
                  a.balance.reported
                      ? l10n.balanceReported
                      : l10n.balanceFromTransactions,
                ),
                trailing: Text(
                  a.balance.amount.format(),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            if (view.otherCurrencyAccounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  l10n.goalNotCounted(
                    view.otherCurrencyAccounts.map((a) => a.name).join(', '),
                  ),
                  style: caption,
                ),
              ),
          ] else ...[
            heading(l10n.goalContributions),
            if (view.contributions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.goalNoContributions, style: caption),
              ),
            for (final GoalContribution c in view.contributions.reversed)
              ListTile(
                key: ValueKey('contribution/${c.id}'),
                title: Text(c.amount.format()),
                subtitle: Text(
                  [
                    shortDateLabel(c.date),
                    ?c.note,
                    if (c.amount.currencyCode != goal.target.currencyCode)
                      l10n.contributionNotCounted(c.amount.currencyCode),
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: l10n.contributionDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteContribution(context, ref, c.id),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
