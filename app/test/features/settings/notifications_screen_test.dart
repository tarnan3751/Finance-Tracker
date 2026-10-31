// Settings → Notifications over the fakes: a row per channel with its state (on, off,
// off with the whole app), each opening its channel's settings; "Turn on notifications"
// asking once, then opening Android's settings; the background sync's switch with its
// last run, cancelling and scheduling; the demo's note; the restriction note and its
// button; and the Settings row that opens the screen.
import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/fake_background_work.dart';
import 'package:finance_tracker/core/platform/fake_notification_channels.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/platform/system_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Channels whose state cannot be read until [readable].
final class _FailingChannels implements NotificationChannels {
  bool readable = false;
  final FakeNotificationChannels _inner = FakeNotificationChannels();

  @override
  Future<void> ensure(Map<AppChannel, ChannelText> texts) =>
      _inner.ensure(texts);

  @override
  Future<NotificationsState> state() async =>
      readable ? _inner.state() : throw StateError('no platform');

  @override
  Future<void> openChannelSettings(AppChannel channel) =>
      _inner.openChannelSettings(channel);

  @override
  Future<void> openAppSettings() => _inner.openAppSettings();
}

void main() {
  late FakeNotificationChannels channels;
  late FakeSystemSettings settings;
  late FakeBackgroundWork work;
  late InMemoryAppMetaStore meta;
  late FakeReminderScheduler scheduler;

  setUp(() {
    channels = FakeNotificationChannels();
    settings = FakeSystemSettings();
    work = FakeBackgroundWork();
    meta = InMemoryAppMetaStore();
    scheduler = FakeReminderScheduler();
  });
  tearDown(() => scheduler.close());

  Future<void> open(
    WidgetTester tester, {
    bool syncs = true,
    NotificationChannels? using,
  }) async {
    await pumpApp(
      tester,
      initialLocation: '/settings/notifications',
      overrides: [
        notificationChannelsProvider.overrideWithValue(using ?? channels),
        systemSettingsProvider.overrideWithValue(settings),
        backgroundWorkProvider.overrideWithValue(work),
        appMetaStoreProvider.overrideWithValue(meta),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        localDataSyncsProvider.overrideWithValue(syncs),
        // No session for the controller to run against the in-memory data.
        syncDeviceIdProvider.overrideWithValue(null),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each channel shows its state and opens its settings', (
    tester,
  ) async {
    channels.blocked.add(AppChannel.weeklySummary);
    await open(tester);
    expect(find.text('Budget alerts'), findsOneWidget);
    expect(find.text('Bill reminders'), findsOneWidget);
    expect(find.text('Weekly summary'), findsOneWidget);
    expect(find.text('Sync problems'), findsOneWidget);
    expect(find.textContaining('\nOn'), findsNWidgets(3));
    expect(find.textContaining('\nOff'), findsOneWidget);
    expect(find.text('Notifications are off for this app'), findsNothing);
    await tester.tap(find.text('Weekly summary'));
    expect(channels.opened, ['weekly_summary']);
  });

  testWidgets('with the app off, Turn on notifications asks once, then opens '
      "Android's settings", (tester) async {
    channels.enabled = false;
    scheduler
      ..granted = false
      ..grantOnRequest = false;
    await open(tester);
    expect(find.text('Notifications are off for this app'), findsOneWidget);
    expect(
      find.textContaining('Off: notifications are off for this app'),
      findsNWidgets(4),
    );
    await tester.tap(find.text('Turn on notifications'));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);
    expect(channels.opened, isEmpty);
    await tester.tap(find.text('Turn on notifications'));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);
    expect(channels.opened, ['app']);
  });

  testWidgets('the background sync switch, its last run, and the restriction', (
    tester,
  ) async {
    await meta.write(
      AppMetaKeys.backgroundLastRun,
      BackgroundRun(
        at: DateTime.utc(2026, 10, 24, 14),
        result: BackgroundResult.offline,
        delegated: false,
      ).toJson(),
    );
    settings.restricted = true;
    await open(tester);
    await tester.scrollUntilVisible(find.text('App settings'), 100);
    expect(find.textContaining('Not scheduled'), findsOneWidget);
    expect(find.textContaining(': no network'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(work.calls.last.method, 'cancel');
    expect(await meta.read(AppMetaKeys.backgroundSyncEnabled), 'false');
    await tester.tap(find.text('App settings'));
    expect(settings.opened, ['details']);
  });

  testWidgets('the demo has no background sync', (tester) async {
    await open(tester, syncs: false);
    await tester.scrollUntilVisible(
      find.text('Not available in the demo'),
      100,
    );
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('Settings opens the screen', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [
        notificationChannelsProvider.overrideWithValue(channels),
        systemSettingsProvider.overrideWithValue(settings),
      ],
    );
    await tester.scrollUntilVisible(
      find.text('Alerts, reminders and background sync'),
      200,
    );
    await tester.ensureVisible(
      find.text('Alerts, reminders and background sync'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alerts, reminders and background sync'));
    await tester.pumpAndSettle();
    expect(find.text('Budget alerts'), findsOneWidget);
  });

  testWidgets('a state that cannot be read says so, and Try again reads it', (
    tester,
  ) async {
    final _FailingChannels failing = _FailingChannels();
    await open(tester, using: failing);
    expect(
      find.text('The notification settings could not be read'),
      findsOneWidget,
    );
    failing.readable = true;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Budget alerts'), findsOneWidget);
  });

  testWidgets("the schedule line is WorkManager's, and a held run says so", (
    tester,
  ) async {
    await meta.write(
      AppMetaKeys.backgroundLastRun,
      BackgroundRun(
        at: DateTime.utc(2026, 10, 24, 14),
        result: BackgroundResult.held,
        delegated: true,
      ).toJson(),
    );
    await open(tester);
    await tester.scrollUntilVisible(find.byType(Switch), 100);
    expect(
      find.textContaining('Not scheduled: it starts once you sign in'),
      findsOneWidget,
      reason: 'signed out here, so nothing is scheduled',
    );
    expect(
      find.textContaining('held until the restore offer is answered'),
      findsOneWidget,
    );
    await work.schedulePeriodicSync(
      every: backgroundSyncEvery,
      constraints: backgroundSyncConstraints,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('About every hour'), findsOneWidget);
  });
}
