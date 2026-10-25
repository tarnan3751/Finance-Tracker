/// The one way an instant is shown as a date and a time: in the clock's zone
/// (`PLAN.md` §6.8), in the device locale's medium date and hour-minute time, such as
/// "Oct 24, 2026 2:00 PM".
///
/// intl puts U+202F (a narrow no-break space) before AM and PM. Neither font the golden
/// tests render with (Ahem, FlutterTest) carries that character, so the engine borrows it
/// from whatever font the host has, and a CI golden's text box changes width from macOS to
/// Linux. It is replaced with U+00A0, a no-break space every font here carries, so the time
/// still never breaks before AM or PM.
library;

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// [instant] (UTC) as a date and a time in [location].
String formatDateTime(DateTime instant, tz.Location location) =>
    DateFormat.yMMMd()
        .add_jm()
        .format(tz.TZDateTime.from(instant, location))
        .replaceAll('\u202F', '\u00A0');
