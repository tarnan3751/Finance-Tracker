// The schema's migrations against the dumped schemas in drift_schemas/ (data.md, "Changing
// the schema"). Schema 1 is validated as created; from schema 2 on, each step opens the
// previous version's database with data, migrates it, and checks the data and the schema.
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('every schema version up to the current one has a dump', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    expect(GeneratedHelper.versions, [
      for (int v = 1; v <= database.schemaVersion; v++) v,
    ]);
  });

  test('a new database matches the schema 1 dump', () async {
    final AppDatabase database = AppDatabase(await verifier.startAt(1));
    addTearDown(database.close);
    await verifier.migrateAndValidate(database, 1);
  });

  // Schema 2 adds: `verifier.schemaAt(1)`, rows inserted through its raw database,
  // `AppDatabase(schema.newConnection())`, `migrateAndValidate(database, 2)`, then reads
  // that check the rows survived.
}
