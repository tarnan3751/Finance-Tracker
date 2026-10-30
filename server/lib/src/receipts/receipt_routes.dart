/// Receipt photos by content hash: `PUT /receipts/{sha256}` and `GET /receipts/{sha256}`
/// (`docs/reference/server.md`, **Receipts**).
///
/// One file per hash, `<directory>/<sha256>`, shared by every user who stored those
/// bytes; the `receipts` table says who did (one row per user and hash), and only a user
/// with a row may read the file, so another user's hash is a 404 like an unknown one. A
/// file is written whenever it is missing, whoever owns the hash (so a store repairs a
/// row whose file a racing deletion removed), under a temporary name renamed into place,
/// so a reader never sees part of one; the row is added only after the file is there.
/// A store and a deletion's removal of the same hash run one at a time, under a lock
/// per hash in this process (the dev server is one process), so a removal can never
/// take a file between a store's check and its row. The hash is checked against the
/// pattern before any path is built from it. Nothing about a photo is logged but its
/// hash's absence of a file.
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/dart.dart' show DartSha256;
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

final _log = Logger('receipts');

/// The largest photo a `PUT` takes: 5 MiB.
const int receiptCap = 5 * 1024 * 1024;

/// The contract's `sha256` path pattern.
final RegExp receiptHashShape = RegExp(r'^[0-9a-f]{64}$');

/// The media type of photo [bytes] by their signature: `image/png` for a PNG, else
/// `image/jpeg`.
String receiptMediaType(List<int> bytes) {
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length < png.length) return 'image/jpeg';
  for (var i = 0; i < png.length; i++) {
    if (bytes[i] != png[i]) return 'image/jpeg';
  }
  return 'image/png';
}

/// The receipt files under [directory] and their owners in [db].
final class ReceiptService {
  /// The service; [now] stamps a row's `created_at`.
  ReceiptService({
    required this.db,
    required this.directory,
    required this.now,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// The database.
  final AppDatabase db;

  /// Where the files are.
  final Directory directory;

  /// The server's clock.
  final DateTime Function() now;

  final Random _random;

  // The tail of the work queued on each hash, removed when the queue empties.
  final Map<String, Future<void>> _locks = {};

  /// Runs [body] once every earlier [locked] call on [hash] has finished, and before any
  /// later one starts.
  Future<T> locked<T>(String hash, Future<T> Function() body) {
    final Future<void> previous = _locks[hash] ?? Future<void>.value();
    final Future<T> result = previous.then((_) => body());
    final Future<void> tail = result.then<void>((_) {}, onError: (Object _) {});
    _locks[hash] = tail;
    tail.then((_) {
      if (identical(_locks[hash], tail)) _locks.remove(hash);
    });
    return result;
  }

  /// Called inside a store's lock between its file check and its write; null except in
  /// the tests, which pause there to race a deletion against it.
  Future<void> Function()? afterFileCheck;

  /// The file of [hash], which must already match [receiptHashShape].
  File fileOf(String hash) {
    if (!receiptHashShape.hasMatch(hash)) {
      throw ArgumentError.value(hash, 'hash', 'not a sha256');
    }
    return File('${directory.path}${Platform.pathSeparator}$hash');
  }

  /// Stores [bytes], whose SHA-256 is [hash], for [userId]: writes the file when it is
  /// missing, then adds the user's row when it is missing; nothing when both are there.
  /// The caller has already checked the shape, the cap and the hash. Runs under the
  /// hash's lock.
  Future<void> store(String userId, String hash, Uint8List bytes) => locked(
    hash,
    () async {
      final file = fileOf(hash);
      final bool missing = !file.existsSync();
      await afterFileCheck?.call();
      if (missing) {
        await directory.create(recursive: true);
        final temp = File(
          '${file.path}.${_random.nextInt(1 << 32).toRadixString(16)}.tmp',
        );
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(file.path);
      }
      await db.transaction((tx) async {
        tx.execute(
          'INSERT OR IGNORE INTO receipts (user_id, sha256, size, created_at) '
          'VALUES (?, ?, ?, ?)',
          [userId, hash, bytes.length, now().millisecondsSinceEpoch],
        );
      });
    },
  );

  /// The bytes [userId] stored under [hash], or null when they stored none (or the file
  /// is gone).
  Future<Uint8List?> read(String userId, String hash) async {
    final owned = await db.read(
      (tx) => tx.first(
        'SELECT 1 FROM receipts WHERE user_id = ? AND sha256 = ?',
        [userId, hash],
      ),
    );
    if (owned == null) return null;
    try {
      return await fileOf(hash).readAsBytes();
    } on PathNotFoundException {
      _log.warning(const LogEvent('receipt_file_missing'));
      return null;
    }
  }
}

void _checkHash(String hash) {
  if (!receiptHashShape.hasMatch(hash)) {
    throw ValidationException.single(
      'sha256',
      'must be 64 lower-case hex digits',
    );
  }
}

/// The receipt routes over [receipts].
List<ApiRoute> receiptRoutes(ReceiptService receipts) => [
  ApiRoute('putReceipt', 'put', '/receipts/{sha256}', (r) async {
    final hash = r.param('sha256');
    _checkHash(hash);
    final type = (r.raw.headers['content-type'] ?? '')
        .split(';')
        .first
        .trim()
        .toLowerCase();
    if (type != 'image/jpeg' && type != 'image/png') {
      throw const ProblemException(
        415,
        ProblemCode.unsupportedMediaType,
        detail: 'A receipt is image/jpeg or image/png',
      );
    }
    final declared = r.raw.contentLength;
    if (declared != null && declared > receiptCap) throw _tooLarge;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in r.raw.read()) {
      builder.add(chunk);
      if (builder.length > receiptCap) throw _tooLarge;
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      throw ValidationException.single('', 'a receipt is not empty');
    }
    final actual = _hex(const DartSha256().hashSync(bytes).bytes);
    if (actual != hash) {
      throw ValidationException.single(
        '',
        "the bytes do not hash to the path's sha256",
      );
    }
    await receipts.store(r.userId, hash, bytes);
    return jsonResponse({'sha256': hash, 'size': bytes.length});
  }),
  ApiRoute('getReceipt', 'get', '/receipts/{sha256}', (r) async {
    final hash = r.param('sha256');
    _checkHash(hash);
    final bytes = await receipts.read(r.userId, hash);
    if (bytes == null) {
      throw const ProblemException.notFound('No receipt with that hash');
    }
    return Response.ok(
      bytes,
      headers: {'content-type': receiptMediaType(bytes)},
    );
  }),
];

const _tooLarge = ProblemException(
  413,
  ProblemCode.payloadTooLarge,
  detail: 'A receipt is at most 5 MiB',
);

String _hex(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
