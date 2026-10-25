/// The `dismissed_pairs` table: the duplicate candidates the user said are not duplicates
/// (`docs/reference/duplicates.md`; `docs/reference/data.md`, schema 7).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// One dismissed pair: two transaction ids in SQLite's `BINARY` order (`id_a` first) and
/// when the user dismissed it. Local to the device: never recorded in the change log,
/// never synced. No foreign key: a pair whose transactions are gone is harmless.
@DataClassName('DismissedPairRow')
class DismissedPairs extends Table {
  TextColumn get idA => text()();
  TextColumn get idB => text()();
  IntColumn get dismissedAt =>
      integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {idA, idB};

  @override
  List<String> get customConstraints => const ['CHECK (id_a < id_b)'];
}
