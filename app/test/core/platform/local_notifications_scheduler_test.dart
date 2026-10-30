// The real scheduler against the plugin's Android method channel, mocked: what it
// initializes with, how it schedules (inexact, the channel, the payload), that it cancels
// only what is no longer wanted, how it reads the pending set and the permission, and
// that a reminder which launched the app is replayed to the first listener.
import 'dart:async';

import 'package:finance_tracker/core/platform/local_notifications_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const MethodChannel channel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  late List<MethodCall> calls;
  late List<Map<String, Object?>> pending;
  late bool enabled;
  late Map<String, Object?>? launch;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    pending = [];
    enabled = false;
    launch = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'getNotificationAppLaunchDetails' => launch,
            'pendingNotificationRequests' => pending,
            'areNotificationsEnabled' => enabled,
            'requestNotificationsPermission' => true,
            _ => null,
          };
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  LocalNotificationsScheduler scheduler() => LocalNotificationsScheduler(
    FlutterLocalNotificationsPlugin(),
    channelName: 'Bill reminders',
    channelDescription: 'Reminders before bills are due',
    now: () => DateTime.utc(2026, 10, 27),
  );

  // A spring-forward day far enough ahead that the plugin, which checks the instant
  // against the real clock, does not find it past for years, and before 2037, after
  // which the zone database has no DST transitions.
  ScheduledReminder reminder(int id, {String bill = 'rent'}) {
    final tz.Location newYork = tz.getLocation('America/New_York');
    return ScheduledReminder(
      id: id,
      billId: bill,
      dueDate: LocalDate(2036, 3, 9),
      at: tz.TZDateTime(newYork, 2036, 3, 9, 2, 30),
      title: 'Rent is due',
      body: 'Mar 9',
    );
  }

  test('initializes once with the small icon', () async {
    final LocalNotificationsScheduler s = scheduler();
    await s.pending();
    await s.pending();
    final List<MethodCall> inits = [
      for (final c in calls)
        if (c.method == 'initialize') c,
    ];
    expect(inits, hasLength(1));
    expect(
      (inits.single.arguments as Map<Object?, Object?>)['defaultIcon'],
      'ic_stat_bill',
    );
  });

  test('schedules inexactly on the bill channel and cancels only stale ids', () async {
    pending = [
      {'id': 1, 'title': 't', 'body': 'b', 'payload': reminder(1).payload},
      {'id': 9, 'title': 't', 'body': 'b', 'payload': reminder(9).payload},
    ];
    await scheduler().replaceAll([reminder(1), reminder(2)]);
    final List<Object?> cancelled = [
      for (final c in calls)
        if (c.method == 'cancel') (c.arguments as Map<Object?, Object?>)['id'],
    ];
    expect(cancelled, [9]);
    final List<Map<Object?, Object?>> scheduled = [
      for (final c in calls)
        if (c.method == 'zonedSchedule') c.arguments as Map<Object?, Object?>,
    ];
    expect([for (final s in scheduled) s['id']], [1, 2]);
    final Map<Object?, Object?> first = scheduled.first;
    expect(first['title'], 'Rent is due');
    expect(first['payload'], reminder(1).payload);
    expect(first['timeZoneName'], 'America/New_York');
    // The wall clock of a time the spring-forward gap skips, as Dart resolved it; the
    // plugin's Java side resolves it again in the zone (to 03:30) the same way.
    expect(first['scheduledDateTime'], endsWith('T03:30:00'));
    final Map<Object?, Object?> specifics =
        first['platformSpecifics']! as Map<Object?, Object?>;
    expect(specifics['channelId'], billRemindersChannelId);
    expect(specifics['channelName'], 'Bill reminders');
    expect(specifics['scheduleMode'], 'inexactAllowWhileIdle');
    expect(calls.where((c) => c.method == 'cancelAll'), isEmpty);
  });

  test('skips a reminder already past', () async {
    final ScheduledReminder past = ScheduledReminder(
      id: 3,
      billId: 'b',
      dueDate: LocalDate(2020, 1, 1),
      at: tz.TZDateTime.utc(2020),
      title: '',
      body: '',
    );
    await scheduler().replaceAll([past]);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test('reads the pending set back from the payloads', () async {
    pending = [
      {
        'id': 2,
        'title': 'Rent is due',
        'body': 'Mar 9',
        'payload': reminder(2).payload,
      },
      {'id': 5, 'title': 'x', 'body': 'y', 'payload': 'not ours'},
    ];
    final List<ScheduledReminder> back = await scheduler().pending();
    expect(back, [reminder(2)]);
  });

  test('asks for the permission only when told to', () async {
    expect(await scheduler().ensurePermission(request: false), isFalse);
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission'),
      isEmpty,
    );
    expect(await scheduler().ensurePermission(request: true), isTrue);
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission'),
      hasLength(1),
    );
    enabled = true;
    calls.clear();
    expect(await scheduler().ensurePermission(request: true), isTrue);
    expect(
      calls.where((c) => c.method == 'requestNotificationsPermission'),
      isEmpty,
    );
  });

  test('cancels pending only, and opens the settings', () async {
    final LocalNotificationsScheduler s = scheduler();
    await s.cancelAll();
    await s.openSettings();
    expect(
      [for (final c in calls) c.method],
      containsAllInOrder([
        'cancelAllPendingNotifications',
        'openAppNotificationSettings',
      ]),
    );
    expect(calls.where((c) => c.method == 'cancelAll'), isEmpty);
  });

  test('clears every notification, shown ones included', () async {
    await scheduler().clearAll();
    expect(calls.where((c) => c.method == 'cancelAll'), hasLength(1));
  });

  test('replays the reminder that launched the app', () async {
    launch = {
      'notificationLaunchedApp': true,
      'notificationResponse': {
        'notificationResponseType': 0,
        'notificationId': 2,
        'payload': reminder(2, bill: 'electric').payload,
      },
    };
    final LocalNotificationsScheduler s = scheduler();
    final Completer<String> opened = Completer<String>();
    final StreamSubscription<String> sub = s.openedBillIds.listen(
      opened.complete,
    );
    expect(await opened.future, 'electric');
    await sub.cancel();
  });
}
