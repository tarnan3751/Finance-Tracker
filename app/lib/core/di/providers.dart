/// The app-wide providers: the flavor's configuration and the clock, and the overrides
/// `bootstrap` installs for a flavor.
///
/// Feature providers live in their feature's `application/` folder; what is here is what
/// every feature may depend on.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The running flavor's configuration. There is no default: `bootstrap` (or a test)
/// overrides it through [overridesFor].
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider is supplied by bootstrap through overridesFor(config)',
);

/// The clock every "now" and "today" comes from.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();

/// The provider overrides that make up the app for [config].
List<Override> overridesFor(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
];
