/// The [BackupPicker] of the dev and prod flavors: `flutter_file_dialog`'s pick, the
/// Storage Access Framework's "open document" (no permission needed), with no MIME
/// filter (the system does not know `.ftbk`; the header's magic tells a backup from any
/// other file). The plugin copies the chosen file into the app's cache; the copy is read
/// in the ranges asked for and deleted on close. Nothing about the file is logged but the
/// platform's error code.
library;

import 'dart:io';

import 'package:finance_tracker/core/platform/backup_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final Logger _log = Logger('backup_picker');

/// Backup files chosen through the system's "open document" dialog.
final class PlatformBackupPicker implements BackupPicker {
  /// The picker.
  const PlatformBackupPicker();

  @override
  Future<PickedFile?> pick() async {
    final String? path;
    try {
      path = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(),
      );
    } on PlatformException catch (e) {
      _log.warning('the backup could not be picked: ${e.code}');
      throw const BackupPickFailedException();
    }
    if (path == null) return null;
    final File copy = File(path);
    try {
      return _CopiedFile(copy, await copy.length());
    } on FileSystemException {
      _log.warning('the picked backup could not be read');
      await _delete(copy);
      throw const BackupPickFailedException();
    }
  }
}

final class _CopiedFile implements PickedFile {
  _CopiedFile(this._file, this.length);

  final File _file;

  @override
  final int length;

  @override
  Future<Uint8List> read([int start = 0, int? end]) async {
    final int stop = end ?? length;
    try {
      final RandomAccessFile raf = await _file.open();
      try {
        await raf.setPosition(start);
        return await raf.read(stop - start);
      } finally {
        await raf.close();
      }
    } on FileSystemException {
      _log.warning('the picked backup could not be read');
      throw const BackupPickFailedException();
    }
  }

  @override
  Future<void> close() => _delete(_file);
}

// Deletes the plugin's copy, alone in a directory of its own, `file_dialog-<uuid>`.
Future<void> _delete(File copy) async {
  final Directory dir = copy.parent;
  try {
    if (p.basename(dir.path).startsWith('file_dialog-')) {
      await dir.delete(recursive: true);
    } else {
      await copy.delete();
    }
  } on FileSystemException {
    // The cache is the system's to clear.
  }
}
