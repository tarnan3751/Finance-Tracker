// The notification channels and the tray notifier against the plugin's Android method
// channel, mocked: the four channels created with their ids and importances (again at
// each start, idempotent), a channel off read from its importance, the settings opened
// through the app's channel; each kind posted on its channel with its tag, alerting
// once, its id a hash of its key and its route in the payload; a bill due never posted;
// the composite telling every notifier past a failure; and the permission asked once.
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/local_notification_channels.dart';
import 'package:finance_tracker/core/platform/local_notifications.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/platform/system_notifier.dart';
import 'package:finance_tracker/core/platform/system_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

const MethodChannel _plugin = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

const Map<AppChannel, ChannelText> _texts = {
  AppChannel.budgetAlerts: (name: 'Budget alerts', description: 'b'),
  AppChannel.billReminders: (name: 'Bill reminders', description: 'r'),
  AppChannel.weeklySummary: (name: 'Weekly summary', description: 'w'),
  AppChannel.syncProblems: (name: 'Sync problems', description: 's'),
};

Map<String, Object?> _channel(String id, int importance) => {
  'id': id,
  'name': id,
  'importance': importance,
  'showBadge': true,
  'bypassDnd': false,
  'playSound': true,
  'enableLights': false,
  'enableVibration': true,
  'ledColor': 0,
  'audioAttributesUsage': 5,
};

final class _Failing implements Notifier {
  @override
  Future<void> notify(AppNotification notification) async =>
      throw StateError('down');
}

final class _Recording implements Notifier {
  final List<String> keys = [];

  @override
  Future<void> notify(AppNotification notification) async =>
      keys.add(notification.key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late List<Map<String, Object?>> channels;
  late bool enabled;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    channels = [];
    enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_plugin, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'getNotificationChannels' => channels,
            'areNotificationsEnabled' => enabled,
            _ => null,
          };
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_plugin, null),
  );

  Iterable<Map<Object?, Object?>> args(String method) => [
    for (final MethodCall c in calls)
      if (c.method == method) c.arguments as Map<Object?, Object?>,
  ];

  test(
    'the channels are created with fixed ids and importances, each start',
    () async {
      final FakeSystemSettings settings = FakeSystemSettings();
      final LocalNotificationChannels c = LocalNotificationChannels(
        LocalNotifications(FlutterLocalNotificationsPlugin()),
        settings,
      );
      await c.ensure(_texts);
      await c.ensure(_texts);
      final List<Map<Object?, Object?>> created = [
        ...args('createNotificationChannel'),
      ];
      expect(created, hasLength(8));
      expect(
        {for (final m in created.take(4)) m['id']: m['importance']},
        {
          'budget_alerts': Importance.defaultImportance.value,
          'bill_reminders': Importance.defaultImportance.value,
          'weekly_summary': Importance.low.value,
          'sync_problems': Importance.defaultImportance.value,
        },
      );
      expect(created.first['name'], 'Budget alerts');

      channels = [
        _channel('budget_alerts', Importance.none.value),
        _channel('weekly_summary', Importance.low.value),
        _channel('other', Importance.none.value),
      ];
      NotificationsState state = await c.state();
      expect(state.appEnabled, isTrue);
      expect(state.blocked, {AppChannel.budgetAlerts});
      expect(state.shows(AppChannel.weeklySummary), isTrue);
      enabled = false;
      state = await c.state();
      expect(state.shows(AppChannel.weeklySummary), isFalse);

      await c.openChannelSettings(AppChannel.syncProblems);
      await c.openAppSettings();
      expect(settings.opened, ['sync_problems']);
      expect(
        calls.map((m) => m.method),
        contains('openAppNotificationSettings'),
      );
    },
  );

  test('each kind is posted on its channel; a bill due is not', () async {
    final SystemNotifier notifier = SystemNotifier(
      LocalNotifications(FlutterLocalNotificationsPlugin()),
      _texts,
      (n) async => switch (n) {
        WeeklySummaryNotification() => (
          channel: AppChannel.weeklySummary,
          title: 'Ready',
          body: 'See it',
          route: '/insights/reports/weekly',
        ),
        _ => null,
      },
    );
    final WeeklySummaryNotification weekly = WeeklySummaryNotification(
      weekStart: LocalDate(2026, 10, 19),
      raisedAt: DateTime.utc(2026, 10, 26),
    );
    await notifier.notify(weekly);
    await notifier.notify(
      BillDueNotification(
        billId: 'b',
        name: 'Rent',
        dueDate: LocalDate(2026, 10, 27),
        amount: null,
        raisedAt: DateTime.utc(2026, 10, 26),
      ),
    );
    final List<Map<Object?, Object?>> shown = [...args('show')];
    expect(shown, hasLength(1));
    final Map<Object?, Object?> post = shown.single;
    expect(post['id'], systemNotificationId(weekly.key));
    expect(post['title'], 'Ready');
    expect(post['payload'], routePayload('/insights/reports/weekly'));
    final Map<Object?, Object?> android =
        post['platformSpecifics']! as Map<Object?, Object?>;
    expect(android['channelId'], 'weekly_summary');
    expect(android['channelName'], 'Weekly summary');
    expect(android['tag'], 'weekly_summary');
    expect(android['onlyAlertOnce'], isTrue);
    expect(android['importance'], Importance.low.value);
  });

  test('a route payload reads back; a reminder payload does not name one', () {
    expect(routeOfPayload(routePayload('/settings')), '/settings');
    expect(routeOfPayload('{"bill":"b","due":"2026-10-27","at":"x"}'), isNull);
    expect(routeOfPayload('not json'), isNull);
  });

  test('the composite tells every notifier past a failure', () async {
    final _Recording after = _Recording();
    await CompositeNotifier([_Failing(), after]).notify(
      WeeklySummaryNotification(
        weekStart: LocalDate(2026, 10, 19),
        raisedAt: DateTime.utc(2026, 10, 26),
      ),
    );
    expect(after.keys, ['weekly/2026-10-19']);
  });

  test('the permission is asked once, ever', () async {
    final FakeReminderScheduler scheduler = FakeReminderScheduler(
      granted: false,
      grantOnRequest: false,
    );
    final InMemoryAppMetaStore meta = InMemoryAppMetaStore();
    final NotificationPermission permission = NotificationPermission(
      scheduler,
      meta,
      () => DateTime.utc(2026, 10, 31),
    );
    expect(await permission.asked(), isFalse);
    expect(await permission.ask(), isFalse);
    expect(await permission.ask(), isFalse);
    expect(scheduler.permissionRequests, 1);
    expect(await permission.asked(), isTrue);
    scheduler.granted = true;
    expect(await permission.ask(), isTrue);
    expect(scheduler.permissionRequests, 1);
    await scheduler.close();
  });
}
