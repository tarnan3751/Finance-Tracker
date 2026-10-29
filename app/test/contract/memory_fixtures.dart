// Fixtures of the in-memory and demo implementations for the contract suites: the
// repositories over one fresh InMemoryStore (the demo one loaded with an empty seed and no
// rules or budgets, so the suites' "fresh repository" cases hold; the real seed has its own test).
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/demo_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/bills/data/demo_bill_repository.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/budgets/data/demo_budget_repository.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:finance_tracker/features/categories/data/demo_category_repository.dart';
import 'package:finance_tracker/features/categories/data/in_memory_category_repository.dart';
import 'package:finance_tracker/features/investments/data/demo_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/demo_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_investment_transaction_repository.dart';
import 'package:finance_tracker/features/items/data/demo_item_repository.dart';
import 'package:finance_tracker/features/items/data/in_memory_item_repository.dart';
import 'package:finance_tracker/features/liabilities/data/demo_liability_repository.dart';
import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart';
import 'package:finance_tracker/features/recurring/data/demo_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:finance_tracker/features/rules/data/demo_rule_repository.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:finance_tracker/features/settings/data/demo_settings_repository.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/demo_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:sync_engine/sync_engine.dart';

import '../helpers/test_seed.dart';
import 'repository_fixture.dart';

/// A fixture factory and its dispose, for one implementation.
typedef FixtureFactory = ({
  Future<RepositoryFixture> Function() create,
  Future<void> Function() dispose,
});

/// The in-memory implementation, recording into an in-memory sync store.
FixtureFactory inMemoryFixtures() {
  late InMemoryStore store;
  return (
    create: () async {
      final SteppingClock clock = SteppingClock();
      store = InMemoryStore(clock);
      final InMemorySyncStore syncStore = InMemorySyncStore();
      final HlcClock hlc = HlcClock('device-a');
      final ChangeRecorder recorder = EngineChangeRecorder(
        syncStore,
        () async => hlc,
        () => clock.nowUtc().millisecondsSinceEpoch,
      );
      return RepositoryFixture(
        clock: clock,
        syncStore: syncStore,
        accounts: InMemoryAccountRepository(store, recorder: recorder),
        transactions: InMemoryTransactionRepository(store, recorder: recorder),
        categories: InMemoryCategoryRepository(store, recorder: recorder),
        settings: InMemorySettingsRepository(recorder: recorder),
        items: InMemoryItemRepository(store),
        rules: InMemoryRuleRepository(clock, recorder: recorder),
        budgets: InMemoryBudgetRepository(clock, recorder: recorder),
        bills: InMemoryBillRepository(clock, recorder: recorder),
        streams: InMemoryRecurringStreamRepository(clock, recorder: recorder),
        liabilities: InMemoryLiabilityRepository(),
        holdings: InMemoryHoldingRepository(),
        investmentTransactions: InMemoryInvestmentTransactionRepository(),
      );
    },
    dispose: () => store.close(),
  );
}

/// The demo implementation.
FixtureFactory demoFixtures() {
  late InMemoryStore store;
  return (
    create: () async {
      final SteppingClock clock = SteppingClock();
      store = InMemoryStore(clock);
      loadDemoSeed(store, const DemoSeed.empty());
      return RepositoryFixture(
        clock: clock,
        accounts: DemoAccountRepository(store),
        transactions: DemoTransactionRepository(store),
        categories: DemoCategoryRepository(store),
        settings: DemoSettingsRepository(),
        items: DemoItemRepository(store),
        rules: DemoRuleRepository(clock),
        budgets: DemoBudgetRepository(clock),
        bills: DemoBillRepository(clock),
        streams: DemoRecurringStreamRepository(clock),
        liabilities: DemoLiabilityRepository(),
        holdings: DemoHoldingRepository(),
        investmentTransactions: DemoInvestmentTransactionRepository(),
      );
    },
    dispose: () => store.close(),
  );
}
