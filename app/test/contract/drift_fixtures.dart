// Fixtures of the Drift implementation for the contract suites: the three repositories
// over one fresh in-memory AppDatabase (NativeDatabase.memory, unencrypted; the encrypted
// open path has its own tests in test/core/db/open_database_test.dart).
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';

import 'memory_fixtures.dart';
import 'repository_fixture.dart';

/// The Drift implementation.
FixtureFactory driftFixtures() {
  late AppDatabase database;
  return (
    create: () async {
      database = AppDatabase(NativeDatabase.memory());
      final SteppingClock clock = SteppingClock();
      return RepositoryFixture(
        clock: clock,
        accounts: DriftAccountRepository(database, clock),
        transactions: DriftTransactionRepository(database, clock),
        categories: DriftCategoryRepository(database, clock),
      );
    },
    dispose: () => database.close(),
  );
}
