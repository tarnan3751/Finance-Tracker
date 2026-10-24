/// Loads the time zone database and sets `tz.local` to the device's zone, once, before
/// anything computes a local date (`PLAN.md` §6.8).
///
/// The full `latest` database is used rather than `latest_10y`: a finance app shows dates
/// years back, and the ten-year window would compute wrong offsets outside it (`PLAN.md`
/// §12). When the platform call fails, or reports a zone the database does not know, a
/// warning is logged and `tz.local` stays UTC, the package's default, so startup goes on;
/// the settings About section shows the active zone, so the fallback is visible.
library;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final Logger _log = Logger('time_zone_setup');

/// Initializes the time zone database and sets the local zone from the device. Never
/// throws: a failing platform call leaves the zone as it was and logs a warning.
Future<void> setUpTimeZones() async {
  tzdata.initializeTimeZones();
  final String identifier;
  try {
    identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (error) {
    _log.warning(
      'Could not read the device time zone ($error); dates are computed in '
      '${tz.local.name}.',
    );
    return;
  }
  applyLocalTimeZone(identifier);
}

/// Sets `tz.local` to the zone named [identifier], or leaves it unchanged and logs a
/// warning when the database has no such zone. The database must be initialized.
void applyLocalTimeZone(String identifier) {
  try {
    tz.setLocalLocation(tz.getLocation(identifier));
  } on tz.LocationNotFoundException {
    _log.warning(
      'Unknown device time zone "$identifier"; dates are computed in '
      '${tz.local.name}.',
    );
  }
}
