/// The [RuleRepository] of the dev and prod flavors, over the `rules` table
/// (`docs/reference/data.md`).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Rules in [AppDatabase]. Audit fields are stamped from the clock. Every write records
/// each rule it changed through [_recorder] in the same database transaction.
final class DriftRuleRepository implements RuleRepository {
  /// The repository over [_database], stamping writes from [_clock] and recording them
  /// through `recorder`.
  DriftRuleRepository(this._database, this._clock, {required this._recorder});

  final AppDatabase _database;
  final Clock _clock;
  final ChangeRecorder _recorder;

  $RulesTable get _rules => _database.rules;

  @override
  Stream<List<Rule>> watchAll() =>
      (_database.select(_rules)
            ..where((r) => r.deletedAt.isNull())
            ..orderBy([
              (r) => OrderingTerm.asc(r.position),
              (r) => OrderingTerm.asc(r.id),
            ]))
          .watch()
          .map((rows) => rows.map(ruleFromRow).toList())
          .distinct(sameList);

  @override
  Future<void> upsert(Rule rule) => _database.transaction(() async {
    final RuleRow? existing = await _row(rule.id);
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('rule', rule.id);
    }
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_rules)
        .insertOnConflictUpdate(
          ruleCompanion(rule, createdAt: existing?.createdAt ?? now, now: now),
        );
    await _recorder.record(
      EntityType.rule,
      rule.id,
      existing == null ? null : ruleRecordJson(ruleFromRow(existing)),
      ruleRecordJson(rule),
    );
  });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final RuleRow? row = await _row(id);
    if (row == null || row.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    await (_database.update(_rules)..where((r) => r.id.equals(id))).write(
      RulesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    final Rule rule = ruleFromRow(row);
    await _recorder.record(
      EntityType.rule,
      id,
      ruleRecordJson(rule),
      ruleRecordJson(rule, deletedAt: now),
    );
  });

  @override
  Future<void> restore(String id) => _database.transaction(() async {
    final RuleRow? row = await _row(id);
    final DateTime? deletedAt = row?.deletedAt;
    if (row == null || deletedAt == null) return;
    await (_database.update(_rules)..where((r) => r.id.equals(id))).write(
      RulesCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(_clock.nowUtc()),
      ),
    );
    final Rule rule = ruleFromRow(row);
    await _recorder.record(
      EntityType.rule,
      id,
      ruleRecordJson(rule, deletedAt: deletedAt),
      ruleRecordJson(rule),
    );
  });

  @override
  Future<void> reorder(List<String> ids) => _database.transaction(() async {
    final List<Rule> live = await watchAll().first;
    final Map<String, Rule> before = {for (final Rule r in live) r.id: r};
    for (final Rule rule in reordered(live, ids)) {
      final Rule old = before[rule.id]!;
      if (old.position == rule.position) continue;
      await (_database.update(
        _rules,
      )..where((r) => r.id.equals(rule.id))).write(
        RulesCompanion(
          position: Value(rule.position),
          updatedAt: Value(_clock.nowUtc()),
        ),
      );
      await _recorder.record(
        EntityType.rule,
        rule.id,
        ruleRecordJson(old),
        ruleRecordJson(rule),
      );
    }
  });

  Future<RuleRow?> _row(String id) => (_database.select(
    _rules,
  )..where((r) => r.id.equals(id))).getSingleOrNull();
}

/// The row of [rule], stamped [createdAt] and [now]; `deleted_at` is written only when
/// given.
RulesCompanion ruleCompanion(
  Rule rule, {
  required DateTime createdAt,
  required DateTime now,
  Value<DateTime?> deletedAt = const Value.absent(),
}) => RulesCompanion(
  id: Value(rule.id),
  name: Value(rule.name),
  position: Value(rule.position),
  conditions: Value(jsonEncode([for (final c in rule.conditions) c.toJson()])),
  actions: Value(jsonEncode([for (final a in rule.actions) a.toJson()])),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: deletedAt,
);

/// The [Rule] a row holds.
Rule ruleFromRow(RuleRow row) => Rule(
  id: row.id,
  name: row.name,
  position: row.position,
  conditions: [
    for (final Object? c in jsonDecode(row.conditions) as List<Object?>)
      RuleCondition.fromJson(c! as Map<String, dynamic>),
  ],
  actions: [
    for (final Object? a in jsonDecode(row.actions) as List<Object?>)
      RuleAction.fromJson(a! as Map<String, dynamic>),
  ],
);
