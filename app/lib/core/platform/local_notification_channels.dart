/// The [NotificationChannels] of dev and prod, over `flutter_local_notifications` 22.3.2
/// (the app's one initialization, `local_notifications.dart`) and the app's
/// `system_settings` channel: a channel is created with `createNotificationChannel`
/// (again at each start with the current locale's name, which Android takes as a rename,
/// never changing its importance); the app is enabled when `areNotificationsEnabled`
/// says so; a channel is off when its importance reads `none`
/// (`getNotificationChannels`), which `areNotificationsEnabled` does not show.
library;

import 'package:finance_tracker/core/platform/local_notifications.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/system_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The channels through the platform.
final class LocalNotificationChannels implements NotificationChannels {
  /// The channels over [_notifications] and [_settings].
  LocalNotificationChannels(this._notifications, this._settings);

  final LocalNotifications _notifications;
  final SystemSettings _settings;

  Future<AndroidFlutterLocalNotificationsPlugin?> _android() async {
    await _notifications.ready();
    return _notifications.android;
  }

  @override
  Future<void> ensure(Map<AppChannel, ChannelText> texts) async {
    final AndroidFlutterLocalNotificationsPlugin? android = await _android();
    if (android == null) return;
    for (final MapEntry(key: AppChannel channel, value: ChannelText text)
        in texts.entries) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          channel.id,
          text.name,
          description: text.description,
          importance: switch (channel.importance) {
            ChannelImportance.low => Importance.low,
            ChannelImportance.standard => Importance.defaultImportance,
          },
        ),
      );
    }
  }

  @override
  Future<NotificationsState> state() async {
    final AndroidFlutterLocalNotificationsPlugin? android = await _android();
    if (android == null) {
      return const NotificationsState(appEnabled: false, blocked: {});
    }
    final bool enabled = await android.areNotificationsEnabled() ?? false;
    final Map<String, AppChannel> byId = {
      for (final AppChannel c in AppChannel.values) c.id: c,
    };
    return NotificationsState(
      appEnabled: enabled,
      blocked: {
        for (final AndroidNotificationChannel c
            in await android.getNotificationChannels() ?? const [])
          if (c.importance == Importance.none && byId[c.id] != null)
            byId[c.id]!,
      },
    );
  }

  @override
  Future<void> openChannelSettings(AppChannel channel) =>
      _settings.openChannelSettings(channel.id);

  @override
  Future<void> openAppSettings() async =>
      (await _android())?.openAppNotificationSettings();
}
