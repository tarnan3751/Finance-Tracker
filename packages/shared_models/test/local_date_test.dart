// Tests for LocalDate and LocalDateRange: validation, leap years, month arithmetic with
// clamping, half-open ranges, the ISO form and ordering.
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

void main() {
  group('validation', () {
    test('accepts real dates', () {
      expect(LocalDate(2026, 10, 24).toIso(), '2026-10-24');
      expect(LocalDate(1, 1, 1).toIso(), '0001-01-01');
      expect(LocalDate(9999, 12, 31).toIso(), '9999-12-31');
    });

    test('rejects impossible dates', () {
      for (final (y, m, day) in [
        (2026, 2, 29),
        (1900, 2, 29),
        (2026, 4, 31),
        (2026, 13, 1),
        (2026, 0, 1),
        (2026, 1, 0),
        (2026, 1, 32),
        (0, 1, 1),
        (10000, 1, 1),
      ]) {
        expect(
          () => LocalDate(y, m, day),
          throwsArgumentError,
          reason: '$y-$m-$day',
        );
      }
    });

    test('leap years', () {
      expect(LocalDate.isLeap(2024), isTrue);
      expect(LocalDate.isLeap(2000), isTrue);
      expect(LocalDate.isLeap(1900), isFalse);
      expect(LocalDate.isLeap(2026), isFalse);
      expect(LocalDate(2024, 2, 29).isLeapYear, isTrue);
      expect(LocalDate.daysInMonth(2024, 2), 29);
      expect(LocalDate.daysInMonth(2026, 2), 28);
      expect(LocalDate.daysInMonth(2026, 9), 30);
    });
  });

  group('ISO form', () {
    test('round trip', () {
      for (final iso in [
        '2026-10-24',
        '2024-02-29',
        '0001-01-01',
        '9999-12-31',
      ]) {
        expect(d(iso).toIso(), iso);
        expect(d(iso).toString(), iso);
        expect(LocalDate.fromJson(d(iso).toJson()), d(iso));
        const converter = LocalDateConverter();
        expect(converter.fromJson(converter.toJson(d(iso))), d(iso));
      }
    });

    test('parse is strict', () {
      for (final text in [
        '2026-1-24',
        '2026-10-24T00:00:00',
        ' 2026-10-24',
        '26-10-24',
        '2026/10/24',
        '2026-02-30',
        '',
      ]) {
        expect(
          () => LocalDate.parse(text),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('arithmetic', () {
    test('addDays across months, years and leap days', () {
      expect(d('2026-10-24').addDays(8), d('2026-11-01'));
      expect(d('2026-12-31').addDays(1), d('2027-01-01'));
      expect(d('2024-02-28').addDays(1), d('2024-02-29'));
      expect(d('2024-03-01').addDays(-1), d('2024-02-29'));
      expect(d('2026-03-01').addDays(-1), d('2026-02-28'));
      expect(d('2026-01-01').addDays(365), d('2027-01-01'));
      expect(d('2024-01-01').addDays(366), d('2025-01-01'));
    });

    test('addMonths clamps to the end of the target month', () {
      expect(d('2026-01-31').addMonths(1), d('2026-02-28'));
      expect(d('2024-01-31').addMonths(1), d('2024-02-29'));
      expect(d('2026-03-31').addMonths(-1), d('2026-02-28'));
      expect(d('2026-05-31').addMonths(1), d('2026-06-30'));
      expect(d('2026-10-24').addMonths(3), d('2027-01-24'));
      expect(d('2026-10-24').addMonths(-10), d('2025-12-24'));
      expect(d('2024-02-29').addMonths(12), d('2025-02-28'));
      expect(() => d('0001-01-01').addMonths(-1), throwsArgumentError);
    });

    test('daysUntil', () {
      expect(d('2026-10-24').daysUntil(d('2026-11-24')), 31);
      expect(d('2026-11-24').daysUntil(d('2026-10-24')), -31);
      expect(d('2000-01-01').daysUntil(d('2100-01-01')), 36525);
    });

    test('weekday matches DateTime over a span of years', () {
      var date = d('1999-12-25');
      for (var i = 0; i < 3000; i++) {
        final utc = DateTime.utc(date.year, date.month, date.day);
        expect(date.weekday, utc.weekday, reason: '$date');
        date = date.addDays(1);
      }
      expect(d('2026-10-24').weekday, DateTime.saturday);
    });

    test('epoch-day arithmetic matches DateTime.utc day counts', () {
      final base = DateTime.utc(1970);
      for (final iso in [
        '0001-01-01',
        '1600-02-29',
        '1969-12-31',
        '9999-12-31',
      ]) {
        final date = d(iso);
        final days = DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).difference(base).inDays;
        expect(d('1970-01-01').daysUntil(date), days, reason: iso);
        expect(d('1970-01-01').addDays(days), date, reason: iso);
      }
    });

    test('month boundaries', () {
      expect(d('2026-02-14').firstOfMonth, d('2026-02-01'));
      expect(d('2026-02-14').lastOfMonth, d('2026-02-28'));
      expect(d('2024-02-14').lastOfMonth, d('2024-02-29'));
    });

    test('DateTime conversions keep the fields', () {
      expect(
        LocalDate.fromDateTime(DateTime(2026, 10, 24, 23, 59)),
        d('2026-10-24'),
      );
      expect(
        LocalDate.fromDateTime(DateTime.utc(2026, 10, 24, 0, 1)),
        d('2026-10-24'),
      );
      expect(d('2026-10-24').toDateTime(), DateTime(2026, 10, 24));
    });
  });

  group('ordering and equality', () {
    test('compares by date', () {
      expect(d('2026-10-24').isBefore(d('2026-10-25')), isTrue);
      expect(d('2026-10-24').isAfter(d('2025-12-31')), isTrue);
      expect(d('2026-10-24').compareTo(d('2026-10-24')), 0);
      expect([d('2026-10-24'), d('2025-01-01'), d('2026-01-31')]..sort(), [
        d('2025-01-01'),
        d('2026-01-31'),
        d('2026-10-24'),
      ]);
      expect(d('2026-10-24'), LocalDate(2026, 10, 24));
      expect(d('2026-10-24').hashCode, LocalDate(2026, 10, 24).hashCode);
    });
  });

  group('LocalDateRange', () {
    final october = LocalDateRange(d('2026-10-01'), d('2026-11-01'));

    test('is half-open', () {
      expect(october.contains(d('2026-10-01')), isTrue);
      expect(october.contains(d('2026-10-31')), isTrue);
      expect(october.contains(d('2026-11-01')), isFalse);
      expect(october.contains(d('2026-09-30')), isFalse);
      expect(october.length, 31);
      expect(october.days.first, d('2026-10-01'));
      expect(october.days.last, d('2026-10-31'));
      expect(october.days.length, 31);
    });

    test('empty and invalid ranges', () {
      final empty = LocalDateRange(d('2026-10-01'), d('2026-10-01'));
      expect(empty.isEmpty, isTrue);
      expect(empty.contains(d('2026-10-01')), isFalse);
      expect(
        () => LocalDateRange(d('2026-10-02'), d('2026-10-01')),
        throwsArgumentError,
      );
    });

    test('overlaps only when a date is shared', () {
      final november = LocalDateRange(d('2026-11-01'), d('2026-12-01'));
      final midMonth = LocalDateRange(d('2026-10-15'), d('2026-11-15'));
      expect(october.overlaps(november), isFalse);
      expect(november.overlaps(october), isFalse);
      expect(october.overlaps(midMonth), isTrue);
      expect(midMonth.overlaps(november), isTrue);
      expect(october.overlaps(october), isTrue);
    });
  });
}
