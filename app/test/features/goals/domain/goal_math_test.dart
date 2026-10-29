// The goal math's worked examples: whole months across month ends and leap days, the
// suggestion rounded up, the linear plan rounded down, a past or absent target date, a
// reached goal and negative contributions.
import 'package:finance_tracker/features/goals/domain/goal_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

Money usd(int minor) => Money(minor, 'USD');

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

Goal goal({int target = 120000, LocalDate? targetDate, LocalDate? createdOn}) =>
    Goal(
      id: 'g',
      name: 'Holiday',
      target: usd(target),
      kind: GoalKind.contribution,
      targetDate: targetDate,
      createdOn: createdOn ?? d(2026, 1, 1),
    );

void main() {
  group('months left', () {
    test('counts whole months, clamped to short months', () {
      expect(monthsLeft(d(2026, 1, 31), d(2026, 2, 28)), 1);
      expect(monthsLeft(d(2026, 1, 31), d(2026, 3, 30)), 1);
      expect(monthsLeft(d(2026, 1, 31), d(2026, 3, 31)), 2);
      expect(monthsLeft(d(2026, 10, 29), d(2027, 10, 29)), 12);
      expect(monthsLeft(d(2026, 10, 29), d(2027, 10, 28)), 11);
      expect(monthsLeft(d(2024, 2, 29), d(2025, 2, 28)), 12);
    });

    test(
      'is at least one for a date ahead, none for today, the past or none',
      () {
        expect(monthsLeft(d(2026, 10, 29), d(2026, 11, 5)), 1);
        expect(monthsLeft(d(2026, 10, 29), d(2026, 10, 30)), 1);
        expect(monthsLeft(d(2026, 10, 29), d(2026, 10, 29)), isNull);
        expect(monthsLeft(d(2026, 10, 29), d(2026, 9, 1)), isNull);
        expect(monthsLeft(d(2026, 10, 29), null), isNull);
      },
    );
  });

  group('the suggestion', () {
    test('is what remains over the months left, rounded up to the cent', () {
      expect(
        suggestedMonthly(usd(100000), usd(0), d(2026, 1, 1), d(2026, 4, 1)),
        usd(33334),
      );
      expect(
        suggestedMonthly(usd(100000), usd(40000), d(2026, 1, 1), d(2026, 4, 1)),
        usd(20000),
      );
      // Under a month: all of it this month.
      expect(
        suggestedMonthly(usd(100000), usd(1), d(2026, 1, 1), d(2026, 1, 20)),
        usd(99999),
      );
    });

    test('counts a withdrawal below zero as more to save', () {
      expect(
        suggestedMonthly(usd(100000), usd(-5000), d(2026, 1, 1), d(2026, 3, 1)),
        usd(52500),
      );
    });

    test('is none once reached, past the date, or without one', () {
      expect(
        suggestedMonthly(
          usd(100000),
          usd(100001),
          d(2026, 1, 1),
          d(2026, 4, 1),
        ),
        isNull,
      );
      expect(
        suggestedMonthly(usd(100000), usd(0), d(2026, 5, 1), d(2026, 4, 1)),
        isNull,
      );
      expect(
        suggestedMonthly(usd(100000), usd(0), d(2026, 4, 1), d(2026, 4, 1)),
        isNull,
      );
      expect(
        suggestedMonthly(usd(100000), usd(0), d(2026, 1, 1), null),
        isNull,
      );
    });
  });

  test('remaining never goes below zero', () {
    expect(remainingFor(usd(1000), usd(400)), usd(600));
    expect(remainingFor(usd(1000), usd(1500)), usd(0));
    expect(remainingFor(usd(1000), usd(-500)), usd(1500));
  });

  test('the linear plan is the elapsed share of the target, rounded down', () {
    // 182 of 365 days of 1,200.00 is 598.356...
    expect(
      expectedProgress(
        usd(120000),
        d(2026, 1, 1),
        d(2027, 1, 1),
        d(2026, 7, 2),
      ),
      usd(59835),
    );
    expect(
      expectedProgress(
        usd(120000),
        d(2026, 1, 1),
        d(2027, 1, 1),
        d(2026, 1, 1),
      ),
      usd(0),
    );
    expect(
      expectedProgress(
        usd(120000),
        d(2026, 1, 1),
        d(2027, 1, 1),
        d(2025, 6, 1),
      ),
      usd(0),
    );
    expect(
      expectedProgress(
        usd(120000),
        d(2026, 1, 1),
        d(2027, 1, 1),
        d(2027, 3, 1),
      ),
      usd(120000),
    );
    // A target date on or before the creation day: the whole target is due.
    expect(
      expectedProgress(
        usd(120000),
        d(2026, 1, 1),
        d(2025, 1, 1),
        d(2026, 1, 1),
      ),
      usd(120000),
    );
  });

  group('the status', () {
    final Goal yearly = goal(targetDate: d(2027, 1, 1));

    test('is done once the progress reaches the target, dated or not', () {
      expect(goalStatus(yearly, usd(120000), d(2026, 3, 1)), const GoalDone());
      expect(goalStatus(goal(), usd(130000), d(2026, 3, 1)), const GoalDone());
      expect(goalStatus(yearly, usd(120000), d(2028, 1, 1)), const GoalDone());
    });

    test(
      'is on track at or above the plan, behind by the difference below',
      () {
        expect(
          goalStatus(yearly, usd(59835), d(2026, 7, 2)),
          const GoalOnTrack(),
        );
        expect(
          goalStatus(yearly, usd(59834), d(2026, 7, 2)),
          GoalBehind(usd(1)),
        );
        expect(goalStatus(yearly, usd(0), d(2026, 1, 1)), const GoalOnTrack());
      },
    );

    test('past the date and short, is behind by what remains', () {
      expect(
        goalStatus(yearly, usd(20000), d(2027, 2, 1)),
        GoalBehind(usd(100000)),
      );
    });

    test('a withdrawal puts it further behind', () {
      final Money progress = contributionProgress([
        GoalContribution(
          id: 'a',
          goalId: 'g',
          date: d(2026, 2, 1),
          amount: usd(50000),
        ),
        GoalContribution(
          id: 'b',
          goalId: 'g',
          date: d(2026, 3, 1),
          amount: usd(-20000),
        ),
      ], 'USD');
      expect(progress, usd(30000));
      expect(
        goalStatus(yearly, progress, d(2026, 7, 2)),
        GoalBehind(usd(29835)),
      );
    });

    test('is open without a target date', () {
      expect(goalStatus(goal(), usd(1000), d(2026, 3, 1)), const GoalOpen());
    });
  });

  test('contributions in another currency are left out of the progress', () {
    expect(
      contributionProgress([
        GoalContribution(
          id: 'a',
          goalId: 'g',
          date: d(2026, 2, 1),
          amount: usd(500),
        ),
        GoalContribution(
          id: 'b',
          goalId: 'g',
          date: d(2026, 2, 1),
          amount: Money(900, 'EUR'),
        ),
      ], 'USD'),
      usd(500),
    );
    expect(contributionProgress(const [], 'USD'), usd(0));
  });
}
