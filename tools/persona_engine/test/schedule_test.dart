// The cadences: nominal dates, the weekend rule, month-end clamping.
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  test('weekly lands on its weekday', () {
    // 2026-10-24 is a Saturday.
    expect(d(2026, 10, 24).weekday, DateTime.saturday);
    const s = Weekly(DateTime.monday);
    expect(s.occurrences(d(2026, 10, 1), d(2026, 10, 31)), [
      d(2026, 10, 5),
      d(2026, 10, 12),
      d(2026, 10, 19),
      d(2026, 10, 26),
    ]);
  });

  test('biweekly counts from its anchor in both directions', () {
    final s = Biweekly(d(2024, 1, 5));
    expect(s.isNominal(d(2024, 1, 19)), isTrue);
    expect(s.isNominal(d(2023, 12, 22)), isTrue);
    expect(s.isNominal(d(2024, 1, 12)), isFalse);
  });

  test('monthly and semi-monthly clamp to the month end', () {
    const monthly = Monthly(31);
    expect(monthly.isNominal(d(2026, 2, 28)), isTrue);
    expect(monthly.isNominal(d(2024, 2, 29)), isTrue);
    expect(monthly.isNominal(d(2024, 2, 28)), isFalse);
    const semi = SemiMonthly(15, 31);
    expect(semi.occurrences(d(2026, 4, 1), d(2026, 4, 30)), [
      d(2026, 4, 15),
      d(2026, 4, 30),
    ]);
  });

  test('yearly dates and their cadence', () {
    const once = Yearly([MonthDay(3, 3)]);
    expect(once.cadence, RecurringCadence.annually);
    const quarterly = Yearly([
      MonthDay(1, 15),
      MonthDay(4, 15),
      MonthDay(6, 15),
      MonthDay(9, 15),
    ]);
    expect(quarterly.cadence, RecurringCadence.unknown);
    expect(quarterly.occurrences(d(2026, 1, 1), d(2026, 12, 31)).length, 4);
  });

  test('the weekend rule moves a date and can pull one into the window', () {
    // 2026-11-01 is a Sunday; 2026-10-31 a Saturday.
    const back = Monthly(1, businessDay: BusinessDayRule.rollBack);
    expect(back.adjust(d(2026, 11, 1)), d(2026, 10, 30));
    expect(back.adjust(d(2026, 10, 31)), d(2026, 10, 30));
    const forward = Monthly(31, businessDay: BusinessDayRule.rollForward);
    expect(forward.adjust(d(2026, 10, 31)), d(2026, 11, 2));
    expect(forward.occurrences(d(2026, 11, 1), d(2026, 11, 3)), [
      d(2026, 11, 2),
    ]);
    expect(back.occurrences(d(2026, 10, 30), d(2026, 10, 30)), [
      d(2026, 10, 30),
    ]);
    expect(const Monthly(1).adjust(d(2026, 11, 1)), d(2026, 11, 1));
  });
}
