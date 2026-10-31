/// The one `flutter_local_notifications` 22.3.2 instance of dev and prod, initialized once
/// per engine (`docs/reference/app-core.md`, **Notifications**).
///
/// The plugin keeps a single tap callback per engine, and a second `initialize` replaces
/// the first's, so everything that posts through the plugin (the bill reminders,
/// `local_notifications_scheduler.dart`) shares this initialization: the small icon
/// `ic_stat_bill`, and the tapped payloads, the one that launched the app first, handed to
/// [reminderPayloads] when they are a reminder's ([ScheduledReminder.fromPayload]) and to
/// [routes] when they name a route ([routePayload]: the system notifications').
library;

import 'dart:async';
import 'dart:convert';

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
  final StreamController<String> _routes = StreamController<String>();
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
    } else if (routeOfPayload(payload) case final String route) {
      if (!_routes.isClosed) _routes.add(route);
    }
  }

  /// The routes of the system notifications tapped, the one that launched the app first.
  Stream<String> get routes {
    unawaited(ready());
    return _routes.stream;
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

/// The payload of a notification whose tap opens [route]: `{"route": route}`.
String routePayload(String route) => jsonEncode({'route': route});

/// The route [payload] names, or null when it names none.
String? routeOfPayload(String payload) {
  try {
    if (jsonDecode(payload) case {'route': final String route}) return route;
  } on FormatException {
    // Not ours.
  }
  return null;
}
