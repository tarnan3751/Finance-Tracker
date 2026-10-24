/// JSON for audit instants: `created_at`, `updated_at`, `deleted_at`, sync times
/// (`PLAN.md` §6.8: UTC instants with milliseconds).
library;

import 'package:json_annotation/json_annotation.dart';

/// Writes a UTC `DateTime` as ISO 8601 with millisecond precision and a trailing `Z`
/// (`2026-10-24T15:04:05.123Z`), and reads any ISO 8601 date-time that names its offset,
/// converting it to UTC.
///
/// Both directions are strict on purpose. Audit instants are UTC with millisecond
/// precision by contract, so writing a non-UTC `DateTime`, one with a nonzero microsecond
/// part, or one outside the years 1 to 9999 is an [ArgumentError]: converting or rounding
/// here would hide the bug, and a value that changed on the way out would not equal itself
/// after a round trip. Build audit values with the app's clock (millisecond precision) or
/// `DateTime.now().toUtc().truncatedToMilliseconds()`. Reading a string without `Z` or an
/// offset is a [FormatException], because `DateTime.parse` would take it as device-local
/// time, and so is one whose UTC year is outside 1 to 9999, which could not be written
/// back; sub-millisecond digits in external input are dropped.
final class UtcInstantConverter implements JsonConverter<DateTime, String> {
  /// The converter.
  const UtcInstantConverter();

  static final RegExp _hasOffset = RegExp(
    r'[T ]\d{2}.*([Zz]|[+-]\d{2}(:?\d{2})?)$',
  );

  @override
  DateTime fromJson(String json) {
    if (!_hasOffset.hasMatch(json)) {
      throw FormatException('Instant has no UTC offset', json);
    }
    final parsed = DateTime.fromMillisecondsSinceEpoch(
      DateTime.parse(json).millisecondsSinceEpoch,
      isUtc: true,
    );
    if (parsed.year < 1 || parsed.year > 9999) {
      throw FormatException('Instant is outside the years 1 to 9999 UTC', json);
    }
    return parsed;
  }

  @override
  String toJson(DateTime object) {
    if (!object.isUtc) {
      throw ArgumentError.value(object, 'object', 'audit instants must be UTC');
    }
    if (object.microsecond != 0) {
      throw ArgumentError.value(
        object,
        'object',
        'audit instants have millisecond precision; use truncatedToMilliseconds()',
      );
    }
    if (object.year < 1 || object.year > 9999) {
      throw ArgumentError.value(object, 'object', 'year must be 1 to 9999');
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${object.year.toString().padLeft(4, '0')}-${two(object.month)}-'
        '${two(object.day)}T${two(object.hour)}:${two(object.minute)}:'
        '${two(object.second)}.${object.millisecond.toString().padLeft(3, '0')}Z';
  }
}

/// Millisecond truncation for building audit instants.
extension DateTimeInstant on DateTime {
  /// This instant with the microseconds dropped, in the same zone.
  DateTime truncatedToMilliseconds() => microsecond == 0
      ? this
      : DateTime.fromMillisecondsSinceEpoch(
          millisecondsSinceEpoch,
          isUtc: isUtc,
        );
}
