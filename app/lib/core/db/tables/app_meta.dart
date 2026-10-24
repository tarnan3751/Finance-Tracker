/// The `app_meta` table: facts about this install (`legacy_import_done`, `install_date`).
library;

import 'package:drift/drift.dart';

/// A fact about the install.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
