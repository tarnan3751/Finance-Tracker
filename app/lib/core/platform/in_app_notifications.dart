/// The app's notifications as the app itself shows them: the in-app [Notifier]
/// (`notifier.dart`), which every flavor uses until Phase 8 adds Android's notification
/// channels. The list lives in memory: it starts empty at each launch (what raised a
/// notification records that it did, so nothing is raised twice).
library;

import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_notifications.g.dart';

/// How many notifications the in-app list keeps; older ones drop off.
const int inAppNotificationLimit = 50;

/// One notification in the in-app list and whether the user has seen it.
typedef InAppNotification = ({AppNotification notification, bool read});

/// The in-app list, newest first, at most [inAppNotificationLimit] long.
@Riverpod(keepAlive: true)
class InAppNotifications extends _$InAppNotifications {
  @override
  List<InAppNotification> build() => const [];

  /// Puts [notification] first, unread, replacing one with the same key.
  void add(AppNotification notification) => state = List.unmodifiable(
    [
      (notification: notification, read: false),
      ...state.where((n) => n.notification.key != notification.key),
    ].take(inAppNotificationLimit),
  );

  /// Marks the notification whose key is [key] read.
  void markRead(String key) => state = List.unmodifiable([
    for (final InAppNotification n in state)
      n.notification.key == key
          ? (notification: n.notification, read: true)
          : n,
  ]);

  /// Marks every notification read.
  void markAllRead() => state = List.unmodifiable([
    for (final InAppNotification n in state)
      (notification: n.notification, read: true),
  ]);
}

/// The [Notifier] that adds to [InAppNotifications].
final class InAppNotifier implements Notifier {
  /// The notifier over [_list].
  InAppNotifier(this._list);

  final InAppNotifications _list;

  @override
  Future<void> notify(AppNotification notification) async =>
      _list.add(notification);
}

/// Where the app's notifications go: the in-app list, in every flavor. Named explicitly:
/// the generator would drop the `Notifier` suffix, and a bare `notifier` would generate a
/// class clashing with Riverpod's own `NotifierProvider`.
@Riverpod(keepAlive: true, name: 'appNotifierProvider')
Notifier appNotifier(Ref ref) =>
    InAppNotifier(ref.watch(inAppNotificationsProvider.notifier));
