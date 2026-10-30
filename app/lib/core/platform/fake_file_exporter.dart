/// The [FileExporter] of the demo flavor and the tests: nothing leaves the app. Every
/// call is recorded with its bytes, so a test (or the demo's integration test) reads back
/// what would have been saved or shared.
library;

import 'dart:typed_data';

import 'package:finance_tracker/core/platform/file_exporter.dart';

/// Which call an [ExportCall] records.
enum ExportKind { saveAs, share }

/// One call to the fake.
final class ExportCall {
  /// A call.
  const ExportCall(this.kind, this.bytes, this.fileName, this.mimeType);

  /// Save as or share.
  final ExportKind kind;

  /// The file's bytes.
  final Uint8List bytes;

  /// The file's name.
  final String fileName;

  /// The file's MIME type.
  final String mimeType;

  @override
  String toString() =>
      'ExportCall($kind, $fileName, $mimeType, ${bytes.length} bytes)';
}

/// Files saved and shared nowhere.
final class FakeFileExporter implements FileExporter {
  /// An exporter whose "Save as" completes with [outcome] ([SaveOutcome.saved] by
  /// default); with [failure] set, every call throws it after being recorded.
  FakeFileExporter({this.outcome = SaveOutcome.saved, this.failure});

  /// What the next "Save as" completes with.
  SaveOutcome outcome;

  /// What every call throws, when set.
  Exception? failure;

  /// The calls, oldest first.
  final List<ExportCall> calls = [];

  @override
  Future<SaveOutcome> saveAs(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    calls.add(ExportCall(ExportKind.saveAs, bytes, fileName, mimeType));
    if (failure case final Exception e) throw e;
    return outcome;
  }

  @override
  Future<void> share(Uint8List bytes, String fileName, String mimeType) async {
    calls.add(ExportCall(ExportKind.share, bytes, fileName, mimeType));
    if (failure case final Exception e) throw e;
  }
}
