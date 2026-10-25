/// Budget alerts (`docs/reference/budgets.md`, **Alerts**; `PLAN.md` §12, "Budget
/// semantics (4a)"): each threshold a budget's spending reaches in a period is raised
/// once on this device, recorded in the [BudgetAlertStore], and told to the user through
/// the [Notifier]. When one change reaches both thresholds, both are recorded and only
/// the higher is told.
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/domain/budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('budgets');

/// Raises the new alerts of budget statuses.
final class BudgetAlertEvaluator {
  /// An evaluator recording in [_store], telling [_notifier], stamping from [_clock].
  BudgetAlertEvaluator(this._store, this._notifier, this._clock);

  final BudgetAlertStore _store;
  final Notifier _notifier;
  final Clock _clock;
  Future<void> _last = Future<void>.value();

  /// Records each threshold [statuses] have reached that this device has not raised for
  /// that budget and period, and notifies the highest new one per budget. Evaluations
  /// run one at a time, in call order. Never throws: a failure is logged by type.
  Future<void> evaluate(List<BudgetStatus> statuses) =>
      _last = _last.then((_) => _evaluate(statuses));

  Future<void> _evaluate(List<BudgetStatus> statuses) async {
    try {
      final DateTime now = _clock.nowUtc();
      for (final BudgetStatus status in statuses) {
        int? highest;
        for (final int bp in status.thresholdsCrossed) {
          if (await _store.markRaised(
            status.budget.id,
            status.period.start,
            bp,
            now,
          )) {
            highest = bp;
          }
        }
        if (highest == null) continue;
        await _notifier.notify(
          BudgetThresholdNotification(
            budgetId: status.budget.id,
            categoryId: status.budget.categoryId,
            periodStart: status.period.start,
            thresholdBp: highest,
            spent: status.spent,
            available: status.available,
            raisedAt: now,
          ),
        );
      }
    } on Object catch (e) {
      _log.warning('budget alerts not evaluated: ${e.runtimeType}');
    }
  }
}
