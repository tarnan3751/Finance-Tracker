// The reminder boundary's pure parts: stable 31-bit ids, the payload round trip, and the
// fake's pending set, permission, firing and taps.
import 'dart:async';

import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  ScheduledReminder reminder(int id, {String bill = 'b'}) => ScheduledReminder(
    id: id,
    billId: bill,
    dueDate: LocalDate(2027, 3, 14),
    at: tz.TZDateTime(tz.getLocation('America/New_York'), 2027, 3, 12, 9),
    title: 'Rent',
    body: 'Due Mar 14',
  );

  test('ids are stable, 31-bit and differ by bill, date and offset', () {
    final int id = reminderId('rent', LocalDate(2027, 3, 14), 2);
    expect(id, reminderId('rent', LocalDate(2027, 3, 14), 2));
    expect(id, inInclusiveRange(0, 0x7fffffff));
    expect({
      id,
      reminderId('rent', LocalDate(2027, 3, 14), 1),
      reminderId('rent', LocalDate(2027, 4, 14), 2),
      reminderId('rents', LocalDate(2027, 3, 14), 2),
    }, hasLength(4));
  });

  test('the payload carries bill, due and the UTC instant, and reads back', () {
    final ScheduledReminder r = reminder(7);
    expect(
      r.payload,
      '{"bill":"b","due":"2027-03-14","at":"2027-03-12T14:00:00.000Z"}',
    );
    final ScheduledReminder? back = ScheduledReminder.fromPayload(
      7,
      'Rent',
      'Due Mar 14',
      r.payload,
    );
    expect(back, r);
    expect(back!.at.location, tz.UTC);
    for (final String? other in [null, '', 'x', '{"bill":1}', '[]']) {
      expect(ScheduledReminder.fromPayload(1, null, null, other), isNull);
    }
  });

  test('the fake replaces its pending set and plays the platform', () async {
    final FakeReminderScheduler fake = FakeReminderScheduler(
      granted: false,
      grantOnRequest: false,
    );
    expect(await fake.ensurePermission(request: false), isFalse);
    expect(fake.permissionRequests, 0);
    expect(await fake.ensurePermission(request: true), isFalse);
    expect(fake.permissionRequests, 1);
    fake.grantOnRequest = true;
    expect(await fake.ensurePermission(request: true), isTrue);

    await fake.replaceAll([reminder(2), reminder(1)]);
    await fake.replaceAll([reminder(3), reminder(2)]);
    expect([for (final r in await fake.pending()) r.id], [2, 3]);
    expect(fake.fire(2), reminder(2));
    expect(fake.fire(2), isNull);
    expect([for (final r in await fake.pending()) r.id], [3]);
    await fake.cancelAll();
    expect(await fake.pending(), isEmpty);

    final List<String> opened = [];
    final StreamSubscription<String> sub = fake.openedBillIds.listen(
      opened.add,
    );
    fake.tap('rent');
    await pumpEventQueue();
    expect(opened, ['rent']);
    await sub.cancel();
    await fake.close();
  });
}
