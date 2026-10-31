// The import's dates: each format strictly, a trailing time ignored, impossible dates
// refused, and the detection with its ambiguity.
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  test('each format reads its dates', () {
    expect(ImportDateFormat.iso.parse('2026-10-05'), LocalDate(2026, 10, 5));
    expect(ImportDateFormat.us.parse('10/05/2026'), LocalDate(2026, 10, 5));
    expect(ImportDateFormat.us.parse('1/5/2026'), LocalDate(2026, 1, 5));
    expect(ImportDateFormat.day.parse('05/10/2026'), LocalDate(2026, 10, 5));
    expect(ImportDateFormat.dotted.parse('05.10.2026'), LocalDate(2026, 10, 5));
    expect(
      ImportDateFormat.slashedIso.parse('2026/10/05'),
      LocalDate(2026, 10, 5),
    );
    expect(
      ImportDateFormat.iso.parse(' 2026-10-05 10:22:00 '),
      LocalDate(2026, 10, 5),
    );
    expect(
      ImportDateFormat.iso.parse('2026-10-05T10:22'),
      LocalDate(2026, 10, 5),
    );
  });

  test('impossible or foreign dates are null', () {
    expect(ImportDateFormat.us.parse('02/30/2026'), isNull);
    expect(ImportDateFormat.us.parse('13/01/2026'), isNull);
    expect(ImportDateFormat.day.parse('29/02/2025'), isNull);
    expect(ImportDateFormat.day.parse('29/02/2024'), LocalDate(2024, 2, 29));
    expect(ImportDateFormat.iso.parse('10/05/2026'), isNull);
    expect(ImportDateFormat.iso.parse('2026-10-05x'), isNull);
    expect(ImportDateFormat.dotted.parse('05/10/2026'), isNull);
    expect(ImportDateFormat.us.parse('10/05/26'), isNull);
    expect(ImportDateFormat.iso.parse(''), isNull);
  });

  test('detection: one format, an ambiguous order, none', () {
    expect(detectDateFormats(['10/28/2026', '10/05/2026']), [
      ImportDateFormat.us,
    ]);
    expect(detectDateFormats(['24/10/2026', '03/10/2026']), [
      ImportDateFormat.day,
    ]);
    expect(detectDateFormats(['03/10/2026', '04/10/2026', '']), [
      ImportDateFormat.us,
      ImportDateFormat.day,
    ]);
    expect(detectDateFormats(['28.10.2026']), [ImportDateFormat.dotted]);
    // One stray row does not hide the file's format.
    expect(detectDateFormats(['2026-10-01', 'Total', '2026-10-02']), [
      ImportDateFormat.iso,
    ]);
    expect(detectDateFormats(['nope', '']), isEmpty);
  });
}
