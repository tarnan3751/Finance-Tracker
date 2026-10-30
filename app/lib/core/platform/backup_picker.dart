/// The platform boundary for opening a backup file (`docs/reference/app-core.md`, **The
/// backup picker**; `docs/reference/backup.md`): the app asks a [BackupPicker] for a
/// file the user chooses and gets back a [PickedFile], its length and its bytes read on
/// demand, so a caller can look at the start of a file and refuse it before reading it
/// whole. `flutter_file_dialog`'s Storage Access Framework "open document" is behind it
/// in dev and prod; a fake stands in for the demo flavor and the tests. Pure Dart, no
/// Flutter import.
library;

import 'dart:typed_data';

/// Lets the user choose a backup file.
abstract interface class BackupPicker {
  /// The file the user chose, or null when they chose none; the caller closes it. Throws
  /// [BackupPickFailedException] when the dialog fails.
  Future<PickedFile?> pick();
}

/// A chosen file.
abstract interface class PickedFile {
  /// Its length, bytes.
  int get length;

  /// Its bytes from [start] to [end] (the end of the file by default). Throws
  /// [BackupPickFailedException] when the file cannot be read.
  Future<Uint8List> read([int start = 0, int? end]);

  /// Lets the file go (the platform's copy is deleted).
  Future<void> close();
}

/// The chosen file could not be read, or the dialog failed.
final class BackupPickFailedException implements Exception {
  /// The exception.
  const BackupPickFailedException();

  @override
  String toString() => 'BackupPickFailedException';
}
