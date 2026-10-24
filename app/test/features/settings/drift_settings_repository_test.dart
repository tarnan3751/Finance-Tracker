// The Drift settings repository against the shared contract, and its reading of stored
// values it does not recognize.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/settings/data/drift_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contract/settings_repository_contract.dart';

void main() {
  late AppDatabase database;
  runSettingsRepositoryContract(
    () async => DriftSettingsRepository(
      database = AppDatabase(NativeDatabase.memory()),
    ),
    dispose: () => database.close(),
  );

  test('a field it cannot read is its default', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.customStatement(
      'INSERT INTO app_settings (key, value) VALUES '
      "('theme_mode', '\"sepia\"'), ('use_dynamic_color', 'not json')",
    );
    expect(
      await DriftSettingsRepository(database).read(),
      const Settings.defaults(),
    );
    await database.customStatement(
      "UPDATE app_settings SET value = 'false' WHERE key = 'use_dynamic_color'",
    );
    expect(
      await DriftSettingsRepository(database).read(),
      const Settings.defaults().copyWith(useDynamicColor: false),
    );
  });
}
