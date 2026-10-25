/// The [BudgetRepository] of the dev and prod flavors, over the `budgets` table
/// (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Budgets in [AppDatabase]. Audit fields are stamped from the clock. Every write records
/// the budget it changed through [_recorder] in the same database transaction.
final class DriftBudgetRepository implements BudgetRepository {
  /// The repository over [_database], stamping writes from [_clock] and recording them
  /// through `recorder`.
  DriftBudgetRepository(this._database, this._clock, {required this._recorder});

  final AppDatabase _database;
  final Clock _clock;
  final ChangeRecorder _recorder;

  $BudgetsTable get _budgets => _database.budgets;

  @override
  Stream<List<Budget>> watchAll() =>
      (_database.select(_budgets)
            ..where((b) => b.deletedAt.isNull())
            ..orderBy([
              (b) => OrderingTerm.asc(b.categoryId),
              (b) => OrderingTerm.asc(b.id),
            ]))
          .watch()
          .map((rows) => rows.map(budgetFromRow).toList())
          .distinct(sameList);

  @override
  Stream<Budget?> watchById(String id) =>
      (_database.select(_budgets)
            ..where((b) => b.id.equals(id) & b.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row == null ? null : budgetFromRow(row))
          .distinct();

  @override
  Future<void> upsert(Budget budget) => _database.transaction(() async {
    final BudgetRow? existing = await _row(budget.id);
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('budget', budget.id);
    }
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_budgets)
        .insertOnConflictUpdate(
          budgetCompanion(
            budget,
            createdAt: existing?.createdAt ?? now,
            now: now,
          ),
        );
    await _recorder.record(
      EntityType.budget,
      budget.id,
      existing == null ? null : budgetRecordJson(budgetFromRow(existing)),
      budgetRecordJson(budget),
    );
  });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final BudgetRow? row = await _row(id);
    if (row == null || row.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    await (_database.update(_budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    final Budget budget = budgetFromRow(row);
    await _recorder.record(
      EntityType.budget,
      id,
      budgetRecordJson(budget),
      budgetRecordJson(budget, deletedAt: now),
    );
  });

  @override
  Future<void> restore(String id) => _database.transaction(() async {
    final BudgetRow? row = await _row(id);
    final DateTime? deletedAt = row?.deletedAt;
    if (row == null || deletedAt == null) return;
    await (_database.update(_budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(_clock.nowUtc()),
      ),
    );
    final Budget budget = budgetFromRow(row);
    await _recorder.record(
      EntityType.budget,
      id,
      budgetRecordJson(budget, deletedAt: deletedAt),
      budgetRecordJson(budget),
    );
  });

  Future<BudgetRow?> _row(String id) => (_database.select(
    _budgets,
  )..where((b) => b.id.equals(id))).getSingleOrNull();
}

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
