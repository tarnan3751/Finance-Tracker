/// The demo flavor's [SettingsRepository]: the in-memory one, starting from the defaults.
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';

/// The demo's settings; changes last until the app closes and are never
/// recorded for sync.
final class DemoSettingsRepository extends InMemorySettingsRepository {
  /// The repository, at the defaults.
  DemoSettingsRepository() : super(recorder: const NoChangeRecorder());
}
