// Reminder instants across DST in both directions, in both hemispheres and on both
// sides of UTC: a skipped time moves later by the gap, a repeated one takes its first
// occurrence; then the window, past instants and paid occurrences.
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/reminder_times.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  void expectInstant(
    String zone,
    LocalDate date,
    int minutes,
    DateTime utc, {
    required String wallClock,
  }) {
    final tz.TZDateTime at = reminderInstant(
      tz.getLocation(zone),
      date,
      minutes,
    );
    expect(at.toUtc(), utc, reason: '$zone $date $minutes');
    expect(
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
      wallClock,
    );
  }

  group('a reminder instant', () {
    test('is the wall-clock time on an ordinary day', () {
      expectInstant(
        'America/New_York',
        d(2027, 3, 10),
        540,
        DateTime.utc(2027, 3, 10, 14),
        wallClock: '09:00',
      );
      expectInstant(
        'America/New_York',
        d(2027, 3, 20),
        540,
        DateTime.utc(2027, 3, 20, 13),
        wallClock: '09:00',
      );
    });

    test('New York: a skipped 02:30 is 03:30, a repeated 01:30 the first', () {
      expectInstant(
        'America/New_York',
        d(2027, 3, 14),
        150,
        DateTime.utc(2027, 3, 14, 7, 30),
        wallClock: '03:30',
      );
      expectInstant(
        'America/New_York',
        d(2027, 11, 7),
        90,
        DateTime.utc(2027, 11, 7, 5, 30), // EDT, not EST's 06:30
        wallClock: '01:30',
      );
    });

    test('Berlin: a skipped 02:30 is 03:30, a repeated 02:30 the first', () {
      expectInstant(
        'Europe/Berlin',
        d(2027, 3, 28),
        150,
        DateTime.utc(2027, 3, 28, 1, 30),
        wallClock: '03:30',
      );
      expectInstant(
        'Europe/Berlin',
        d(2027, 10, 31),
        150,
        DateTime.utc(2027, 10, 31, 0, 30), // CEST, not CET's 01:30
        wallClock: '02:30',
      );
    });

    test('Auckland: the southern hemisphere both ways', () {
      expectInstant(
        'Pacific/Auckland',
        d(2027, 9, 26),
        150,
        DateTime.utc(2027, 9, 25, 14, 30),
        wallClock: '03:30',
      );
      expectInstant(
        'Pacific/Auckland',
        d(2027, 4, 4),
        150,
        DateTime.utc(2027, 4, 3, 13, 30), // NZDT, not NZST's 14:30
        wallClock: '02:30',
      );
    });

    test('a time just outside the repeated hour is unambiguous', () {
      expectInstant(
        'Europe/Berlin',
        d(2027, 10, 31),
        180,
        DateTime.utc(2027, 10, 31, 2),
        wallClock: '03:00',
      );
      expectInstant(
        'Europe/Berlin',
        d(2027, 10, 31),
        119,
        DateTime.utc(2027, 10, 30, 23, 59),
        wallClock: '01:59',
      );
    });
  });

  group('reminder times', () {
    late final tz.Location newYork = tz.getLocation('America/New_York');
    final BillReminder bill = BillReminder(
      id: 'b',
      dueDate: d(2027, 3, 1),
      cadence: RecurringCadence.weekly,
      reminderOffsetDays: const [0, 2],
    );

    test('keep the wall-clock time across the DST change', () {
      final List<ReminderTime> times = reminderTimes(
        bill,
        BillSchedule.of(bill),
        DateTime.utc(2027, 3, 6, 12),
        newYork,
      );
      final List<String> walls = [
        for (final r in times.take(4)) '${r.at.month}-${r.at.day} ${r.at.hour}',
      ];
      expect(walls, ['3-6 9', '3-8 9', '3-13 9', '3-15 9']);
      expect(times[0].at.toUtc().hour, 14); // EST
      expect(times[3].at.toUtc().hour, 13); // EDT
    });

    test('skip past instants and stop 60 days out', () {
      final DateTime now = DateTime.utc(
        2027,
        3,
        8,
        15,
      ); // 11:00 EDT on a due day
      final List<ReminderTime> times = reminderTimes(
        bill,
        BillSchedule.of(bill),
        now,
        newYork,
      );
      expect(times.first.due, d(2027, 3, 15));
      expect(times.first.offset, 2);
      expect(times.every((r) => r.at.isAfter(now)), isTrue);
      expect(
        times.every(
          (r) =>
              !r.at.isAfter(now.add(const Duration(days: reminderWindowDays))),
        ),
        isTrue,
      );
      // The window ends 2027-05-07 11:00 EDT: 05-10's reminder two days before is
      // past it, so the last is 05-03's on the day.
      expect(times.last.due, d(2027, 5, 3));
      expect(times.last.offset, 0);
    });

    test('leave out the occurrences skip excludes', () {
      final List<ReminderTime> times = reminderTimes(
        bill,
        BillSchedule.of(bill),
        DateTime.utc(2027, 3, 6, 12),
        newYork,
        skip: (due) => due == d(2027, 3, 8),
      );
      expect(times.map((r) => r.due), isNot(contains(d(2027, 3, 8))));
      expect(times.first.due, d(2027, 3, 15));
    });

    test('a one-off past its date has none', () {
      final BillReminder once = BillReminder(id: 'o', dueDate: d(2027, 3, 1));
      expect(
        reminderTimes(
          once,
          BillSchedule.of(once),
          DateTime.utc(2027, 3, 2),
          newYork,
        ),
        isEmpty,
      );
    });
  });
}
