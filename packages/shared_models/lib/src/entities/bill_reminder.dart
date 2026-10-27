/// A bill and its reminders (`PLAN.md` §6.2, §12 "Bills"; `docs/reference/bills.md`).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'bill_reminder.freezed.dart';
part 'bill_reminder.g.dart';

/// How many paid occurrences a bill keeps: the latest ones.
const int paidOccurrenceLimit = 24;

/// The default reminder time, 09:00, in minutes after local midnight.
const int defaultReminderMinutes = 540;

/// A bill the user pays: entered by hand, or accepted from a suggestion, when it keeps the
/// recurring stream ([streamId]) or the liability ([liabilityAccountId]) it came from.
/// Every field after [dueDate] has a default, so a record written before they existed
/// still decodes.
@freezed
abstract class BillReminder with _$BillReminder {
  /// A bill. [dueDate] is its first due date, from which [cadence] repeats it (null: once);
  /// a monthly or annual bill keeps [dueDate]'s day of the month, clamped to short months,
  /// a semimonthly one that day and the day 15 days away in the same month. [name] is
  /// null only on records older than the field (shown by the stream's merchant then).
  /// [reminderOffsetDays] are the days before each due date to remind, 0 to 30, distinct;
  /// [reminderMinutes] the local wall-clock time of the reminders, minutes after
  /// midnight. An [autopay] bill is never missed. [paidOccurrences] are the due dates the
  /// user marked paid, ascending, at most [paidOccurrenceLimit].
  const factory BillReminder({
    required String id,
    String? streamId,
    String? name,
    Money? amount,
    required LocalDate dueDate,
    @_OffsetsConverter() @Default([2]) List<int> reminderOffsetDays,
    RecurringCadence? cadence,
    String? accountId,
    String? liabilityAccountId,
    @_MinutesConverter() @Default(defaultReminderMinutes) int reminderMinutes,
    @Default(true) bool active,
    @Default(false) bool autopay,
    @_PaidConverter() @Default(<LocalDate>[]) List<LocalDate> paidOccurrences,
  }) = _BillReminder;

  const BillReminder._();

  /// Reads the snake_case JSON form.
  factory BillReminder.fromJson(Map<String, dynamic> json) =>
      _$BillReminderFromJson(json);

  /// This bill with the occurrence due [due] marked paid (the oldest marks dropping past
  /// [paidOccurrenceLimit]).
  BillReminder markPaid(LocalDate due) =>
      copyWith(paidOccurrences: normalizePaid([...paidOccurrences, due]));

  /// This bill with the mark on the occurrence due [due] removed.
  BillReminder unmarkPaid(LocalDate due) => copyWith(
    paidOccurrences: normalizePaid(paidOccurrences.where((d) => d != due)),
  );
}

/// [dates] as a bill keeps its paid occurrences: ascending, distinct, the newest
/// [paidOccurrenceLimit].
List<LocalDate> normalizePaid(Iterable<LocalDate> dates) {
  final List<LocalDate> sorted = dates.toSet().toList()..sort();
  return List.unmodifiable(
    sorted.length > paidOccurrenceLimit
        ? sorted.sublist(sorted.length - paidOccurrenceLimit)
        : sorted,
  );
}

/// Reads the paid occurrences as [normalizePaid] keeps them, whatever order, repeats or
/// length the JSON has.
final class _PaidConverter
    implements JsonConverter<List<LocalDate>, List<dynamic>> {
  const _PaidConverter();

  @override
  List<LocalDate> fromJson(List<dynamic> json) => normalizePaid([
    for (final Object? d in json) LocalDate.parse(d! as String),
  ]);

  @override
  List<dynamic> toJson(List<LocalDate> object) => [
    for (final LocalDate d in object) d.toIso(),
  ];
}

/// Rejects reminder offsets outside 0 to 30 days, or repeated, at the JSON boundary.
final class _OffsetsConverter
    implements JsonConverter<List<int>, List<dynamic>> {
  const _OffsetsConverter();

  @override
  List<int> fromJson(List<dynamic> json) {
    final List<int> offsets = [
      for (final Object? v in json) (v! as num).toInt(),
    ];
    if (offsets.any((d) => d < 0 || d > 30) ||
        offsets.toSet().length != offsets.length) {
      throw FormatException(
        'reminder_offset_days must be distinct, 0 to 30',
        json,
      );
    }
    return offsets;
  }

  @override
  List<dynamic> toJson(List<int> object) => object;
}

/// Rejects a reminder time outside the day at the JSON boundary.
final class _MinutesConverter implements JsonConverter<int, int> {
  const _MinutesConverter();

  @override
  int fromJson(int json) {
    if (json < 0 || json >= 24 * 60) {
      throw FormatException('reminder_minutes must be 0 to 1439', json);
    }
    return json;
  }

  @override
  int toJson(int object) => object;
}
