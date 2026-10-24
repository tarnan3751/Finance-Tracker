/// A recurring stream of transactions (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'recurring_stream.freezed.dart';
part 'recurring_stream.g.dart';

/// A stream of transactions that recur at a cadence: a subscription, a bill, a salary.
@freezed
abstract class RecurringStream with _$RecurringStream {
  /// A stream; [lastExpected] and [nextExpected] are null when unknown.
  const factory RecurringStream({
    required String id,
    required String accountId,
    required String merchantName,
    @JsonKey(unknownEnumValue: RecurringCadence.unknown)
    required RecurringCadence cadence,
    required Money averageAmount,
    LocalDate? lastExpected,
    LocalDate? nextExpected,
    required RecurringStatus status,
    required bool isSubscription,
    required RecurringSource source,
  }) = _RecurringStream;

  /// Reads the snake_case JSON form.
  factory RecurringStream.fromJson(Map<String, dynamic> json) =>
      _$RecurringStreamFromJson(json);
}
