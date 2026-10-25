/// How a rule is stored in the `rules` table (`docs/reference/data.md`): the row of a rule
/// and the rule of a row, shared by the repository and the sync store.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:shared_models/shared_models.dart';

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
