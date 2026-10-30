/// Which [BackupPicker] opens backup files: the fake by default (the demo flavor and the
/// tests), `flutter_file_dialog` in dev and prod (`overridesFor`).
library;

import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:finance_tracker/core/platform/fake_backup_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_picker_provider.g.dart';

/// The backup picker.
@Riverpod(keepAlive: true)
BackupPicker backupPicker(Ref ref) => FakeBackupPicker();
