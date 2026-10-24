/// A bill reminder (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'bill_reminder.freezed.dart';
part 'bill_reminder.g.dart';

/// A reminder for a bill, tied to a recurring stream or entered manually ([streamId]
/// null, with its own [name] and [amount]).
@freezed
abstract class BillReminder with _$BillReminder {
  /// A reminder; [reminderOffsetDays] are the days before [dueDate] to remind.
  const factory BillReminder({
    required String id,
    String? streamId,
    String? name,
    Money? amount,
    required LocalDate dueDate,
    required List<int> reminderOffsetDays,
  }) = _BillReminder;

  /// Reads the snake_case JSON form.
  factory BillReminder.fromJson(Map<String, dynamic> json) =>
      _$BillReminderFromJson(json);
}
