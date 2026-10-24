/// A [CategoryRepository] over an [InMemoryStore]: what tests use.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Categories held in [store].
base class InMemoryCategoryRepository implements CategoryRepository {
  /// The repository over [store].
  InMemoryCategoryRepository(this.store);

  /// The state shared with the account and transaction repositories.
  final InMemoryStore store;

  @override
  Stream<List<Category>> watchAll() =>
      store.watch(store.categories, same: sameList);

  @override
  Stream<Category?> watchById(String id) =>
      store.watch(() => store.category(id));

  @override
  Future<void> upsert(Category category) async =>
      store.upsertCategory(category);

  @override
  Future<void> delete(String id) async => store.deleteCategory(id);

  @override
  Future<void> ensureSeeded() async => store.seedSystemCategories();
}
