// The wiring `startApp` builds for each app mode (`overridesFor`), for a test that starts
// the app on a mode store of its own: the platform seams with no host implementation
// left out (their fakes are the defaults; the notification plugin one that answers
// nothing), the wipe the in-memory one over the test's store, the clock, the package
// info and the device name pinned, the demo seed the file's shared one (seed.dart), and
// in the live mode the database in memory and the restore offer answered.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/app_shortcuts_provider.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/connectivity_provider.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/launch_intent_provider.dart';
import 'package:finance_tracker/core/platform/local_notifications.dart';
import 'package:finance_tracker/core/platform/local_notifications_provider.dart';
import 'package:finance_tracker/core/platform/monotonic_clock_provider.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/platform/screen_security_provider.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/settings/application/package_info.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';
import 'restore_offer.dart';
import 'seed.dart';

/// The wiring for each configuration `startApp` resolves over [modes], with [extra]
/// last (a test's fake server, for one).
List<Override> Function(AppConfig config) modeWiring(
  AppModeStore modes, {
  List<Override> extra = const [],
}) =>
    (config) => [
      for (final Override o in overridesFor(config))
        if (!_replaced.any(
          // ignore: invalid_use_of_visible_for_testing_member
          (p) => identical(o.origin, p),
        ))
          o,
      appModeStoreProvider.overrideWithValue(modes),
      localNotificationsProvider.overrideWithValue(
        LocalNotifications(_QuietPlugin()),
      ),
      clockProvider.overrideWithValue(testClock),
      packageInfoProvider.overrideWith((ref) async => testPackageInfo),
      appVersionProvider.overrideWith((ref) async => testPackageInfo.version),
      deviceNameProvider.overrideWith((ref) async => 'Pixel 6'),
      cachedDemoSeedOverride,
      if (config.isLive) ...[
        databaseProvider.overrideWith((ref) {
          final AppDatabase database = AppDatabase(NativeDatabase.memory());
          ref.onDispose(() => databaseClosing[database] = database.close());
          return database;
        }),
        restoreOfferProvider.overrideWith(AnsweredRestoreOffer.new),
      ],
      ...extra,
    ];

final List<Object> _replaced = [
  appModeStoreProvider,
  localWipeProvider,
  monotonicClockProvider,
  deviceAuthProvider,
  widgetWriterProvider,
  launchIntentProvider,
  appShortcutsProvider,
  screenSecurityProvider,
  connectivityProvider,
  backgroundWorkProvider,
  reminderSchedulerProvider,
  appNotifierProvider,
  notificationChannelsProvider,
  systemSettingsProvider,
];

/// The notification plugin with no platform: initialized, and launched by no tap.
final class _QuietPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => null;
}
