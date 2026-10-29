/// A position in one security of an investment account, as Plaid's Investments product
/// reports it (`PLAN.md` §12, "Investments in the app").
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/decimal.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'holding.freezed.dart';

/// Account [accountId]'s position in security [securityId]: [quantity] shares at the
/// institution's [institutionPrice] per share (in [institutionValue]'s currency) on
/// [institutionPriceAsOf], worth [institutionValue], bought for [costBasis] when the
/// institution reports it. The value and the cost basis are the institution's totals, never
/// computed from the price. Server-authoritative, replaced on every pull and never synced,
/// so the entity has no JSON form of its own.
@freezed
abstract class Holding with _$Holding {
  /// A holding.
  const factory Holding({
    required String accountId,
    required String securityId,
    required Decimal quantity,
    required Decimal institutionPrice,
    LocalDate? institutionPriceAsOf,
    required Money institutionValue,
    Money? costBasis,
    required DataSource source,
  }) = _Holding;
}
