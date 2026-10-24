/// An account, linked through Plaid or manual (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/utc_instant_converter.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// A bank, card, loan or investment account.
///
/// Balances are derived, never stored as truth (`PLAN.md` §6): [currentBalance],
/// [availableBalance] and [creditLimit] are the institution's reported figures as of
/// [balancesAsOf], and are null for a manual account, whose balance is always derived from
/// its transactions (an opening balance is itself a `manual` transaction).
@freezed
abstract class Account with _$Account {
  /// An account. [itemId] is null for a manual account; [subtype] is Plaid's subtype
  /// string, kept open because Plaid's list grows.
  const factory Account({
    required String id,
    String? itemId,
    @JsonKey(unknownEnumValue: AccountType.other) required AccountType type,
    String? subtype,
    required String name,
    String? officialName,
    String? mask,
    required String currencyCode,
    Money? currentBalance,
    Money? availableBalance,
    Money? creditLimit,
    @UtcInstantConverter() DateTime? balancesAsOf,
    required bool isHidden,
    required int displayOrder,
  }) = _Account;

  /// Reads the snake_case JSON form.
  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
