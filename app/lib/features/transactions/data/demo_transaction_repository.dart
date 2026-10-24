/// The demo flavor's [TransactionRepository]: the in-memory repository over a store
/// loaded with the demo seed (`core/db/demo_seed.dart`).
library;

import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';

/// The demo seed's transactions; changes last until the app closes.
final class DemoTransactionRepository extends InMemoryTransactionRepository {
  /// The repository over the demo [store] (see `loadDemoSeed`).
  DemoTransactionRepository(super.store);
}
