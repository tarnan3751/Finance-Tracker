// Fixtures of the Drift implementation for the contract suites: the three repositories
// and the settings over one fresh in-memory AppDatabase, recording into its sync store (NativeDatabase.memory, unencrypted; the encrypted
// open path has its own tests in test/core/db/open_database_test.dart).
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/bills/data/drift_bill_repository.dart';
import 'package:finance_tracker/features/budgets/data/drift_budget_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/items/data/drift_item_repository.dart';
import 'package:finance_tracker/features/liabilities/data/drift_liability_repository.dart';
import 'package:finance_tracker/features/recurring/data/drift_recurring_stream_repository.dart';
import 'package:finance_tracker/features/rules/data/drift_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/drift_settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:sync_engine/sync_engine.dart';

import 'memory_fixtures.dart';
import 'repository_fixture.dart';

/// The Drift implementation; [fullTextSearch] false opens it as a SQLite without FTS5.
FixtureFactory driftFixtures({bool fullTextSearch = true}) {
  late AppDatabase database;
  return (
    create: () async {
      database = AppDatabase(
        NativeDatabase.memory(),
        allowFullTextSearch: fullTextSearch,
      );
      final SteppingClock clock = SteppingClock();
      final DriftSyncStore syncStore = DriftSyncStore(database, clock);
      final HlcClock hlc = HlcClock('device-a');
      final ChangeRecorder recorder = EngineChangeRecorder(
        syncStore,
        () async => hlc,
        () => clock.nowUtc().millisecondsSinceEpoch,
      );
      return RepositoryFixture(
        clock: clock,
        syncStore: syncStore,
        accounts: DriftAccountRepository(database, clock, recorder: recorder),
        transactions: DriftTransactionRepository(
          database,
          clock,
          recorder: recorder,
        ),
        categories: DriftCategoryRepository(
          database,
          clock,
          recorder: recorder,
        ),
        settings: DriftSettingsRepository(database, recorder: recorder),
        items: DriftItemRepository(database),
        rules: DriftRuleRepository(database, clock, recorder: recorder),
        budgets: DriftBudgetRepository(database, clock, recorder: recorder),
        bills: DriftBillRepository(database, clock, recorder: recorder),
        streams: DriftRecurringStreamRepository(
          database,
          clock,
          recorder: recorder,
        ),
        liabilities: DriftLiabilityRepository(database, clock),
      );
    },
    dispose: () => database.close(),
  );
}
