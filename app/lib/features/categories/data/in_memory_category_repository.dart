/// A [CategoryRepository] over an [InMemoryStore]: what tests use.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Categories held in [store]. Every write but the seeding records each category it
/// changed through [recorder] after the store's synchronous write.
base class InMemoryCategoryRepository implements CategoryRepository {
  /// The repository over [store], recording through [recorder].
  InMemoryCategoryRepository(this.store, {required this.recorder});

  /// The state shared with the account and transaction repositories.
  final InMemoryStore store;

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  @override
  Stream<List<Category>> watchAll() =>
      store.watch(store.categories, same: sameList);

  @override
  Stream<Category?> watchById(String id) =>
      store.watch(() => store.category(id));

  @override
  Future<void> upsert(Category category) async {
    final Map<String, Map<String, Object?>> before = store.categoryRecordsOf(
      category.id,
    );
    store.upsertCategory(category);
    await recordEach(recorder, EntityType.category, before, {
      category.id: store.categoryRecordsOf(category.id)[category.id]!,
    });
  }

  @override
  Future<void> delete(String id) async {
    final Map<String, Map<String, Object?>> before = store.categoryRecordsOf(
      id,
    );
    store.deleteCategory(id);
    await recordEach(
      recorder,
      EntityType.category,
      before,
      store.categoryRecordsOf(id),
    );
  }

  @override
  Future<void> ensureSeeded() async => store.seedSystemCategories();
}
