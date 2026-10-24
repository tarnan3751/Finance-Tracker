/// Net worth on a date (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'net_worth_snapshot.freezed.dart';
part 'net_worth_snapshot.g.dart';

/// Assets and liabilities on [date], with each account's contribution in [byAccount]
/// (account id to balance). Keyed by date. [source] marks reconstructed history as
/// `derived` (`PLAN.md` §7.1).
@freezed
abstract class NetWorthSnapshot with _$NetWorthSnapshot {
  /// A snapshot.
  const factory NetWorthSnapshot({
    required LocalDate date,
    required Money assets,
    required Money liabilities,
    required Map<String, Money> byAccount,
    required DataSource source,
  }) = _NetWorthSnapshot;

  /// Reads the snake_case JSON form.
  factory NetWorthSnapshot.fromJson(Map<String, dynamic> json) =>
      _$NetWorthSnapshotFromJson(json);
}
