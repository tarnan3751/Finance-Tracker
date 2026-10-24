/// The demo flavor's [CategoryRepository]: the in-memory repository over the demo store.
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/categories/data/in_memory_category_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';

/// The demo's categories; changes last until the app closes and are never
/// recorded for sync.
final class DemoCategoryRepository extends InMemoryCategoryRepository {
  /// The repository over the demo [store].
  DemoCategoryRepository(super.store)
    : super(recorder: const NoChangeRecorder());
}
