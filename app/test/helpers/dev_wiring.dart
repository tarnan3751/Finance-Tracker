// The dev flavor's wiring (`overridesFor`) with the platform seams that have no
// implementation on the host left out, for a test to supply its fakes.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/connectivity_provider.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// `overridesFor(AppConfig.dev())` without the network, the background work, the
/// reminder scheduler and the tray (the in-app list stays the notifier).
List<Override> devWiring() => [
  for (final Override o in overridesFor(AppConfig.dev()))
    if (!_platform.any(
      // ignore: invalid_use_of_visible_for_testing_member
      (p) => identical(o.origin, p),
    ))
      o,
];

final List<Object> _platform = [
  connectivityProvider,
  backgroundWorkProvider,
  reminderSchedulerProvider,
  appNotifierProvider,
];
