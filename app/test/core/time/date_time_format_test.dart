// The date and time of an instant: in the clock's zone, with a no-break space the test
// fonts carry before AM or PM instead of intl's narrow one.
import 'package:finance_tracker/core/time/date_time_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('formats in the zone, with U+00A0 and never U+202F', () {
    final DateTime instant = DateTime.utc(2026, 10, 24, 14);
    expect(formatDateTime(instant, tz.UTC), 'Oct 24, 2026 2:00\u00a0PM');
    expect(
      formatDateTime(instant, tz.getLocation('America/New_York')),
      'Oct 24, 2026 10:00\u00a0AM',
    );
    expect(formatDateTime(instant, tz.UTC), isNot(contains('\u202f')));
  });
}
