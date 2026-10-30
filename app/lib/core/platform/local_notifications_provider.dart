/// The app's one notifications plugin (`local_notifications.dart`): read only by the dev
/// and prod implementations behind the notification seams (`overridesFor`); the demo
/// flavor and the tests use fakes and never initialize it.
library;

import 'package:finance_tracker/core/platform/local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_notifications_provider.g.dart';

/// The plugin, shared.
@Riverpod(keepAlive: true)
LocalNotifications localNotifications(Ref ref) =>
    LocalNotifications(FlutterLocalNotificationsPlugin());
