/// A [BudgetRepository] held in memory: what tests use, and the base of the demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Budgets kept in memory for the life of the object; they depend on no other
/// repository, so they keep their own state. Deletes are stamped from the clock. Every
/// write records the budget it changed through [recorder].
base class InMemoryBudgetRepository implements BudgetRepository {
  /// A repository holding [initial], stamping deletes from [_clock] and recording
  /// through [recorder].
  InMemoryBudgetRepository(
    this._clock, {
    required this.recorder,
    List<Budget> initial = const [],
  }) {
    for (final Budget budget in initial) {
      _budgets[budget.id] = (budget: budget, deletedAt: null);
    }
  }

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  final Clock _clock;
  final Map<String, ({Budget budget, DateTime? deletedAt})> _budgets = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Budget> _live() =>
      [
        for (final entry in _budgets.values)
          if (entry.deletedAt == null) entry.budget,
      ]..sort((a, b) {
        final int byCategory = compareBinary(a.categoryId, b.categoryId);
        return byCategory != 0 ? byCategory : compareBinary(a.id, b.id);
      });

  Stream<T> _watch<T>(T Function() read, bool Function(T, T) same) =>
      Stream<T>.multi((controller) {
        controller.add(read());
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(read()),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(same);

  @override
  Stream<List<Budget>> watchAll() => _watch(_live, sameList);

  @override
  Stream<Budget?> watchById(String id) => _watch(() {
    final entry = _budgets[id];
    return entry == null || entry.deletedAt != null ? null : entry.budget;
  }, (a, b) => a == b);

  @override
  Future<void> upsert(Budget budget) async {
    final existing = _budgets[budget.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('budget', budget.id);
    }
    _budgets[budget.id] = (budget: budget, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.budget,
      budget.id,
      existing == null ? null : budgetRecordJson(existing.budget),
      budgetRecordJson(budget),
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = _budgets[id];
    if (existing == null || existing.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    _budgets[id] = (budget: existing.budget, deletedAt: now);
    _changes.add(null);
    await recorder.record(
      EntityType.budget,
      id,
      budgetRecordJson(existing.budget),
      budgetRecordJson(existing.budget, deletedAt: now),
    );
  }

  @override
  Future<void> restore(String id) async {
    final existing = _budgets[id];
    final DateTime? deletedAt = existing?.deletedAt;
    if (existing == null || deletedAt == null) return;
    _budgets[id] = (budget: existing.budget, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.budget,
      id,
      budgetRecordJson(existing.budget, deletedAt: deletedAt),
      budgetRecordJson(existing.budget),
    );
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
