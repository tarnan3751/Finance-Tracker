/// The [ItemRepository] of the dev and prod flavors, over the `items` table
/// (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:shared_models/shared_models.dart';

/// Items in [AppDatabase]. Nothing is recorded: Items are the server's.
final class DriftItemRepository implements ItemRepository {
  /// The repository over [_database].
  DriftItemRepository(this._database);

  final AppDatabase _database;

  $ItemsTable get _items => _database.items;

  @override
  Stream<List<LinkedBank>> watchAll() =>
      (_database.select(_items)..orderBy([
            (i) => OrderingTerm.asc(i.institutionName.collate(Collate.noCase)),
            (i) => OrderingTerm.asc(i.id),
          ]))
          .watch()
          .map((rows) => rows.map(linkedBankFromRow).toList())
          .distinct(sameList);

  @override
  Stream<LinkedBank?> watchById(String id) =>
      (_database.select(_items)..where((i) => i.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : linkedBankFromRow(row))
          .distinct();

  @override
  Future<void> applyPlaid(
    List<ServerItem> items, {
    required DateTime pulledAt,
  }) => _database.transaction(() async {
    for (final ServerItem item in items) {
      await applyPlaidItem(item, pulledAt: pulledAt);
    }
    await (_database.delete(
      _items,
    )..where((i) => i.id.isNotIn([for (final i in items) i.item.id]))).go();
  });

  @override
  Future<void> applyPlaidItem(ServerItem item, {required DateTime pulledAt}) =>
      _database.transaction(() async {
        final ItemRow? existing = await (_database.select(
          _items,
        )..where((i) => i.id.equals(item.item.id))).getSingleOrNull();
        final Uri? logoUrl = item.institution.logoUrl;
        // The logo's bytes stay while its URL does; a new URL is fetched again.
        final Uint8List? logo =
            existing != null && existing.institutionLogoUrl == logoUrl
            ? existing.institutionLogo
            : null;
        await _database
            .into(_items)
            .insertOnConflictUpdate(
              ItemsCompanion.insert(
                id: item.item.id,
                institutionId: item.institution.id,
                institutionName: item.institution.name,
                institutionLogoUrl: Value(logoUrl),
                institutionLogo: Value(logo),
                institutionColor: Value(item.institution.primaryColor),
                status: item.item.status,
                errorCode: Value(item.item.errorCode),
                lastSuccessfulSyncAt: Value(item.item.lastSuccessfulSyncAt),
                pulledAt: pulledAt,
              ),
            );
      });

  @override
  Future<void> markLoginRequired(String id) =>
      (_database.update(_items)..where((i) => i.id.equals(id))).write(
        const ItemsCompanion(
          status: Value(ItemStatus.loginRequired),
          errorCode: Value(itemLoginRequiredCode),
        ),
      );
}

/// The [LinkedBank] a row holds.
LinkedBank linkedBankFromRow(ItemRow row) => LinkedBank(
  item: Item(
    id: row.id,
    institutionId: row.institutionId,
    status: row.status,
    errorCode: row.errorCode,
    lastSuccessfulSyncAt: row.lastSuccessfulSyncAt,
  ),
  institution: Institution(
    id: row.institutionId,
    name: row.institutionName,
    logoUrl: row.institutionLogoUrl,
    primaryColor: row.institutionColor,
  ),
  logo: row.institutionLogo,
  pulledAt: row.pulledAt,
);
