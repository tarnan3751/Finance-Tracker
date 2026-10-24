/// Startup shared by the three entry points: checks the configuration, sets up logging and
/// time zones, then runs the app inside its Riverpod `ProviderScope`.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/legacy/legacy_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the app for [config]. Throws a [StateError] before anything runs when the prod
/// flavor is given a server URL that is not HTTPS.
Future<void> bootstrap(AppConfig config) async {
  final Uri? serverBaseUrl = config.serverBaseUrl;
  if (config.flavor == Flavor.prod &&
      serverBaseUrl != null &&
      serverBaseUrl.scheme != 'https') {
    throw StateError(
      'The prod flavor needs an https server URL, got $serverBaseUrl',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  setUpLogging(config.flavor);
  forwardUncaughtErrors();
  await setUpTimeZones();
  runApp(
    ProviderScope(
      overrides: overridesFor(config),
      child: LegacyFinanceTrackerApp(config: config),
    ),
  );
}
