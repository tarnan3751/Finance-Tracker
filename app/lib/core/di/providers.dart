/// The app-wide providers: the flavor's configuration, the clock and the settings
/// repository, and the overrides `bootstrap` installs for a flavor.
///
/// Feature providers live in their feature's `application/` folder; what is here is what
/// every feature may depend on.
library;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/data/settings_repository.dart';
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

/// Where the app preferences are kept: in memory by default; Phase 1c overrides it with
/// the Drift implementation for dev and prod.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final InMemorySettingsRepository repository = InMemorySettingsRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// The provider overrides that make up the app for [config].
List<Override> overridesFor(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
];
