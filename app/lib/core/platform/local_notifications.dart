/// The one `flutter_local_notifications` 22.3.2 instance of dev and prod, initialized once
/// per engine (`docs/reference/app-core.md`, **Notifications**).
///
/// The plugin keeps a single tap callback per engine, and a second `initialize` replaces
/// the first's, so everything that posts through the plugin (the bill reminders,
/// `local_notifications_scheduler.dart`) shares this initialization: the small icon
/// `ic_stat_bill`, and the tapped payloads, the one that launched the app first, handed to
/// [reminderPayloads] when they are a reminder's ([ScheduledReminder.fromPayload]).
library;

import 'dart:async';

import 'package:finance_tracker/core/platform/reminder_scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// The plugin, initialized on first use, and the payloads of the notifications tapped.
final class LocalNotifications {
  /// The notifications over [plugin].
  LocalNotifications(this.plugin);

  /// The plugin.
  final FlutterLocalNotificationsPlugin plugin;

  // Not broadcast: a tap that launched the app waits for the first listener.
  final StreamController<String> _reminders = StreamController<String>();
  Future<void>? _initialized;

  /// Initializes the plugin, once; every use awaits it first.
  Future<void> ready() => _initialized ??= _initialize();

  Future<void> _initialize() async {
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_bill'),
      ),
      onDidReceiveNotificationResponse: (response) => _tapped(response.payload),
    );
    final NotificationAppLaunchDetails? launch = await plugin
        .getNotificationAppLaunchDetails();
    if (launch != null && launch.didNotificationLaunchApp) {
      _tapped(launch.notificationResponse?.payload);
    }
  }

  void _tapped(String? payload) {
    if (payload == null) return;
    if (ScheduledReminder.fromPayload(0, null, null, payload) != null) {
      if (!_reminders.isClosed) _reminders.add(payload);
    }
  }

  /// The payloads of the bill reminders tapped, the one that launched the app first.
  Stream<String> get reminderPayloads {
    unawaited(ready());
    return _reminders.stream;
  }

  /// The plugin's Android implementation, or null off Android.
  AndroidFlutterLocalNotificationsPlugin? get android => plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
}
