/// The budgets' rows in the `budgets` table (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// The row of [budget], stamped [createdAt] and [now]; `deleted_at` is written only when
/// given. The amount is stored as `amount_minor` in the row's `currency`.
BudgetsCompanion budgetCompanion(
  Budget budget, {
  required DateTime createdAt,
  required DateTime now,
  Value<DateTime?> deletedAt = const Value.absent(),
}) => BudgetsCompanion(
  id: Value(budget.id),
  categoryId: Value(budget.categoryId),
  period: Value(budget.period),
  periodStartDay: Value(budget.periodStartDay),
  amountMinor: Value(minorUnitsIn(budget.amount, budget.amount.currencyCode)!),
  currency: Value(budget.amount.currencyCode),
  rollover: Value(budget.rollover),
  startDate: Value(budget.startDate),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: deletedAt,
);

/// The [Budget] a row holds.
Budget budgetFromRow(BudgetRow row) => Budget(
  id: row.id,
  categoryId: row.categoryId,
  period: row.period,
  periodStartDay: row.periodStartDay,
  amount: Money(row.amountMinor, row.currency),
  rollover: row.rollover,
  startDate: row.startDate,
);
