/// What Settings → Notifications shows (`docs/reference/background.md`, **Settings**),
/// read from the platform each time the screen asks (it asks again on resume, since the
/// user may have changed a channel in Android's settings): what the app and each channel
/// may show, whether the permission was asked, the background sync's switch, where
/// WorkManager has it and its last run, and whether Android restricts the app's
/// background work.
library;

import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/background/background_sync_watcher.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/notification_channels.dart';
import 'package:finance_tracker/core/platform/notification_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_overview.g.dart';

/// The screen's state.
typedef NotificationsOverview = ({
  NotificationsState notifications,
  bool asked,
  bool backgroundAvailable,
  bool backgroundEnabled,
  BackgroundWorkState schedule,
  BackgroundRun? lastRun,
  bool restricted,
});

/// The state, read when the screen asks.
@riverpod
Future<NotificationsOverview> notificationsOverview(Ref ref) async {
  final bool available = ref.watch(localDataSyncsProvider);
  return (
    notifications: await ref.read(notificationChannelsProvider).state(),
    asked: await ref.read(notificationPermissionProvider).asked(),
    backgroundAvailable: available,
    backgroundEnabled: await ref
        .read(backgroundSyncWatcherProvider.notifier)
        .enabled(),
    schedule: await ref.read(backgroundWorkProvider).periodicState(),
    lastRun: BackgroundRun.parse(
      await ref.read(appMetaStoreProvider).read(AppMetaKeys.backgroundLastRun),
    ),
    restricted: await ref.read(systemSettingsProvider).backgroundRestricted(),
  );
}
