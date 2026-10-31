/// Which [BackupPicker] opens a CSV to import (`docs/reference/import.md`, **Picking**):
/// the fake by default (the tests), the system's "open document" dialog showing
/// [csvMimeTypes] in dev and prod, and the demo's sample export in the demo flavor
/// (`filePickerOverridesFor`). The backup picker's seam, a provider of its own.
library;

import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'csv_picker_provider.g.dart';

/// The MIME types the dialog offers for an import: text (CSV is `text/csv` or
/// `text/comma-separated-values`, sometimes `text/plain`), `application/csv`, and the
/// spreadsheet type that Drive and many banks give a CSV.
const List<String> csvMimeTypes = [
  'text/*',
  'application/csv',
  'application/vnd.ms-excel',
];

/// The CSV picker.
@Riverpod(keepAlive: true)
BackupPicker csvPicker(Ref ref) => FakeBackupPicker();
