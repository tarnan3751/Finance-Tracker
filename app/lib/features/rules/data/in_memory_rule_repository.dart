/// A [RuleRepository] held in memory: what tests use, and the base of the demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Rules kept in memory for the life of the object; they depend on no other repository,
/// so they keep their own state. Deletes are stamped from the clock. Every write records
/// each rule it changed through [recorder].
base class InMemoryRuleRepository implements RuleRepository {
  /// A repository holding [initial], stamping deletes from [_clock] and recording
  /// through [recorder].
  InMemoryRuleRepository(
    this._clock, {
    required this.recorder,
    List<Rule> initial = const [],
  }) {
    for (final Rule rule in initial) {
      _rules[rule.id] = (rule: rule, deletedAt: null);
    }
  }

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  final Clock _clock;
  final Map<String, ({Rule rule, DateTime? deletedAt})> _rules = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Rule> _live() =>
      [
        for (final entry in _rules.values)
          if (entry.deletedAt == null) entry.rule,
      ]..sort((a, b) {
        final int byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : compareBinary(a.id, b.id);
      });

  @override
  Stream<List<Rule>> watchAll() => Stream<List<Rule>>.multi((controller) {
    controller.add(_live());
    final StreamSubscription<void> subscription = _changes.stream.listen(
      (_) => controller.add(_live()),
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  }).distinct(sameList);

  @override
  Future<void> upsert(Rule rule) async {
    final existing = _rules[rule.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('rule', rule.id);
    }
    _rules[rule.id] = (rule: rule, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.rule,
      rule.id,
      existing == null ? null : ruleRecordJson(existing.rule),
      ruleRecordJson(rule),
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = _rules[id];
    if (existing == null || existing.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    _rules[id] = (rule: existing.rule, deletedAt: now);
    _changes.add(null);
    await recorder.record(
      EntityType.rule,
      id,
      ruleRecordJson(existing.rule),
      ruleRecordJson(existing.rule, deletedAt: now),
    );
  }

  @override
  Future<void> restore(String id) async {
    final existing = _rules[id];
    final DateTime? deletedAt = existing?.deletedAt;
    if (existing == null || deletedAt == null) return;
    _rules[id] = (rule: existing.rule, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.rule,
      id,
      ruleRecordJson(existing.rule, deletedAt: deletedAt),
      ruleRecordJson(existing.rule),
    );
  }

  @override
  Future<void> reorder(List<String> ids) async {
    final List<Rule> live = _live();
    final Map<String, Rule> before = {for (final Rule r in live) r.id: r};
    final List<Rule> moved = [
      for (final Rule r in reordered(live, ids))
        if (before[r.id]!.position != r.position) r,
    ];
    if (moved.isEmpty) return;
    for (final Rule r in moved) {
      _rules[r.id] = (rule: r, deletedAt: null);
    }
    _changes.add(null);
    for (final Rule r in moved) {
      await recorder.record(
        EntityType.rule,
        r.id,
        ruleRecordJson(before[r.id]!),
        ruleRecordJson(r),
      );
    }
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
