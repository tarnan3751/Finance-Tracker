/// What the goal screens show and do: each goal with its contributions, progress,
/// suggestion and status (`GoalView`, from `domain/goal_math.dart`), and the writes
/// (`docs/reference/goals.md`).
///
/// A balance goal's progress is its linked accounts' balances as the accounts screens
/// show them (`shownBalance`: reported by the institution, else derived from
/// transactions); the linked accounts in another currency than the target are left out
/// and listed, and a linked account that no longer exists is left out. A contribution
/// goal's contributions in another currency are left out of its progress and listed too.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/goals/domain/goal_math.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'goals_providers.g.dart';

/// A goal as the screens show it on one day.
final class GoalView {
  /// The view of [goal].
  const GoalView({
    required this.goal,
    required this.contributions,
    required this.progress,
    required this.accounts,
    required this.otherCurrencyAccounts,
    required this.otherCurrencyContributions,
    required this.remaining,
    required this.monthsLeft,
    required this.suggestion,
    required this.status,
  });

  /// The goal.
  final Goal goal;

  /// Its live contributions, by date, then by id.
  final List<GoalContribution> contributions;

  /// How far it has come, in the target's currency.
  final Money progress;

  /// The linked accounts that count toward a balance goal, with the balance each is
  /// shown with; empty for a contribution goal.
  final List<({Account account, ShownBalance balance})> accounts;

  /// The linked accounts left out because they are in another currency.
  final List<Account> otherCurrencyAccounts;

  /// The contributions left out of the progress because they are in another currency
  /// (another device's, recorded before a currency change); empty for a balance goal.
  final List<GoalContribution> otherCurrencyContributions;

  /// What is left to reach the target, never below zero.
  final Money remaining;

  /// The whole months to the target date, or null (`monthsLeft`).
  final int? monthsLeft;

  /// The suggested monthly amount, or null (`suggestedMonthly`).
  final Money? suggestion;

  /// Where it stands.
  final GoalStatus status;

  /// Whether it is archived.
  bool get archived => goal.archivedAt != null;
}

/// [entry] as the screens show it on [today], over the live [accounts] by id and their
/// [derived] balances.
GoalView goalView(
  GoalEntry entry,
  Map<String, Account> accounts,
  Map<String, Money?> derived,
  LocalDate today,
) {
  final Goal goal = entry.goal;
  final String currency = goal.target.currencyCode;
  final List<({Account account, ShownBalance balance})> counted = [];
  final List<Account> other = [];
  if (goal.kind == GoalKind.balance) {
    for (final String id in goal.linkedAccountIds) {
      final Account? account = accounts[id];
      if (account == null) continue;
      if (account.currencyCode != currency) {
        other.add(account);
      } else {
        counted.add((
          account: account,
          balance: shownBalance(account, derived),
        ));
      }
    }
  }
  final Money progress = switch (goal.kind) {
    GoalKind.balance => Money.sum([
      for (final a in counted) a.balance.amount,
    ], currencyCode: currency),
    GoalKind.contribution => contributionProgress(
      entry.contributions,
      currency,
    ),
  };
  return GoalView(
    goal: goal,
    contributions: entry.contributions,
    progress: progress,
    accounts: counted,
    otherCurrencyAccounts: other,
    otherCurrencyContributions: goal.kind == GoalKind.contribution
        ? [
            for (final GoalContribution c in entry.contributions)
              if (c.amount.currencyCode != currency) c,
          ]
        : const [],
    remaining: remainingFor(goal.target, progress),
    monthsLeft: monthsLeft(today, goal.targetDate),
    suggestion: suggestedMonthly(goal.target, progress, today, goal.targetDate),
    status: goalStatus(goal, progress, today),
  );
}

/// The live goals with their contributions, by creation day, then id.
@riverpod
Stream<List<GoalEntry>> goalEntries(Ref ref) =>
    ref.watch(goalRepositoryProvider).watchAll();

/// Every live goal as the screens show it today, archived ones included, in
/// [goalEntries]' order; recomputed when the goals, the accounts, their balances or
/// today change.
@riverpod
Future<List<GoalView>> goalViews(Ref ref) async {
  final List<GoalEntry> entries = await ref.watch(goalEntriesProvider.future);
  final List<Account> accounts = await ref.watch(accountsProvider.future);
  final Map<String, Money?> derived = await ref.watch(
    derivedBalancesProvider.future,
  );
  final LocalDate today = ref.watch(todayProvider);
  final Map<String, Account> byId = {for (final Account a in accounts) a.id: a};
  return [
    for (final GoalEntry entry in entries)
      goalView(entry, byId, derived, today),
  ];
}

/// Live goal [id] as the screens show it today, or null when there is none.
@riverpod
Future<GoalView?> goalViewById(Ref ref, String id) async {
  for (final GoalView view in await ref.watch(goalViewsProvider.future)) {
    if (view.goal.id == id) return view;
  }
  return null;
}

/// The goal actions.
@riverpod
GoalActions goalActions(Ref ref) =>
    GoalActions(ref.watch(goalRepositoryProvider));

/// Writes goals to a [GoalRepository]; it holds the repository, not a ref, so an action
/// begun on a screen finishes after the screen is gone (a delete navigates away first).
final class GoalActions {
  GoalActions(this._goals);

  final GoalRepository _goals;

  /// Stores new [goal].
  Future<void> create(Goal goal) => _goals.create(goal);

  /// Saves the edits of [goal].
  Future<void> update(Goal goal) => _goals.update(goal);

  /// Archives goal [id] ([archived] true) or brings it back.
  Future<void> setArchived(String id, {required bool archived}) =>
      _goals.setArchived(id, archived: archived);

  /// Deletes goal [id]; [restore] undoes it.
  Future<void> delete(String id) => _goals.delete(id);

  /// Restores deleted goal [id].
  Future<void> restore(String id) => _goals.restore(id);

  /// Adds [contribution].
  Future<void> addContribution(GoalContribution contribution) =>
      _goals.addContribution(contribution);

  /// Deletes contribution [id]; [restoreContribution] undoes it.
  Future<void> deleteContribution(String id) => _goals.deleteContribution(id);

  /// Restores deleted contribution [id].
  Future<void> restoreContribution(String id) => _goals.restoreContribution(id);
}
