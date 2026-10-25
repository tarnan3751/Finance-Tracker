/// The [SavedFilterRepository] of the dev and prod flavors, over the `saved_filters`
/// table (`docs/reference/data.md`). Nothing is recorded: saved filters stay on the
/// device.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter_repository.dart';
import 'package:uuid/uuid.dart';

/// Saved filters in [AppDatabase], audit instants stamped from the clock.
final class DriftSavedFilterRepository implements SavedFilterRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftSavedFilterRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  $SavedFiltersTable get _table => _database.savedFilters;

  @override
  Stream<List<SavedFilter>> watchAll() =>
      (_database.select(_table)..orderBy([
            (f) => OrderingTerm.asc(f.position),
            (f) => OrderingTerm.asc(f.id),
          ]))
          .watch()
          .map((rows) => rows.map(_fromRow).toList())
          .distinct(sameList);

  @override
  Future<SavedFilter> save(String name, Map<String, Object?> filters) async {
    checkSavedFilterName(name);
    return _database.transaction(() async {
      final Expression<int> highest = _table.position.max();
      final int? last = (await (_database.selectOnly(
        _table,
      )..addColumns([highest])).getSingle()).read(highest);
      final DateTime now = _clock.nowUtc();
      final SavedFilter saved = SavedFilter(
        id: const Uuid().v4(),
        name: name,
        position: last == null ? 0 : last + 1,
        filters: filters,
      );
      await _database
          .into(_table)
          .insert(
            SavedFiltersCompanion.insert(
              id: saved.id,
              name: name,
              queryJson: jsonEncode(filters),
              position: saved.position,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return saved;
    });
  }

  @override
  Future<void> rename(String id, String name) async {
    checkSavedFilterName(name);
    await (_database.update(_table)..where((f) => f.id.equals(id))).write(
      SavedFiltersCompanion(
        name: Value(name),
        updatedAt: Value(_clock.nowUtc()),
      ),
    );
  }

  @override
  Future<void> delete(String id) =>
      (_database.delete(_table)..where((f) => f.id.equals(id))).go();
}

SavedFilter _fromRow(SavedFilterRow row) => SavedFilter(
  id: row.id,
  name: row.name,
  position: row.position,
  filters: jsonDecode(row.queryJson) as Map<String, Object?>,
);
