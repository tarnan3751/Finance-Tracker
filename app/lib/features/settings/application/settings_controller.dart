/// The settings the UI shows and changes, backed by `settingsRepositoryProvider`.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_controller.g.dart';

/// The current [Settings] as an `AsyncValue`, following the repository's stream, and
/// the two changes the settings screen makes.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Stream<Settings> build() => ref.watch(settingsRepositoryProvider).watch();

  /// Saves [mode] as the theme mode.
  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((settings) => settings.copyWith(themeMode: mode));

  /// Saves whether dynamic color is used.
  Future<void> setUseDynamicColor(bool enabled) =>
      _update((settings) => settings.copyWith(useDynamicColor: enabled));

  /// The last update in flight. Each update reads, changes and saves, so two running at
  /// once would both read the same settings and the second save would undo the first;
  /// every update therefore starts after the previous one has finished, failed or not.
  Future<void> _lastUpdate = Future<void>.value();

  Future<void> _update(Settings Function(Settings) change) {
    final Future<void> update = _lastUpdate
        .catchError((Object _) {})
        .then((_) => _apply(change));
    _lastUpdate = update;
    return update;
  }

  Future<void> _apply(Settings Function(Settings) change) async {
    if (!ref.mounted) return;
    final repository = ref.read(settingsRepositoryProvider);
    final Settings current = await repository.read();
    if (!ref.mounted) return;
    await repository.save(change(current));
  }
}
