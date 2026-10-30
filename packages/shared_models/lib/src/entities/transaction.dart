/// A transaction and its splits (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';
import 'package:shared_models/src/time/utc_instant_converter.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// One transaction on one account.
///
/// [amount] is negative for an outflow and positive for an inflow. Plaid's sign is the
/// opposite and is flipped at the server boundary.
///
/// [name] is always present: Plaid's raw `name`, or the user's description for a manual
/// entry. [merchantName] is Plaid's cleaned merchant name only, null when Plaid has none.
/// The enrichment fallback is display-side: it reads [name] when [merchantName] is null
/// and never writes [merchantName] or any other Plaid field.
///
/// [hidden] is the user's override: a hidden transaction still counts toward its
/// account's balance (the money moved) and is left out of budgets, reports and the
/// default transaction list. The server never sets it; it travels through the change log.
///
/// [receiptPath] names the receipt photo's file on a device (`receipts/<id>.jpg`, the same
/// on every device) and [receiptSha256] the SHA-256 of its bytes, lower-case hex, by which
/// a device without the file fetches it; both are the user's and travel through the change
/// log. [receiptSha256] is null without a receipt, and for one attached before it existed
/// until its device hashes it.
///
/// [source] is the record's provenance (`PLAN.md` §7.1). [deletedAt] is the tombstone.
@freezed
abstract class Transaction with _$Transaction {
  /// A transaction.
  const factory Transaction({
    required String id,
    required String accountId,
    required Money amount,
    required LocalDate date,
    LocalDate? authorizedDate,
    required bool pending,
    String? pendingTransactionId,
    required String name,
    String? merchantName,
    Uri? merchantLogoUrl,
    String? plaidPrimaryCategory,
    String? plaidDetailedCategory,
    String? userCategoryId,
    String? notes,
    @Default(<String>[]) List<String> tags,
    @Default(<TransactionSplit>[]) List<TransactionSplit> splits,
    String? receiptPath,
    String? receiptSha256,
    @Default(false) bool hidden,
    required DataSource source,
    @UtcInstantConverter() required DateTime createdAt,
    @UtcInstantConverter() required DateTime updatedAt,
    @UtcInstantConverter() DateTime? deletedAt,
    required int syncVersion,
  }) = _Transaction;

  /// Reads the snake_case JSON form.
  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

/// A part of a transaction's amount assigned to a category.
@freezed
abstract class TransactionSplit with _$TransactionSplit {
  /// A split.
  const factory TransactionSplit({
    required String categoryId,
    required Money amount,
    String? note,
  }) = _TransactionSplit;

  /// Reads the snake_case JSON form.
  factory TransactionSplit.fromJson(Map<String, dynamic> json) =>
      _$TransactionSplitFromJson(json);
}
