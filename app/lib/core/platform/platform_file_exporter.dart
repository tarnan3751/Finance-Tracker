/// The [FileExporter] of the dev and prod flavors. The bytes are written to a file of
/// their own name, in a directory of the call's own under the app's temporary directory
/// (`export/`, so two calls for one name never share a file), which
/// `flutter_file_dialog` hands to the Storage Access Framework's "Save as" dialog (no
/// permission needed) or `share_plus` to the share sheet (it copies the file into its
/// own `cache/share_plus/` behind its `FileProvider` first). The temporary directory is
/// deleted when the call returns, whatever the outcome. Nothing about the file is logged
/// but the platform's error code.
library;

import 'dart:io';

import 'package:finance_tracker/core/platform/file_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

final Logger _log = Logger('file_exporter');

/// Files saved through the "Save as" dialog and shared through the share sheet.
final class PlatformFileExporter implements FileExporter {
  /// An exporter writing its temporary files under [temporaryDirectory]
  /// (`getTemporaryDirectory`).
  PlatformFileExporter(this.temporaryDirectory);

  /// Where the temporary files go.
  final Future<Directory> Function() temporaryDirectory;

  @override
  Future<SaveOutcome> saveAs(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) => _withFile(bytes, fileName, (path) async {
    final String? saved = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        sourceFilePath: path,
        mimeTypesFilter: [mimeType],
      ),
    );
    return saved == null ? SaveOutcome.cancelled : SaveOutcome.saved;
  });

  @override
  Future<void> share(Uint8List bytes, String fileName, String mimeType) =>
      _withFile(bytes, fileName, (path) async {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path, mimeType: mimeType)],
            fileNameOverrides: [fileName],
          ),
        );
      });

  // Runs [use] on a temporary file holding [bytes], named [fileName], in a directory of
  // its own, then deletes the directory.
  Future<T> _withFile<T>(
    Uint8List bytes,
    String fileName,
    Future<T> Function(String path) use,
  ) async {
    Directory? dir;
    try {
      final Directory exports = Directory(
        p.join((await temporaryDirectory()).path, 'export'),
      );
      await exports.create(recursive: true);
      dir = await exports.createTemp();
      final File file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes, flush: true);
      return await use(file.path);
    } on PlatformException catch (e) {
      _log.warning('the export failed: ${e.code}');
      throw const ExportFailedException();
    } on FileSystemException {
      _log.warning('the export file could not be written');
      throw const ExportFailedException();
    } finally {
      try {
        await dir?.delete(recursive: true);
      } on FileSystemException {
        // Never written, or already gone.
      }
    }
  }
}
