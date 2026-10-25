// The demo budgets: two per persona on categories every demo has; on the persona's demo
// seed the food budget runs over and the transportation one stays on pace, in each of
// the two full periods before today's and on the demo's reference day.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/features/budgets/data/demo_budgets.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

void main() {
  final CategoryLookup lookup = categoryLookup(systemCategories);
  final List<LocalDate> days = [
    LocalDate(2026, 10, 24),
    LocalDate(2025, 1, 31),
    LocalDate(2028, 2, 29),
  ];

  for (final PersonaId persona in PersonaId.values) {
    test('${persona.slug}: one budget over, one on pace', () {
      for (final LocalDate today in days) {
        final List<Budget> budgets = demoBudgets(persona, today);
        expect(budgets, hasLength(2));
        final [Budget over, Budget onPace] = budgets;
        final List<Transaction> transactions = demoSeedFor(
          persona,
          today,
        ).household.transactions;
        for (final Budget b in budgets) {
          final String reason = '${b.id} on $today';
          expect(lookup.byId, contains(b.categoryId), reason: reason);
          final LocalDateRange current = periodContaining(
            today,
            b.periodStartDay,
          );
          expect(b.startDate, current.start.addMonths(-2), reason: reason);
          final List<LocalDateRange> earlier = periodsFrom(
            b.startDate,
            b.periodStartDay,
            through: today,
          )..removeLast();
          expect(earlier, hasLength(2), reason: reason);
          for (final LocalDateRange p in earlier) {
            final Money spent = spentIn(p, b, transactions, lookup);
            expect(
              b == over ? spent > b.amount : spent <= b.amount,
              isTrue,
              reason: '$reason: $spent in $p',
            );
          }
        }
        if (today == days.first) {
          expect(
            budgetStatus(over, today, transactions, lookup).projectedOverspend,
            isTrue,
          );
          final BudgetStatus pace = budgetStatus(
            onPace,
            today,
            transactions,
            lookup,
          );
          expect(pace.projectedOverspend, isFalse);
          expect(pace.carried.isPositive, isTrue);
        }
      }
    });
  }
}
