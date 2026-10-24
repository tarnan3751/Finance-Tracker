/// The categories: the system set seeded from Plaid's taxonomy, and the user's own.
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor); all
/// pass `test/contract/category_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads and writes categories. Every stream starts with the current value and emits again
/// only when that value changes.
///
/// A system category's name, parent and Plaid code never change; only its icon and color
/// do, and it is never deleted. A user category's delete is soft. Transactions keep their
/// `userCategoryId` when its category is deleted; the UI treats it as unset (the
/// transactions' effective category).
abstract interface class CategoryRepository {
  /// The live categories, by name (ignoring case for ASCII letters), then by id.
  Stream<List<Category>> watchAll();

  /// The live category [id], or null when there is none or it is deleted.
  Stream<Category?> watchById(String id);

  /// Inserts or replaces [category].
  ///
  /// Throws [CategoryNotEditableException] when it would create a system category or
  /// change anything but the icon and color of one, or turn a user category into a system
  /// one; `EntityDeletedException` (`core/db/database_exceptions.dart`) when the category
  /// is deleted.
  Future<void> upsert(Category category);

  /// Soft-deletes user category [id] and its live direct children. Throws
  /// [CategoryNotDeletableException] for a system category; does nothing when there is no
  /// such live category.
  Future<void> delete(String id);

  /// Creates the system categories that are missing (`category_defaults.dart`): one per
  /// Plaid primary category (`plaid:<PRIMARY>`) and one per detailed category under it
  /// (`plaid:<DETAILED>`). Leaves existing ones, and their icon and color, as they are.
  Future<void> ensureSeeded();
}

/// A system category cannot be deleted.
final class CategoryNotDeletableException implements Exception {
  /// The exception for [categoryId].
  const CategoryNotDeletableException(this.categoryId);

  /// The system category's id.
  final String categoryId;

  @override
  String toString() =>
      'CategoryNotDeletableException: $categoryId is a system category';
}

/// A system category was written with more than its icon and color changed, or a user
/// category was written as a system one.
final class CategoryNotEditableException implements Exception {
  /// The exception for [categoryId].
  const CategoryNotEditableException(this.categoryId);

  /// The category's id.
  final String categoryId;

  @override
  String toString() =>
      'CategoryNotEditableException: only the icon and color of system category '
      '$categoryId can change';
}
