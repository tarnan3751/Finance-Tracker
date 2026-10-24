/// The [SettingsRepository] of the dev and prod flavors, over the `app_settings` table:
/// one row per field, its value JSON (`theme_mode` a string, `use_dynamic_color` a bool),
/// so Phase 2's sync can merge settings field by field. A missing or unreadable value
/// reads as that field's default.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';

const String _themeMode = 'theme_mode';
const String _useDynamicColor = 'use_dynamic_color';

/// Settings in [AppDatabase].
final class DriftSettingsRepository implements SettingsRepository {
  /// The repository over [_database].
  DriftSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<Settings> watch() =>
      _database.select(_database.appSettings).watch().map(_fromRows).distinct();

  @override
  Future<Settings> read() async =>
      _fromRows(await _database.select(_database.appSettings).get());

  @override
  Future<void> save(Settings settings) => _database.batch((batch) {
    batch.insertAllOnConflictUpdate(_database.appSettings, [
      AppSettingsCompanion.insert(
        key: _themeMode,
        value: jsonEncode(settings.themeMode.name),
      ),
      AppSettingsCompanion.insert(
        key: _useDynamicColor,
        value: jsonEncode(settings.useDynamicColor),
      ),
    ]);
  });

  Settings _fromRows(List<AppSettingRow> rows) {
    final Map<String, Object?> values = {
      for (final AppSettingRow row in rows) row.key: _decode(row.value),
    };
    const Settings defaults = Settings.defaults();
    final Object? mode = values[_themeMode];
    final Object? dynamicColor = values[_useDynamicColor];
    return Settings(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => defaults.themeMode,
      ),
      useDynamicColor: dynamicColor is bool
          ? dynamicColor
          : defaults.useDynamicColor,
    );
  }

  Object? _decode(String json) {
    try {
      return jsonDecode(json);
    } on FormatException {
      return null;
    }
  }
}
