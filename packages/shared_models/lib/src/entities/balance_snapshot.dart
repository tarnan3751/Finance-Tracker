/// An account's balance on a date (`PLAN.md` §7.1).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'balance_snapshot.freezed.dart';
part 'balance_snapshot.g.dart';

/// An account's balances on a date. [source] says whether the institution reported them
/// (`plaid`) or they were reconstructed from transactions (`derived`, labelled in the UI).
@freezed
abstract class BalanceSnapshot with _$BalanceSnapshot {
  /// A snapshot.
  const factory BalanceSnapshot({
    required String accountId,
    required LocalDate date,
    required Money current,
    Money? available,
    Money? limit,
    required DataSource source,
  }) = _BalanceSnapshot;

  /// Reads the snake_case JSON form.
  factory BalanceSnapshot.fromJson(Map<String, dynamic> json) =>
      _$BalanceSnapshotFromJson(json);
}
