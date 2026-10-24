/// The `app_settings` table: the app preferences, one row per setting, the value JSON.
library;

import 'package:drift/drift.dart';

/// A setting: [key] is the field name, [value] its JSON encoding.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
