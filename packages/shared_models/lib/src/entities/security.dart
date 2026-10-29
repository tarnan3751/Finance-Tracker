/// A security that holdings and investment transactions reference, as Plaid's Investments
/// product reports it (`PLAN.md` §12, "Investments in the app").
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/decimal.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'security.freezed.dart';

/// A security: its name and ticker when known, Plaid's [type] kept open (`equity`, `etf`,
/// `mutual fund`, `cash`, ...), whether it is a cash equivalent, and its [closePrice] per
/// unit on [closePriceAsOf], in [currencyCode]. Server-authoritative and never synced, so
/// the entity has no JSON form of its own.
@freezed
abstract class Security with _$Security {
  /// A security.
  const factory Security({
    required String id,
    String? name,
    String? tickerSymbol,
    String? type,
    bool? isCashEquivalent,
    Decimal? closePrice,
    LocalDate? closePriceAsOf,
    required String currencyCode,
    required DataSource source,
  }) = _Security;
}
