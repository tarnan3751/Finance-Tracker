// The demo rules: two per persona, each matching some of that persona's demo
// transactions and changing them, and naming only categories every demo has.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/rules/data/demo_rules.dart';
import 'package:finance_tracker/features/rules/domain/rules_engine.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

void main() {
  final CategoryLookup lookup = categoryLookup(systemCategories);

  for (final PersonaId persona in PersonaId.values) {
    test('${persona.slug}: two rules, each changing some transactions', () {
      final List<Rule> rules = demoRules(persona);
      expect(rules, hasLength(2));
      expect({for (final Rule r in rules) r.position}, {0, 1});
      for (final Rule rule in rules) {
        for (final RuleAction action in rule.actions) {
          if (action.kind == RuleActionKind.setCategory) {
            expect(lookup.byId, contains(action.value), reason: rule.id);
          }
        }
      }
      final List<Transaction> transactions = demoSeedFor(
        persona,
        LocalDate(2026, 10, 24),
      ).household.transactions;
      for (final Rule rule in rules) {
        expect(
          transactions.where(
            (t) => applyRules([rule], t, lookup: lookup).changed != null,
          ),
          isNotEmpty,
          reason: rule.id,
        );
      }
    });
  }
}
