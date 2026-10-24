/// The app's notion of "now" and "today", in the device's time zone (`PLAN.md` §6.8).
///
/// Code that needs the current instant or the current local date reads a [Clock] from
/// `clockProvider` rather than calling `DateTime.now()`, so tests can pin both the instant
/// and the zone with a [FixedClock]. Audit fields use [Clock.nowUtc]; "today", periods and
/// month boundaries are computed in [Clock.location]. Pure Dart, no Flutter import.
library;

import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// The source of the current instant and the zone local dates are computed in.
///
/// [nowUtc] is truncated to milliseconds: audit instants (`created_at`, `updated_at`, the
/// sync clock's wall time) are millisecond precision, and their JSON converter refuses a
/// `DateTime` that carries microseconds.
///
/// [today] is the local date; [todayLocalMidnight] is the instant that date starts, for
/// the few callers that need a `DateTime`. Phase 1d moves the UI's date callers onto
/// [today].
abstract interface class Clock {
  /// The current instant, in UTC, truncated to milliseconds.
  DateTime nowUtc();

  /// The start of the current local day in [location], as a `tz.TZDateTime`. On a day
  /// whose midnight a DST change skips, this is the first instant of that day.
  DateTime todayLocalMidnight();

  /// The current local date in [location].
  LocalDate today();

  /// The zone "today" and local dates are computed in.
  tz.Location get location;
}

/// The real clock: the system time, in `tz.local`, which time zone setup sets to the
/// device's zone at startup (UTC when the device zone is unknown).
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => _toUtcMillis(DateTime.now());

  @override
  DateTime todayLocalMidnight() => _midnight(tz.TZDateTime.now(location));

  @override
  LocalDate today() => LocalDate.fromDateTime(todayLocalMidnight());

  @override
  tz.Location get location => tz.local;
}

/// A clock stopped at one instant in one zone, for tests.
final class FixedClock implements Clock {
  /// A clock that always reads [utc] (converted to UTC if it is not, and truncated to
  /// milliseconds) in [location].
  FixedClock(DateTime utc, this.location) : _utc = _toUtcMillis(utc);

  final DateTime _utc;

  @override
  final tz.Location location;

  @override
  DateTime nowUtc() => _utc;

  @override
  DateTime todayLocalMidnight() =>
      _midnight(tz.TZDateTime.from(_utc, location));

  @override
  LocalDate today() => LocalDate.fromDateTime(todayLocalMidnight());
}

tz.TZDateTime _midnight(tz.TZDateTime local) =>
    tz.TZDateTime(local.location, local.year, local.month, local.day);

DateTime _toUtcMillis(DateTime instant) => DateTime.fromMillisecondsSinceEpoch(
  instant.millisecondsSinceEpoch,
  isUtc: true,
);
