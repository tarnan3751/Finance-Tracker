// Tests for UtcInstantConverter: millisecond precision, the Z suffix, offsets converted on
// read, zone-less input rejected, non-UTC or sub-millisecond output rejected.
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  const converter = UtcInstantConverter();

  test('writes milliseconds and Z', () {
    expect(
      converter.toJson(DateTime.utc(2026, 10, 24, 15, 4, 5, 123)),
      '2026-10-24T15:04:05.123Z',
    );
    expect(converter.toJson(DateTime.utc(2026)), '2026-01-01T00:00:00.000Z');
  });

  test('refuses sub-millisecond precision on write and drops it on read', () {
    expect(
      () => converter.toJson(DateTime.utc(2026, 10, 24, 15, 4, 5, 123, 999)),
      throwsArgumentError,
    );
    expect(
      converter.toJson(
        DateTime.utc(
          2026,
          10,
          24,
          15,
          4,
          5,
          123,
          999,
        ).truncatedToMilliseconds(),
      ),
      '2026-10-24T15:04:05.123Z',
    );
    expect(
      converter.fromJson('2026-10-24T15:04:05.123999Z'),
      DateTime.utc(2026, 10, 24, 15, 4, 5, 123),
    );
  });

  test('round trips', () {
    final instant = DateTime.utc(2024, 2, 29, 23, 59, 59, 999);
    final back = converter.fromJson(converter.toJson(instant));
    expect(back, instant);
    expect(back.isUtc, isTrue);
  });

  test('converts an offset to UTC', () {
    final parsed = converter.fromJson('2026-10-24T10:00:00.000-05:00');
    expect(parsed, DateTime.utc(2026, 10, 24, 15));
    expect(parsed.isUtc, isTrue);
    expect(
      converter.fromJson('2026-10-25T01:30:00+0230'),
      DateTime.utc(2026, 10, 24, 23),
    );
    expect(
      converter.fromJson('2026-10-24T15:00:00z'),
      DateTime.utc(2026, 10, 24, 15),
    );
  });

  test('rejects a string without an offset', () {
    for (final text in [
      '2026-10-24T15:04:05.123',
      '2026-10-24T15:04:05',
      '2026-10-24',
      '2026-10-24T15',
      'yesterday',
    ]) {
      expect(
        () => converter.fromJson(text),
        throwsFormatException,
        reason: text,
      );
    }
  });

  test('truncatedToMilliseconds keeps the zone and makes now round-trip', () {
    final now = DateTime.now().toUtc().truncatedToMilliseconds();
    expect(now.microsecond, 0);
    expect(now.isUtc, isTrue);
    expect(converter.fromJson(converter.toJson(now)), now);
    final local = DateTime(
      2026,
      10,
      24,
      1,
      2,
      3,
      4,
      5,
    ).truncatedToMilliseconds();
    expect(local.isUtc, isFalse);
    expect(local, DateTime(2026, 10, 24, 1, 2, 3, 4));
    final exact = DateTime.utc(2026);
    expect(identical(exact.truncatedToMilliseconds(), exact), isTrue);
  });

  test('refuses to read an instant it could not write back', () {
    for (final text in [
      '9999-12-31T23:59:59.999-01:00',
      '+010000-01-01T00:00:00Z',
      '-000001-01-01T00:00:00Z',
    ]) {
      expect(
        () => converter.fromJson(text),
        throwsFormatException,
        reason: text,
      );
    }
    expect(
      converter.fromJson('9999-12-31T23:59:59.999Z'),
      DateTime.utc(9999, 12, 31, 23, 59, 59, 999),
    );
    expect(
      converter.fromJson('0001-01-01T00:59:00+00:30'),
      DateTime.utc(1, 1, 1, 0, 29),
    );
  });

  test('refuses years outside 1 to 9999', () {
    expect(() => converter.toJson(DateTime.utc(10000)), throwsArgumentError);
    expect(() => converter.toJson(DateTime.utc(0)), throwsArgumentError);
    expect(converter.toJson(DateTime.utc(1)), '0001-01-01T00:00:00.000Z');
  });

  test('refuses to write a local DateTime', () {
    expect(
      () => converter.toJson(DateTime(2026, 10, 24, 15)),
      throwsArgumentError,
    );
  });
}
