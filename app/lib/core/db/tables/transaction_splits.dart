/// The `transaction_splits` table: a transaction's splits, in order.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/tables/transactions.dart';

/// One split of one transaction at [position] in its list. `amount_minor` is in the
/// transaction's currency.
@DataClassName('TransactionSplitRow')
class TransactionSplits extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get categoryId => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {transactionId, position};
}
