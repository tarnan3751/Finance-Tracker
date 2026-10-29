/// A goal's progress, suggestion and status (`PLAN.md` §12 "Goals";
/// `docs/reference/goals.md`, **The math**). Pure Dart, in integer minor units.
///
/// - **Progress**: a balance goal's is the sum of its linked accounts' balances in the
///   target's currency (the caller gives the balances; other currencies are left out);
///   a contribution goal's the sum of its live contributions in that currency.
/// - **Remaining**: the target less the progress, never below zero.
/// - **Months left**: the whole months from today to the target date (the most months
///   whose step from today, clamped to short months, is on or before it), at least one
///   when the date is after today; none when it is today, past or absent.
/// - **Suggestion**: the remaining amount over the months left, rounded up to the minor
///   unit; none when no months are left or nothing remains.
/// - **Status**: done when the progress reached the target; else, with a target date,
///   on track when the progress is at least the linear plan's amount for today (the
///   target times the days from the creation day to today over the days to the target
///   date, rounded down, the whole target from the target date on), behind by the
///   difference otherwise; open (no status) without a target date.
library;

import 'package:shared_models/shared_models.dart';

/// Where a goal stands.
sealed class GoalStatus {
  const GoalStatus();
}

/// The progress reached the target.
final class GoalDone extends GoalStatus {
  /// The status.
  const GoalDone();
}

/// The progress is at least the plan's amount for today.
final class GoalOnTrack extends GoalStatus {
  /// The status.
  const GoalOnTrack();
}

/// The progress is [shortfall] below the plan's amount for today.
final class GoalBehind extends GoalStatus {
  /// The status, [shortfall] behind the plan.
  const GoalBehind(this.shortfall);

  /// How far below the plan the progress is.
  final Money shortfall;

  @override
  bool operator ==(Object other) =>
      other is GoalBehind && other.shortfall == shortfall;

  @override
  int get hashCode => shortfall.hashCode;
}

/// The goal has no target date, so no plan to be on or behind.
final class GoalOpen extends GoalStatus {
  /// The status.
  const GoalOpen();
}

/// The sum of [contributions] in [currencyCode]; the others are left out.
Money contributionProgress(
  Iterable<GoalContribution> contributions,
  String currencyCode,
) => Money.sum([
  for (final GoalContribution c in contributions)
    if (c.amount.currencyCode == currencyCode) c.amount,
], currencyCode: currencyCode);

/// What is left to reach [target] from [progress], never below zero.
Money remainingFor(Money target, Money progress) =>
    Money.max(target - progress, Money.zero(target.currencyCode));

/// The whole months from [today] to [targetDate]: at least one when it is after
/// [today], null when it is [today], before it, or null.
int? monthsLeft(LocalDate today, LocalDate? targetDate) {
  if (targetDate == null || !targetDate.isAfter(today)) return null;
  int months = 0;
  while (!today.addMonths(months + 1).isAfter(targetDate)) {
    months++;
  }
  return months < 1 ? 1 : months;
}

/// The monthly amount that reaches [target] from [progress] by [targetDate], rounded up
/// to the minor unit; null without months left or when nothing remains.
Money? suggestedMonthly(
  Money target,
  Money progress,
  LocalDate today,
  LocalDate? targetDate,
) {
  final int? months = monthsLeft(today, targetDate);
  final Money remaining = remainingFor(target, progress);
  if (months == null || remaining.isZero) return null;
  return remaining.multipliedBy(1, months, mode: RoundingMode.ceiling);
}

/// The linear plan's amount for [today], from zero on [createdOn] to [target] on
/// [targetDate], rounded down; the whole target on and after [targetDate], zero before
/// [createdOn].
Money expectedProgress(
  Money target,
  LocalDate createdOn,
  LocalDate targetDate,
  LocalDate today,
) {
  final int total = createdOn.daysUntil(targetDate);
  if (total <= 0 || !today.isBefore(targetDate)) return target;
  final int elapsed = createdOn.daysUntil(today);
  if (elapsed <= 0) return Money.zero(target.currencyCode);
  return target.multipliedBy(elapsed, total, mode: RoundingMode.floor);
}

/// Where [goal] stands on [today] with [progress].
GoalStatus goalStatus(Goal goal, Money progress, LocalDate today) {
  if (progress >= goal.target) return const GoalDone();
  final LocalDate? targetDate = goal.targetDate;
  if (targetDate == null) return const GoalOpen();
  final Money expected = expectedProgress(
    goal.target,
    goal.createdOn,
    targetDate,
    today,
  );
  return progress >= expected
      ? const GoalOnTrack()
      : GoalBehind(expected - progress);
}
