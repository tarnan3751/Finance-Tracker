/// When a bill's reminders go off (`docs/reference/bills.md`, **Reminder times**;
/// `PLAN.md` §6.8): for each occurrence and each offset, the local date that many days
/// before it at the bill's wall-clock time, in a zone. Pure Dart.
///
/// The instant is built from the wall clock with `tz.TZDateTime(location, y, m, d, h,
/// min)`, never by adding a `Duration` across days, so it stays at the wall-clock time
/// across a DST change. A time a DST gap skips resolves as the `timezone` package does,
/// later by the gap's length (02:30 on a spring-forward day is 03:30). A time a fall-back
/// day has twice is its **first** occurrence: the package gives the second in zones east
/// of UTC, so when the zone's previous period had a larger offset and the instant earlier
/// by the difference shows the same wall clock, that earlier instant is used.
/// `flutter_local_notifications` re-resolves the wall clock the same way on Android
/// (`ZonedDateTime.of`: the earlier offset in an overlap, later by the gap in a gap), so
/// the instant computed here is the one the platform schedules.
library;

import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// How far ahead reminders are planned.
const int reminderWindowDays = 60;

/// One reminder of a bill: for its occurrence due [due], [offset] days before, at [at].
typedef ReminderTime = ({LocalDate due, int offset, tz.TZDateTime at});

/// The instant [minutes] after midnight on [date] in [location], the first one when the
/// day has that wall-clock time twice.
tz.TZDateTime reminderInstant(
  tz.Location location,
  LocalDate date,
  int minutes,
) {
  final int hour = minutes ~/ 60;
  final int minute = minutes % 60;
  final tz.TZDateTime at = tz.TZDateTime(
    location,
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  );
  final int ms = at.millisecondsSinceEpoch;
  final tz.TzInstant period = location.lookupTimeZone(ms);
  final Duration before = location
      .lookupTimeZone(period.start - 1)
      .timeZone
      .offset;
  final Duration now = period.timeZone.offset;
  if (before > now) {
    final tz.TZDateTime earlier = tz.TZDateTime.fromMillisecondsSinceEpoch(
      location,
      ms - (before - now).inMilliseconds,
    );
    if (earlier.year == date.year &&
        earlier.month == date.month &&
        earlier.day == date.day &&
        earlier.hour == hour &&
        earlier.minute == minute) {
      return earlier;
    }
  }
  return at;
}

/// [bill]'s reminders after [now] and at most [reminderWindowDays] days after it, in
/// [location], for the occurrences of [schedule] that [skip] does not exclude (the paid
/// ones); by instant, then due date, then offset.
List<ReminderTime> reminderTimes(
  BillReminder bill,
  BillSchedule schedule,
  DateTime now,
  tz.Location location, {
  bool Function(LocalDate due)? skip,
}) {
  final tz.TZDateTime local = tz.TZDateTime.from(now, location);
  final LocalDate today = LocalDate(local.year, local.month, local.day);
  final DateTime end = now.add(const Duration(days: reminderWindowDays));
  final List<ReminderTime> times = [
    // An occurrence up to the largest offset past the window's last day still has a
    // reminder inside it.
    for (final LocalDate due in schedule.between(
      today,
      today.addDays(reminderWindowDays + 31),
    ))
      if (skip == null || !skip(due))
        for (final int offset in bill.reminderOffsetDays)
          (
            due: due,
            offset: offset,
            at: reminderInstant(
              location,
              due.addDays(-offset),
              bill.reminderMinutes,
            ),
          ),
  ]..removeWhere((r) => !r.at.isAfter(now) || r.at.isAfter(end));
  return times..sort((a, b) {
    final int byAt = a.at.compareTo(b.at);
    if (byAt != 0) return byAt;
    final int byDue = a.due.compareTo(b.due);
    return byDue != 0 ? byDue : a.offset.compareTo(b.offset);
  });
}
