/// The user's rules (`docs/reference/rules.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// two rules of the persona it shows); all pass `test/contract/rule_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads and writes rules. Every stream starts with the current value and emits again
/// only when that value changes. Deletes are soft; [restore] is the only way back.
abstract interface class RuleRepository {
  /// The live rules, by `position`, then by id: the order they are applied in.
  Stream<List<Rule>> watchAll();

  /// Inserts or replaces [rule]. Throws `EntityDeletedException`
  /// (`core/db/database_exceptions.dart`) when the rule is deleted.
  Future<void> upsert(Rule rule);

  /// Soft-deletes rule [id]; does nothing when there is no such live rule.
  Future<void> delete(String id);

  /// Restores deleted rule [id]; does nothing when there is no such deleted rule.
  Future<void> restore(String id);

  /// Gives the live rules [ids] the positions 0, 1, 2… in that order, and the live rules
  /// not among them the next positions, in their current order. Ids of rules that are not
  /// live, and repeats, are ignored, so a list read before another device's change still
  /// applies. Only the rules whose position changes are written.
  Future<void> reorder(List<String> ids);
}

/// The order [reorder] gives [live] (the live rules in their current order) for [ids].
List<Rule> reordered(List<Rule> live, List<String> ids) {
  final Map<String, Rule> byId = {for (final Rule r in live) r.id: r};
  final List<Rule> first = [
    for (final String id in {...ids})
      if (byId[id] case final Rule rule) rule,
  ];
  final Set<String> placed = {for (final Rule r in first) r.id};
  return [
    for (final (int i, Rule r) in [
      ...first,
      ...live.where((r) => !placed.contains(r.id)),
    ].indexed)
      r.copyWith(position: i),
  ];
}
