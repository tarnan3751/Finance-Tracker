/// Where the app preferences are kept. The in-memory implementation is the default in
/// every flavor until Phase 1c adds the Drift one for dev and prod; both pass
/// `test/features/settings/settings_repository_contract.dart`.
library;

import 'package:finance_tracker/features/settings/domain/settings.dart';

/// Reads, watches and saves the one [Settings] record of this install.
abstract interface class SettingsRepository {
  /// The current settings, then every saved change. A new listener gets the current
  /// value first; [Settings.defaults] before anything was saved.
  Stream<Settings> watch();

  /// The current settings; [Settings.defaults] before anything was saved.
  Future<Settings> read();

  /// Replaces the stored settings with [settings] and notifies every watcher.
  Future<void> save(Settings settings);
}
