/// A buy, sell, contribution, dividend, fee or transfer in an investment account, as
/// Plaid's Investments product reports it (`PLAN.md` §12, "Investments in the app").
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/decimal.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'investment_transaction.freezed.dart';

/// One investment transaction of account [accountId] on [date]: Plaid's [type] and
/// [subtype] kept open (`buy`, `sell`, `cash`, `fee`, ...), [quantity] units of
/// [securityId] (none for cash) at [price] per unit, the cash [amount] in the app's sign
/// (negative is money out of the account's cash, as a buy is) and the [fees]. [deletedAt]
/// is the server's tombstone (UTC) and [syncVersion] the server's version of the row.
/// Server-authoritative and never synced, so the entity has no JSON form of its own.
@freezed
abstract class InvestmentTransaction with _$InvestmentTransaction {
  /// An investment transaction.
  const factory InvestmentTransaction({
    required String id,
    required String accountId,
    String? securityId,
    required LocalDate date,
    required String name,
    required String type,
    String? subtype,
    required Decimal quantity,
    required Decimal price,
    required Money amount,
    Money? fees,
    DateTime? deletedAt,
    required int syncVersion,
    required DataSource source,
  }) = _InvestmentTransaction;
}
