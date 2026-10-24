/// The demo flavor's [AccountRepository]: the in-memory repository over a store loaded
/// with the demo seed (`core/db/demo_seed.dart`).
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';

/// The demo seed's accounts; changes last until the app closes and are never
/// recorded for sync.
final class DemoAccountRepository extends InMemoryAccountRepository {
  /// The repository over the demo [store] (see `loadDemoSeed`).
  DemoAccountRepository(super.store)
    : super(recorder: const NoChangeRecorder());
}
