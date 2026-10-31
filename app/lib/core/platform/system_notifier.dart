/// The [Notifier] that posts to the system tray (`docs/reference/background.md`,
/// **Notifications**), beside the in-app list ([CompositeNotifier]): each kind on its
/// channel through the app's one plugin (`local_notifications.dart`), with the text
/// [NoticeText] gives it in the device's locale, tagged with its channel's id (so its
/// notification id, a hash of the notification's key, never meets a bill reminder's), and
/// alerting once (raising the same notification again replaces it quietly). A
/// [BillDueNotification] stays in-app only: the bill's scheduled reminder is its tray
/// notification. The tap opens the notice's route (`LocalNotifications.routes`).
library;

import 'dart:convert';

import 'package:finance_tracker/core/platform/local_notifications.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('notifications');

/// What a tray notification says and where its tap goes.
typedef SystemNotice = ({
  AppChannel channel,
  String title,
  String body,
  String route,
});

/// The tray notice of a notification, or null when it has none.
typedef NoticeText = Future<SystemNotice?> Function(
  AppNotification notification,
);

/// Tells every notifier, in order; one that fails does not stop the others.
final class CompositeNotifier implements Notifier {
  /// The notifier over [_notifiers].
  const CompositeNotifier(this._notifiers);

  final List<Notifier> _notifiers;

  @override
  Future<void> notify(AppNotification notification) async {
    for (final Notifier n in _notifiers) {
      try {
        await n.notify(notification);
      } on Object catch (e) {
        _log.warning('a notification was not shown: ${e.runtimeType}');
      }
    }
  }
}

/// The notification id of [key]: a 31-bit FNV-1a hash.
int systemNotificationId(String key) {
  int hash = 0x811c9dc5;
  for (final int unit in utf8.encode(key)) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// The tray notifier.
final class SystemNotifier implements Notifier {
  /// The notifier over [_notifications], with the channels named by [_channels] and the
  /// texts of [_text].
  SystemNotifier(this._notifications, this._channels, this._text);

  final LocalNotifications _notifications;
  final Map<AppChannel, ChannelText> _channels;
  final NoticeText _text;

  @override
  Future<void> notify(AppNotification notification) async {
    if (notification is BillDueNotification) return;
    final SystemNotice? notice = await _text(notification);
    if (notice == null) return;
    await _notifications.ready();
    final ChannelText? channel = _channels[notice.channel];
    await _notifications.plugin.show(
      id: systemNotificationId(notification.key),
      title: notice.title,
      body: notice.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          notice.channel.id,
          channel?.name ?? notice.channel.id,
          channelDescription: channel?.description,
          importance: switch (notice.channel.importance) {
            ChannelImportance.low => Importance.low,
            ChannelImportance.standard => Importance.defaultImportance,
          },
          tag: notice.channel.id,
          onlyAlertOnce: true,
        ),
      ),
      payload: routePayload(notice.route),
    );
  }
}
