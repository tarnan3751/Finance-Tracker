/// What the category screens show and do: the live categories, by id and as a two-level
/// hierarchy, and the writes the editor makes.
///
/// Deleting a category leaves its transactions' `userCategoryId` alone
/// (`docs/reference/data.md`). A transaction whose category is null, or names a deleted or
/// unknown one, shows the category of its Plaid code, else "Uncategorized"
/// (`features/transactions/domain/effective_category.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

part 'categories_providers.g.dart';

/// The live categories, by name.
@riverpod
Stream<List<Category>> categories(Ref ref) =>
    ref.watch(categoryRepositoryProvider).watchAll();

/// The live categories by id, for screens that name a transaction's category.
@riverpod
Map<String, Category> categoriesById(Ref ref) => {
  for (final Category category
      in ref.watch(categoriesProvider).value ?? const [])
    category.id: category,
};

/// A top-level category and the categories under it, both by name.
typedef CategoryGroup = ({Category primary, List<Category> children});

/// The live categories as their hierarchy: every top-level category with its children.
/// A child whose parent is not live is shown at the top level.
@riverpod
List<CategoryGroup> categoryTree(Ref ref) =>
    buildCategoryTree(ref.watch(categoriesProvider).value ?? const []);

/// [byName] (categories in the repository's order) grouped under their parents.
List<CategoryGroup> buildCategoryTree(List<Category> byName) {
  final Set<String> ids = {for (final Category c in byName) c.id};
  final Map<String, List<Category>> children = {};
  final List<Category> primaries = [];
  for (final Category category in byName) {
    final String? parent = category.parentId;
    if (parent != null && ids.contains(parent)) {
      (children[parent] ??= []).add(category);
    } else {
      primaries.add(category);
    }
  }
  return [
    for (final Category primary in primaries)
      (primary: primary, children: children[primary.id] ?? const []),
  ];
}

/// The writes of the category screens.
@riverpod
CategoryActions categoryActions(Ref ref) => CategoryActions(
  ref.watch(categoryRepositoryProvider),
  ref.watch(transactionRepositoryProvider),
);

/// Creates, edits and deletes categories. The repository's typed exceptions
/// (`CategoryNotEditableException`, `CategoryNotDeletableException`,
/// `EntityDeletedException`) reach the caller, which explains them.
final class CategoryActions {
  CategoryActions(this._categories, this._transactions);

  final CategoryRepository _categories;
  final TransactionRepository _transactions;

  static const Uuid _uuid = Uuid();

  /// Creates a user category and returns its id.
  Future<String> create({
    required String name,
    String? parentId,
    required String icon,
    required int color,
  }) async {
    final String id = _uuid.v4();
    await _categories.upsert(
      Category(
        id: id,
        name: name,
        parentId: parentId,
        isSystem: false,
        icon: icon,
        color: color,
      ),
    );
    return id;
  }

  /// Saves an edited [category]; a system category may change only its icon and color.
  Future<void> update(Category category) => _categories.upsert(category);

  /// How many live transactions are filed under [ids] (directly or through a split): the
  /// ones a delete of those categories leaves uncategorized.
  Future<int> transactionCount(Set<String> ids) =>
      _transactions.count(TransactionQuery(categoryIds: ids));

  /// Deletes user category [id] and its children.
  Future<void> delete(String id) => _categories.delete(id);
}
