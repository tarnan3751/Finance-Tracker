/// The [BackupPicker] of the demo flavor and the tests: it hands back the file a test
/// put in [FakeBackupPicker.file] (none by default), counts the calls, and records the
/// ranges read.
library;

import 'dart:typed_data';

import 'package:finance_tracker/core/platform/backup_picker.dart';

/// A picker whose user always chooses [file].
final class FakeBackupPicker implements BackupPicker {
  /// A picker choosing [file]; with [failure] set, every call throws it; with [length]
  /// set, the file says it is that long (a test of a file too large to build).
  FakeBackupPicker({this.file, this.failure, this.length});

  /// What the next pick returns; null is the user choosing nothing.
  Uint8List? file;

  /// What every call throws, when set.
  Exception? failure;

  /// The length the chosen file reports, when set.
  int? length;

  /// How many times [pick] was called.
  int calls = 0;

  /// The ranges read, in order, `(start, end)`.
  final List<(int, int)> reads = [];

  /// How many picked files were closed.
  int closed = 0;

  @override
  Future<PickedFile?> pick() async {
    calls++;
    if (failure case final Exception e) throw e;
    final Uint8List? bytes = file;
    return bytes == null ? null : _FakeFile(this, bytes);
  }
}

final class _FakeFile implements PickedFile {
  _FakeFile(this._picker, this._bytes);

  final FakeBackupPicker _picker;
  final Uint8List _bytes;

  @override
  int get length => _picker.length ?? _bytes.length;

  @override
  Future<Uint8List> read([int start = 0, int? end]) async {
    final int stop = (end ?? _bytes.length).clamp(start, _bytes.length);
    _picker.reads.add((start, stop));
    return Uint8List.sublistView(_bytes, start, stop);
  }

  @override
  Future<void> close() async => _picker.closed++;
}
