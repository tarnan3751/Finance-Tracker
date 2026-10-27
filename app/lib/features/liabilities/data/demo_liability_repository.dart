/// The demo flavor's [LiabilityRepository]: the in-memory one, holding the persona's
/// liabilities (`liabilityRepositoryProvider`).
library;

import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart';
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';

/// The demo's liabilities; a pull after a Link replaces them with what the in-app fake
/// serves, which is the same seed.
final class DemoLiabilityRepository extends InMemoryLiabilityRepository {
  /// The repository holding `initial`.
  DemoLiabilityRepository({super.initial});
}
