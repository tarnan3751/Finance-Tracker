/// An [ItemRepository] over an [InMemoryStore]: what tests use.
library;

import 'dart:typed_data';

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';

/// Items held in [store], beside the accounts they own. Nothing is recorded: Items are
/// the server's.
base class InMemoryItemRepository implements ItemRepository {
  /// The repository over [store].
  InMemoryItemRepository(this.store);

  /// The state shared with the other repositories.
  final InMemoryStore store;

  @override
  Stream<List<LinkedBank>> watchAll() =>
      store.watch(store.items, same: sameList);

  @override
  Stream<LinkedBank?> watchById(String id) => store.watch(() => store.item(id));

  @override
  Future<List<LinkedBank>> applyPlaid(
    List<ServerItem> items, {
    required DateTime pulledAt,
  }) async {
    store.applyPlaidItems(items, pulledAt);
    return [for (final ServerItem i in items) store.item(i.item.id)!];
  }

  @override
  Future<void> applyPlaidItem(
    ServerItem item, {
    required DateTime pulledAt,
  }) async => store.applyPlaidItem(item, pulledAt);

  @override
  Future<void> saveLogo(String id, Uri logoUrl, Uint8List bytes) async =>
      store.saveItemLogo(id, logoUrl, bytes);

  @override
  Future<void> markLoginRequired(String id) async =>
      store.markItemLoginRequired(id);
}
