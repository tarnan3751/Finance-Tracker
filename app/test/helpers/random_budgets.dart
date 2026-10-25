// Random budgets for the round-trip and convergence tests: every field varied, the start
// day across 1 to 28, amounts in three currencies, start dates across 2020 to 2031.
import 'dart:math';

import 'package:shared_models/shared_models.dart';

/// A random budget [id] from [random].
Budget randomBudget(Random random, String id) => Budget(
  id: id,
  categoryId: const [
    'plaid:FOOD_AND_DRINK',
    'plaid:FOOD_AND_DRINK_GROCERIES',
    'plaid:TRANSPORTATION',
    'user-hobbies',
  ][random.nextInt(4)],
  period: BudgetPeriodKind.monthly,
  periodStartDay: 1 + random.nextInt(28),
  amount: Money(
    random.nextInt(500000),
    const ['USD', 'EUR', 'JPY'][random.nextInt(3)],
  ),
  rollover: random.nextBool(),
  startDate: LocalDate(2020, 1, 1).addDays(random.nextInt(12 * 365)),
);
