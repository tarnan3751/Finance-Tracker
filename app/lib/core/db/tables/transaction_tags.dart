/// The `transaction_tags` table: a transaction's tags, in order.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/tables/transactions.dart';

/// One tag of one transaction at [position] in its list.
@DataClassName('TransactionTagRow')
@TableIndex(name: 'transaction_tags_tag', columns: {#tag})
class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get tag => text()();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, position};
}
