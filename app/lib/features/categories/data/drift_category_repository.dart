/// The [CategoryRepository] of the dev and prod flavors, over the `categories` table
/// (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Categories in [AppDatabase]. Audit fields are stamped from the clock.
final class DriftCategoryRepository implements CategoryRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftCategoryRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  $CategoriesTable get _categories => _database.categories;

  @override
  Stream<List<Category>> watchAll() =>
      (_database.select(_categories)
            ..where((c) => c.deletedAt.isNull())
            ..orderBy([
              (c) => OrderingTerm.asc(c.name.collate(Collate.noCase)),
              (c) => OrderingTerm.asc(c.id),
            ]))
          .watch()
          .map((rows) => rows.map(categoryFromRow).toList())
          .distinct(sameList);

  @override
  Stream<Category?> watchById(String id) =>
      (_database.select(_categories)
            ..where((c) => c.id.equals(id) & c.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row == null ? null : categoryFromRow(row))
          .distinct();

  @override
  Future<void> upsert(Category category) => _database.transaction(() async {
    final CategoryRow? existing = await (_database.select(
      _categories,
    )..where((c) => c.id.equals(category.id))).getSingleOrNull();
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('category', category.id);
    }
    checkCategoryEdit(
      existing == null ? null : categoryFromRow(existing),
      category,
    );
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_categories)
        .insertOnConflictUpdate(
          categoryCompanion(
            category,
            createdAt: existing?.createdAt ?? now,
            now: now,
          ),
        );
  });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final CategoryRow? row = await (_database.select(
      _categories,
    )..where((c) => c.id.equals(id) & c.deletedAt.isNull())).getSingleOrNull();
    if (row == null) return;
    if (row.isSystem) throw CategoryNotDeletableException(id);
    final DateTime now = _clock.nowUtc();
    await (_database.update(_categories)..where(
          (c) =>
              (c.id.equals(id) | c.parentId.equals(id)) & c.deletedAt.isNull(),
        ))
        .write(
          CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
  });

  @override
  Future<void> ensureSeeded() async {
    final DateTime now = _clock.nowUtc();
    await _database.batch(
      (batch) => batch.insertAll(_categories, [
        for (final Category c in systemCategories)
          categoryCompanion(c, createdAt: now, now: now),
      ], mode: InsertMode.insertOrIgnore),
    );
  }
}

/// The row of [c], stamped [createdAt] and [now]; `deleted_at` is written only when given.
CategoriesCompanion categoryCompanion(
  Category c, {
  required DateTime createdAt,
  required DateTime now,
  Value<DateTime?> deletedAt = const Value.absent(),
}) => CategoriesCompanion(
  id: Value(c.id),
  name: Value(c.name),
  parentId: Value(c.parentId),
  isSystem: Value(c.isSystem),
  icon: Value(c.icon),
  color: Value(c.color),
  plaidCategory: Value(c.plaidCategory),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: deletedAt,
);

/// The [Category] a row holds.
Category categoryFromRow(CategoryRow row) => Category(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  isSystem: row.isSystem,
  icon: row.icon,
  color: row.color,
  plaidCategory: row.plaidCategory,
);
