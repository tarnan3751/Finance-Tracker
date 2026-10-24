/// The demo flavor's [CategoryRepository]: the in-memory repository over the demo store.
library;

import 'package:finance_tracker/features/categories/data/in_memory_category_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';

/// The demo's categories; changes last until the app closes.
final class DemoCategoryRepository extends InMemoryCategoryRepository {
  /// The repository over the demo [store].
  DemoCategoryRepository(super.store);
}
