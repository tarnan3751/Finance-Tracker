/// The demo flavor's goals: two per persona, from its demo seed without changing the
/// engine (`PLAN.md` §12 "Goals"), so the goals screens have something to show. User
/// data, so no `source`. Data only, deterministic for a seed and a day:
///
/// - **Emergency fund**, a balance goal on the persona's savings account (its first
///   depository account when it has none): twice that account's balance, rounded up to
///   a hundred (at least a thousand) in its currency, created six months before today,
///   due a year after;
/// - **Holiday**, a contribution goal of 1,800.00 in the same currency, created six
///   months before today and due six months after, with six monthly contributions of
///   125.00 from its creation day, so it shows behind its plan.
library;

import 'package:persona_engine/persona_engine.dart' show DemoSeed;
import 'package:shared_models/shared_models.dart';

/// The demo goals of [seed] as of [today], with their contributions; none when the
/// persona has no depository account.
({List<Goal> goals, List<GoalContribution> contributions}) demoGoals(
  DemoSeed seed,
  LocalDate today,
) {
  final List<Account> depository = [
    for (final Account a in seed.household.accounts)
      if (a.type == AccountType.depository) a,
  ];
  if (depository.isEmpty) return (goals: const [], contributions: const []);
  final Account fund = depository.firstWhere(
    (a) => a.subtype == 'savings',
    orElse: () => depository.first,
  );
  final String currency = fund.currencyCode;
  int unit = 1;
  for (int i = Money.zero(currency).scale; i > 0; i--) {
    unit *= 10;
  }
  // [units] whole units of the currency.
  Money major(int units) => Money(units * unit, currency);
  final int hundred = 100 * unit;
  final int twice = 2 * (fund.currentBalance?.minorUnits ?? 0);
  final int rounded = (twice + hundred - 1) ~/ hundred * hundred;
  final LocalDate created = today.addMonths(-6);
  const String holiday = 'demo-goal-holiday';
  return (
    goals: [
      Goal(
        id: 'demo-goal-fund',
        name: 'Emergency fund',
        target: Money.max(Money(rounded, currency), major(1000)),
        kind: GoalKind.balance,
        linkedAccountIds: [fund.id],
        targetDate: today.addMonths(12),
        createdOn: created,
      ),
      Goal(
        id: holiday,
        name: 'Holiday',
        target: major(1800),
        kind: GoalKind.contribution,
        targetDate: today.addMonths(6),
        createdOn: created,
      ),
    ],
    contributions: [
      for (int m = 0; m < 6; m++)
        GoalContribution(
          id: '$holiday-${m + 1}',
          goalId: holiday,
          date: created.addMonths(m),
          amount: major(125),
        ),
    ],
  );
}
