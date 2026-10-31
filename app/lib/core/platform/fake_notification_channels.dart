/// The [NotificationChannels] of the demo flavor and the tests: the state a test sets,
/// every call recorded.
library;

import 'package:finance_tracker/core/platform/notification_channels.dart';

/// Channels without a platform.
final class FakeNotificationChannels implements NotificationChannels {
  /// Channels with the app [enabled].
  FakeNotificationChannels({this.enabled = true});

  /// Whether the app may notify.
  bool enabled;

  /// The channels turned off.
  final Set<AppChannel> blocked = {};

  /// The texts of the last [ensure].
  Map<AppChannel, ChannelText>? texts;

  /// How many times [ensure] ran.
  int ensured = 0;

  /// The settings opened, in order: a channel's id, or `app`.
  final List<String> opened = [];

  @override
  Future<void> ensure(Map<AppChannel, ChannelText> texts) async {
    this.texts = texts;
    ensured++;
  }

  @override
  Future<NotificationsState> state() async =>
      NotificationsState(appEnabled: enabled, blocked: {...blocked});

  @override
  Future<void> openChannelSettings(AppChannel channel) async =>
      opened.add(channel.id);

  @override
  Future<void> openAppSettings() async => opened.add('app');
}
