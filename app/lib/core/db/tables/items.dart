/// The `items` table: the user's Plaid Items as the server last listed them
/// (`docs/reference/data.md`, schema 3).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// One Plaid Item with its institution. Server-authoritative: written only by the Plaid
/// pull (`core/plaid/plaid_pull.dart`), never recorded in the change log. `status` is the
/// `ItemStatus` JSON name, `removed` for an Item unlinked with its history kept;
/// `institution_logo` holds the logo's bytes, fetched once per `institution_logo_url`
/// (the server's logo route is bearer-secured). `pulled_at` is when the pull last wrote
/// the row. Accounts name their Item by `item_id` with no foreign key.
@DataClassName('ItemRow')
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get institutionId => text()();
  TextColumn get institutionName => text()();
  TextColumn get institutionLogoUrl =>
      text().map(const UriColumnConverter()).nullable()();
  BlobColumn get institutionLogo => blob().nullable()();
  IntColumn get institutionColor => integer().nullable()();
  TextColumn get status => text().map(const ItemStatusColumnConverter())();
  TextColumn get errorCode => text().nullable()();
  IntColumn get lastSuccessfulSyncAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();
  IntColumn get pulledAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (status IN ('healthy', 'login_required', 'error', "
        "'pending_expiration', 'unknown', 'removed'))",
  ];
}
