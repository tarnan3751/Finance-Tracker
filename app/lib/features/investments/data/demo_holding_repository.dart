/// The demo flavor's [HoldingRepository]: the in-memory one, holding the persona's
/// brokerage (`holdingRepositoryProvider`).
library;

import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';

/// The demo's holdings; a pull after a Link replaces them with what the in-app fake
/// serves, which is the same seed.
final class DemoHoldingRepository extends InMemoryHoldingRepository {
  /// The repository holding `holdings` and `securities`.
  DemoHoldingRepository({super.holdings, super.securities});
}
