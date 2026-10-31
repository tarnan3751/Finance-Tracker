// The demo's sample export: the same file for the same day, named for its fictional
// bank, read like a bank's export (its title line passed over, US dates past the 12th,
// so the order is never ambiguous); and the flavors' CSV pickers: the system dialog with
// the CSV types in dev and prod, the sample in the demo.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/csv_picker_provider.dart';
import 'package:finance_tracker/core/platform/platform_backup_picker.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/import/data/demo_csv_picker.dart';
import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/date_formats.dart';
import 'package:finance_tracker/features/import/domain/header_detection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('the sample: one file per day, a bank export in shape', () async {
    final LocalDate today = LocalDate(2026, 3, 9);
    expect(demoCsv(today), demoCsv(today));
    expect(demoCsv(today), isNot(demoCsv(today.addDays(1))));
    final CsvTable table = await readCsv(demoCsv(today));
    final int header = findHeaderRow(table.rows)!;
    expect(table.rows[header], ['Date', 'Description', 'Amount', 'Balance']);
    final List<List<String>> rows = table.rows.sublist(header + 1);
    expect(rows, hasLength(16));
    expect(detectDateFormats([for (final r in rows) r[0]]), [
      ImportDateFormat.us,
    ]);
    expect(rows.last[0], '03/08/2026');
  });

  test('the demo picker answers the sample for the clock', () async {
    final Clock clock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);
    final PickedFile picked = (await DemoCsvPicker(clock).pick())!;
    expect(picked.name, demoCsvFileName);
    expect(await picked.read(), demoCsv(clock.today()));
  });

  test('each flavor its picker', () {
    BackupPicker pickerOf(AppConfig config) {
      final ProviderContainer c = ProviderContainer.test(
        overrides: [
          ...filePickerOverridesFor(config),
          clockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC),
          ),
        ],
      );
      return c.read(csvPickerProvider);
    }

    for (final AppConfig config in [AppConfig.dev(), AppConfig.prod()]) {
      final BackupPicker picker = pickerOf(config);
      expect(
        picker,
        isA<PlatformBackupPicker>().having(
          (p) => p.mimeTypesFilter,
          'mimeTypesFilter',
          csvMimeTypes,
        ),
      );
    }
    expect(pickerOf(AppConfig.demo()), isA<DemoCsvPicker>());
  });
}
