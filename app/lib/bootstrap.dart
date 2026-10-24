/// Startup shared by the three entry points: checks the configuration, then runs the app.
///
/// Phase 1 plugs its Riverpod container and the database into this function.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/legacy/legacy_app.dart';
import 'package:flutter/widgets.dart';

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
  runApp(LegacyFinanceTrackerApp(config: config));
}
