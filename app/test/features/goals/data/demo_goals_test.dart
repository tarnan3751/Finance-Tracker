// The demo goals of every persona: an emergency fund on its savings account (the first
// depository account without one) and a holiday saved by six contributions, both
// deterministic, the fund's target twice the account's balance rounded up to a hundred,
// and the holiday behind its plan; loaded into the demo repository as given.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/features/goals/application/goals_providers.dart';
import 'package:finance_tracker/features/goals/data/demo_goal_repository.dart';
import 'package:finance_tracker/features/goals/data/demo_goals.dart';
import 'package:finance_tracker/features/goals/domain/goal_math.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart' show testClock;

void main() {
  final LocalDate today = LocalDate(2026, 10, 27);

  for (final PersonaId persona in PersonaId.values) {
    test('${persona.slug}: an emergency fund and a holiday', () async {
      final DemoSeed seed = demoSeedFor(persona, today);
      final demo = demoGoals(seed, today);
      final again = demoGoals(demoSeedFor(persona, today), today);
      expect(again.goals, demo.goals);
      expect(again.contributions, demo.contributions);
      expect(demo.goals.map((g) => g.id), [
        'demo-goal-fund',
        'demo-goal-holiday',
      ]);

      final Goal fund = demo.goals.first;
      final Account account = seed.household.accounts.singleWhere(
        (a) => a.id == fund.linkedAccountIds.single,
      );
      expect(account.type, AccountType.depository);
      if (seed.household.accounts.any((a) => a.subtype == 'savings')) {
        expect(account.subtype, 'savings');
      }
      final Money balance = account.currentBalance!;
      expect(fund.kind, GoalKind.balance);
      expect(fund.target.currencyCode, account.currencyCode);
      expect(fund.target.minorUnits % 10000, 0);
      expect(fund.target >= balance + balance, isTrue);
      expect(fund.target.minorUnits >= 100000, isTrue);
      expect(fund.createdOn, LocalDate(2026, 4, 27));
      expect(fund.targetDate, LocalDate(2027, 10, 27));

      final Goal holiday = demo.goals.last;
      expect(holiday.kind, GoalKind.contribution);
      expect(holiday.target, Money(180000, account.currencyCode));
      expect(holiday.targetDate, LocalDate(2027, 4, 27));
      expect(demo.contributions.map((c) => c.date), [
        for (int m = 0; m < 6; m++) LocalDate(2026, 4 + m, 27),
      ]);
      expect(
        contributionProgress(demo.contributions, account.currencyCode),
        Money(75000, account.currencyCode),
      );
      expect(
        goalStatus(holiday, Money(75000, account.currencyCode), today),
        isA<GoalBehind>(),
      );

      final DemoGoalRepository repository = DemoGoalRepository(
        testClock,
        goals: demo.goals,
        contributions: demo.contributions,
      );
      addTearDown(repository.close);
      final List<GoalEntry> entries = await repository.watchAll().first;
      expect(entries.map((e) => e.contributions.length), [0, 6]);
      expect(
        goalView(entries.last, const {}, const {}, today).status,
        isA<GoalBehind>(),
      );
    });
  }
}
