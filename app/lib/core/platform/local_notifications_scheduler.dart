/// The [ReminderScheduler] of dev and prod, over `flutter_local_notifications` 22.3.2
/// (BSD-3; `docs/reference/bills.md`, **The platform boundary**; `build.md` for the
/// receivers, desugaring and the icon).
///
/// Reminders are scheduled with `zonedSchedule` in inexact mode with idle allowed (no
/// exact-alarm permission: Android 14 denies it by default; a reminder may come up to
/// about an hour late), on the one channel `bill_reminders` (Phase 8 adds the others and
/// their settings), through the app's one plugin initialization
/// (`local_notifications.dart`, with the small icon `ic_stat_bill`). The payload is
/// [ScheduledReminder.payload]: the pending set is read back from it, and a tap opens its
/// bill; a reminder that launched the app is replayed into [openedBillIds].
library;

import 'package:finance_tracker/core/platform/local_notifications.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The channel the reminders are posted on.
const String billRemindersChannelId = 'bill_reminders';

/// Bill reminders through the platform's notifications.
final class LocalNotificationsScheduler implements ReminderScheduler {
  /// The scheduler over [_notifications], posting on a channel named [channelName] and
  /// described by [channelDescription] (localized); `now` is the clock past reminders
  /// are checked against.
  LocalNotificationsScheduler(
    this._notifications, {
    required this.channelName,
    required this.channelDescription,
    this._now = DateTime.now,
  });

  final LocalNotifications _notifications;
  final DateTime Function() _now;

  /// The channel's name in the system settings.
  final String channelName;

  /// The channel's description in the system settings.
  final String channelDescription;

  FlutterLocalNotificationsPlugin get _plugin => _notifications.plugin;

  Future<void> _ready() => _notifications.ready();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _notifications.android;

  @override
  Future<bool> ensurePermission({required bool request}) async {
    await _ready();
    final AndroidFlutterLocalNotificationsPlugin? android = _android;
    if (android == null) return false;
    final bool enabled = await android.areNotificationsEnabled() ?? false;
    if (enabled || !request) return enabled;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> replaceAll(List<ScheduledReminder> reminders) async {
    await _ready();
    final Set<int> wanted = {for (final r in reminders) r.id};
    for (final PendingNotificationRequest p
        in await _plugin.pendingNotificationRequests()) {
      if (!wanted.contains(p.id)) await _plugin.cancel(id: p.id);
    }
    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        billRemindersChannelId,
        channelName,
        channelDescription: channelDescription,
      ),
    );
    final DateTime now = _now();
    for (final ScheduledReminder r in reminders) {
      // The plugin refuses a past instant; one can pass between planning and here.
      if (!r.at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: r.at,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.payload,
      );
    }
  }

  @override
  Future<List<ScheduledReminder>> pending() async {
    await _ready();
    return [
      for (final PendingNotificationRequest p
          in await _plugin.pendingNotificationRequests())
        ?ScheduledReminder.fromPayload(p.id, p.title, p.body, p.payload),
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Future<void> cancelAll() async {
    await _ready();
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  Future<void> clearAll() async {
    await _ready();
    await _plugin.cancelAll();
  }

  @override
  Future<void> openSettings() async {
    await _ready();
    await _android?.openAppNotificationSettings();
  }

  @override
  Stream<String> get openedBillIds => _notifications.reminderPayloads.map(
    (payload) => ScheduledReminder.fromPayload(0, null, null, payload)!.billId,
  );
}
