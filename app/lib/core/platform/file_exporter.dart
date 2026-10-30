/// The platform boundary for exported files (`docs/reference/app-core.md`, **The file
/// exporter**; `docs/reference/export.md`): the app hands a [FileExporter] the bytes of a
/// file it made (the monthly report's PDF, the transactions' CSV) and the system's "Save
/// as" dialog saves them where the user picks, or the share sheet sends them on.
/// `flutter_file_dialog` and `share_plus` are behind it in dev and prod; a fake stands in
/// for the demo flavor and the tests. Pure Dart, no Flutter import.
library;

import 'dart:typed_data';

/// Saves or shares a file the app made.
abstract interface class FileExporter {
  /// Offers [bytes] to the system's "Save as" dialog under the suggested [fileName], of
  /// [mimeType]. Throws [ExportFailedException] when the file cannot be written or the
  /// dialog fails.
  Future<SaveOutcome> saveAs(Uint8List bytes, String fileName, String mimeType);

  /// Offers [bytes] to the system's share sheet as the file [fileName], of [mimeType].
  /// Throws [ExportFailedException] when the file cannot be written or the sheet fails.
  Future<void> share(Uint8List bytes, String fileName, String mimeType);
}

/// What became of a "Save as".
enum SaveOutcome {
  /// The user picked a place and the file was saved there.
  saved,

  /// The user closed the dialog without saving.
  cancelled,
}

/// The file could not be saved or shared.
final class ExportFailedException implements Exception {
  /// The exception.
  const ExportFailedException();

  @override
  String toString() => 'ExportFailedException';
}
