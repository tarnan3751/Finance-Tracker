/// The user's Plaid Items as the server last listed them (`docs/reference/data.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, loaded
/// with the demo seed's Items); all pass `test/contract/item_repository_contract.dart`.
/// Items are server-authoritative: only the Plaid pull and the Link flow write them, and
/// nothing here is recorded in the change log.
library;

import 'dart:typed_data';

import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:shared_models/shared_models.dart';

/// Plaid's error code for an Item whose login must be repaired.
const String itemLoginRequiredCode = 'ITEM_LOGIN_REQUIRED';

/// An Item with its institution, as the server sends it.
typedef ServerItem = ({Item item, Institution institution});

/// Reads and writes the stored Items. Every stream starts with the current value and
/// emits again only when that value changes.
abstract interface class ItemRepository {
  /// Every stored Item, by institution name (ASCII letters ignoring case), then id.
  Stream<List<LinkedBank>> watchAll();

  /// Item [id], or null when there is none.
  Stream<LinkedBank?> watchById(String id);

  /// Replaces the stored Items with [items], the server's whole list, stamping each
  /// [pulledAt]: a listed Item is inserted or updated with every field the server gave
  /// (its logo bytes kept while its logo URL is unchanged), and a stored Item the list
  /// does not hold is removed (its accounts leave the server's account list, which the
  /// account repository's `applyPlaid` applies). Returns the Items as now stored, in
  /// [items]' order, logo bytes included.
  Future<List<LinkedBank>> applyPlaid(
    List<ServerItem> items, {
    required DateTime pulledAt,
  });

  /// Inserts or updates the one Item [item] as [applyPlaid] does, leaving the others:
  /// the answer to an exchange, before the next pull.
  Future<void> applyPlaidItem(ServerItem item, {required DateTime pulledAt});

  /// Stores [bytes], the logo fetched from [logoUrl], on Item [id], unless the Item is
  /// gone or its logo URL has changed since (a pull wrote another one meanwhile).
  Future<void> saveLogo(String id, Uri logoUrl, Uint8List bytes);

  /// Marks Item [id] as needing its login repaired (`loginRequired`, Plaid's
  /// `ITEM_LOGIN_REQUIRED`), as the server answered; the next pull confirms it. Does
  /// nothing when there is no such Item.
  Future<void> markLoginRequired(String id);
}
