/// The [SettingsRepository] of the dev and prod flavors, over the `app_settings` table:
/// one row per field, its value JSON (`theme_mode` a string, `use_dynamic_color` a bool),
/// so Phase 2's sync can merge settings field by field. A missing or unreadable value
/// reads as that field's default.
library;

import 'dart:convert';

import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';
import 'package:shared_models/shared_models.dart';

const String _themeMode = 'theme_mode';
const String _useDynamicColor = 'use_dynamic_color';

/// Settings in [AppDatabase]. Every save records the fields it changed in the settings
/// record `settings/local` through [_recorder], in the same database transaction. The
/// settings always exist (the defaults before any save), so a save is an update against
/// what was stored, and first saves on two devices merge field by field.
final class DriftSettingsRepository implements SettingsRepository {
  /// The repository over [_database], recording saves through `recorder`.
  DriftSettingsRepository(this._database, {required this._recorder});

  final AppDatabase _database;
  final ChangeRecorder _recorder;

  @override
  Stream<Settings> watch() => _database
      .select(_database.appSettings)
      .watch()
      .map(settingsFromRows)
      .distinct();

  @override
  Future<Settings> read() async =>
      settingsFromRows(await _database.select(_database.appSettings).get());

  @override
  Future<void> save(Settings settings) => _database.transaction(() async {
    final List<AppSettingRow> rows = await _database
        .select(_database.appSettings)
        .get();
    await _database.batch((batch) {
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
    await _recorder.record(
      EntityType.settings,
      settingsRecordId,
      settingsRecordJson(settingsFromRows(rows)),
      settingsRecordJson(settings),
    );
  });
}

/// The [Settings] the `app_settings` [rows] hold: a missing or unreadable value is that
/// field's default.
Settings settingsFromRows(List<AppSettingRow> rows) {
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
