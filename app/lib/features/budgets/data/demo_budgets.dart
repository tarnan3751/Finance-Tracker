/// The demo flavor's budgets: two per persona, on the system categories its demo seed
/// spends in every month, so the budgets screens have something to show. Food and drink
/// (the group) is budgeted below every recent month's spending, so it runs over and
/// raises its alerts; transportation, from the 15th with rollover, at about twice the
/// persona's busiest month, so it stays on pace and carries a surplus. Both start two
/// periods before today's, so rollover has history. Data only.
library;

import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

/// The two budgets of [persona]'s demo as of [today]: the one that runs over first.
List<Budget> demoBudgets(PersonaId persona, LocalDate today) {
  final (int food, int transport) = switch (persona) {
    PersonaId.renter => (50000, 100000),
    PersonaId.family => (100000, 150000),
    PersonaId.student => (30000, 8000),
    PersonaId.smallBusiness => (80000, 120000),
  };
  return [
    _budget('demo-budget-food', 'plaid:FOOD_AND_DRINK', 1, food, false, today),
    _budget(
      'demo-budget-transport',
      'plaid:TRANSPORTATION',
      15,
      transport,
      true,
      today,
    ),
  ];
}

Budget _budget(
  String id,
  String categoryId,
  int periodStartDay,
  int amountMinor,
  bool rollover,
  LocalDate today,
) => Budget(
  id: id,
  categoryId: categoryId,
  period: BudgetPeriodKind.monthly,
  periodStartDay: periodStartDay,
  amount: Money(amountMinor, 'USD'),
  rollover: rollover,
  startDate: periodContaining(today, periodStartDay).start.addMonths(-2),
);
