/// The demo flavor's [ItemRepository]: the in-memory repository over a store loaded with
/// the demo seed's Items (`core/db/demo_seed.dart`).
library;

import 'package:finance_tracker/features/items/data/in_memory_item_repository.dart';

/// The demo seed's Items, then what the pull against the demo's fake server brings.
final class DemoItemRepository extends InMemoryItemRepository {
  /// The repository over the demo [store] (see `loadDemoSeed`).
  DemoItemRepository(super.store);
}
