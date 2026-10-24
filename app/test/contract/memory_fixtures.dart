// Fixtures of the in-memory and demo implementations for the contract suites: the three
// repositories over one fresh InMemoryStore (the demo one loaded with an empty seed, so the
// suites' "fresh repository" cases hold; the real seed has its own test).
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/demo_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/categories/data/demo_category_repository.dart';
import 'package:finance_tracker/features/categories/data/in_memory_category_repository.dart';
import 'package:finance_tracker/features/items/data/demo_item_repository.dart';
import 'package:finance_tracker/features/items/data/in_memory_item_repository.dart';
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
      );
    },
    dispose: () => store.close(),
  );
}
