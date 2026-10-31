/// The entry point WorkManager's task runs in its own engine
/// (`docs/reference/background.md`, **The isolate**): the process's one-time setup the
/// app's `bootstrap` does (logging with the flavor's sink, the time zones, intl's locale),
/// with every locale's date symbols too (`initializeDateFormatting`; the app gets them
/// from flutter_localizations at its first frame, which this engine never draws); the
/// database opener sets SQLite's temporary directory itself. Then one
/// [runBackgroundCycle] on the flavor's own wiring (`overridesFor`, with no window, so
/// the lock never calls `MainActivity`'s channel, which this engine has not). The flavor comes in
/// the task's input data (`workmanager_background_work.dart`).
library;

import 'dart:io';

import 'package:finance_tracker/bootstrap.dart' show deviceLocale;
import 'package:finance_tracker/core/background/background_cycle.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:finance_tracker/core/platform/workmanager_background_work.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// The task's entry point.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) async {
    final AppConfig config = switch (input?[flavorInputKey]) {
      'dev' => AppConfig.dev(),
      'prod' => AppConfig.prod(),
      _ => AppConfig.demo(),
    };
    setUpLogging(config.flavor);
    await setUpTimeZones();
    Intl.defaultLocale = deviceLocale();
    // Every locale's date symbols, which the app gets from flutter_localizations at its
    // first frame and this engine never draws: a step formatting a date in a locale
    // other than English would throw without them.
    await initializeDateFormatting();
    return runBackgroundCycle(
      BackgroundEnvironment(
        config: config,
        overrides: overridesFor(config, window: false),
        databaseFile: () async => File(
          p.join(
            (await getApplicationSupportDirectory()).path,
            databaseFileName,
          ),
        ),
        wipePending: () async {
          final SharedPreferences preferences =
              await SharedPreferences.getInstance();
          // Another engine may have written it since this one first read.
          await preferences.reload();
          return preferences.getString(DriftLocalWipe.pendingKey) != null;
        },
      ),
    );
  });
}
