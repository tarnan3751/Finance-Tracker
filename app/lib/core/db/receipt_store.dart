/// Where receipt photos are kept (`docs/reference/data.md`, **Receipts**): one file per
/// transaction, `receipts/<transaction id>.jpg` under the app's private support directory
/// in dev and prod, in memory in the demo flavor and the tests. A transaction's
/// `receiptPath` holds that relative name; the file never syncs, so on another device the
/// path names nothing. A new photo is staged under a temporary name and committed over the
/// old one only once the transaction's write has succeeded. [ReceiptStore.sweep] removes
/// the files no live transaction references. No path is logged. No Flutter import.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// The folder the receipts are in, relative to the store's root.
const String receiptFolder = 'receipts';

/// The relative path of transaction [transactionId]'s receipt: `receipts/<id>.jpg`.
String receiptPathFor(String transactionId) =>
    '$receiptFolder/$transactionId.jpg';

/// A photo written under a temporary name for transaction [transactionId], not yet its
/// receipt: [ReceiptStore.commit] makes it so, [ReceiptStore.discard] drops it.
final class StagedReceipt {
  /// A staged photo of [transactionId].
  const StagedReceipt(this.transactionId);

  final String transactionId;

  @override
  String toString() => 'StagedReceipt($transactionId)';
}

/// The receipt files.
abstract interface class ReceiptStore {
  /// Writes [bytes] as the staged photo of [transactionId], replacing an earlier staged
  /// one. Throws an [ArgumentError] for an id that is not letters, digits, `-` and `_`.
  Future<StagedReceipt> stage(String transactionId, Uint8List bytes);

  /// Makes [staged] its transaction's receipt, over any earlier one, and returns its
  /// path ([receiptPathFor]).
  Future<String> commit(StagedReceipt staged);

  /// Drops [staged]; the transaction's receipt, if any, stays as it was.
  Future<void> discard(StagedReceipt staged);

  /// The photo at receipt [path], or null when there is none (a path synced from another
  /// device, a removed one, or not a receipt path).
  Future<Uint8List?> read(String path);

  /// Deletes the photo at receipt [path]; nothing happens when there is none.
  Future<void> delete(String path);

  /// Deletes every file in the receipts folder whose path is not in [keep] and that was
  /// last written before [olderThan] (so a photo saved while the sweep runs stays), staged
  /// ones included. Returns how many it deleted.
  Future<int> sweep(Set<String> keep, {required DateTime olderThan});

  /// Deletes every receipt, staged ones included: the local wipe's.
  Future<void> deleteAll();
}

final RegExp _id = RegExp(r'^[A-Za-z0-9_-]+$');
final RegExp _path = RegExp(r'^receipts/[A-Za-z0-9_-]+\.jpg$');

/// Whether [path] is a receipt path, `receipts/<id>.jpg` ([receiptPathFor]).
bool isReceiptPath(String path) => _path.hasMatch(path);

void _checkId(String transactionId) {
  if (!_id.hasMatch(transactionId)) {
    throw ArgumentError.value(
      transactionId,
      'transactionId',
      'must be letters, digits, - and _',
    );
  }
}

/// The receipts as files under a root directory: the app's support directory in dev and
/// prod (private storage, outside every backup), a temporary one in tests.
final class FileReceiptStore implements ReceiptStore {
  /// A store under the directory [root] gives (looked up once, on first use).
  FileReceiptStore(Future<Directory> Function() root) : _root = root;

  final Future<Directory> Function() _root;
  Future<String>? _base;

  Future<String> get _baseDir => _base ??= _root().then((d) => d.path);

  Future<File> _file(String relative) async =>
      File(p.join(await _baseDir, relative));

  Future<File> _staged(String transactionId) =>
      _file('$receiptFolder/$transactionId.jpg.staged');

  @override
  Future<StagedReceipt> stage(String transactionId, Uint8List bytes) async {
    _checkId(transactionId);
    final File file = await _staged(transactionId);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return StagedReceipt(transactionId);
  }

  @override
  Future<String> commit(StagedReceipt staged) async {
    final String path = receiptPathFor(staged.transactionId);
    // A rename within one directory replaces the old file in one step.
    await (await _staged(staged.transactionId))
        .rename((await _file(path)).path);
    return path;
  }

  @override
  Future<void> discard(StagedReceipt staged) async {
    await _deleteIfPresent(await _staged(staged.transactionId));
  }

  @override
  Future<Uint8List?> read(String path) async {
    if (!_path.hasMatch(path)) return null;
    final File file = await _file(path);
    try {
      return await file.readAsBytes();
    } on PathNotFoundException {
      return null;
    }
  }

  @override
  Future<void> delete(String path) async {
    if (!_path.hasMatch(path)) return;
    await _deleteIfPresent(await _file(path));
  }

  @override
  Future<int> sweep(Set<String> keep, {required DateTime olderThan}) async {
    final Directory folder = Directory(p.join(await _baseDir, receiptFolder));
    if (!folder.existsSync()) return 0;
    int deleted = 0;
    await for (final FileSystemEntity entity in folder.list(
      followLinks: false,
    )) {
      if (entity is! File) continue;
      if (keep.contains('$receiptFolder/${p.basename(entity.path)}')) continue;
      final DateTime modified;
      try {
        modified = entity.lastModifiedSync();
      } on FileSystemException {
        continue;
      }
      if (!modified.isBefore(olderThan)) continue;
      if (await _deleteIfPresent(entity)) deleted++;
    }
    return deleted;
  }

  @override
  Future<void> deleteAll() async {
    final Directory folder = Directory(p.join(await _baseDir, receiptFolder));
    if (folder.existsSync()) await folder.delete(recursive: true);
  }

  // Whether [file] was there to delete.
  static Future<bool> _deleteIfPresent(File file) async {
    try {
      await file.delete();
      return true;
    } on PathNotFoundException {
      return false;
    }
  }
}

/// The receipts in memory: the demo flavor's and the tests'. Nothing outlives the store.
/// Holding no write times, its [sweep] leaves the staged photos alone and treats every
/// committed one as old.
final class MemoryReceiptStore implements ReceiptStore {
  final Map<String, Uint8List> _files = {};
  final Map<String, Uint8List> _staged = {};

  /// The receipt paths it holds, for tests.
  Set<String> get paths => {..._files.keys};

  /// How many photos are staged and neither committed nor discarded, for tests.
  int get stagedCount => _staged.length;

  @override
  Future<StagedReceipt> stage(String transactionId, Uint8List bytes) async {
    _checkId(transactionId);
    _staged[transactionId] = bytes;
    return StagedReceipt(transactionId);
  }

  @override
  Future<String> commit(StagedReceipt staged) async {
    final Uint8List? bytes = _staged.remove(staged.transactionId);
    if (bytes == null) {
      throw StateError('nothing staged for ${staged.transactionId}');
    }
    final String path = receiptPathFor(staged.transactionId);
    _files[path] = bytes;
    return path;
  }

  @override
  Future<void> discard(StagedReceipt staged) async {
    _staged.remove(staged.transactionId);
  }

  @override
  Future<Uint8List?> read(String path) async => _files[path];

  @override
  Future<void> delete(String path) async {
    _files.remove(path);
  }

  @override
  Future<int> sweep(Set<String> keep, {required DateTime olderThan}) async {
    final List<String> gone = [
      for (final String path in _files.keys)
        if (!keep.contains(path)) path,
    ];
    gone.forEach(_files.remove);
    return gone.length;
  }

  @override
  Future<void> deleteAll() async {
    _files.clear();
    _staged.clear();
  }
}
