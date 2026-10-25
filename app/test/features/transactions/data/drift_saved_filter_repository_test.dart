// The Drift SavedFilterRepository against the shared contract.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/transactions/data/drift_saved_filter_repository.dart';

import '../../../contract/repository_fixture.dart';
import '../../../contract/saved_filter_repository_contract.dart';

void main() {
  late AppDatabase database;
  runSavedFilterRepositoryContract(() async {
    database = AppDatabase(NativeDatabase.memory());
    return DriftSavedFilterRepository(database, SteppingClock());
  }, dispose: () => database.close());
}
