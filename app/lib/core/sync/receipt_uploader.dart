/// The upload of receipt photos before the changes that name them
/// (`docs/reference/sync-app.md`, **Receipts**): the sync session's `beforePush`.
///
/// An outbox entry of a transaction whose payload sets `receipt_sha256` to a hash waits
/// until the photo with that hash is on the server, so a device that pulls the change can
/// fetch it. For each such entry of a batch:
///
/// - if the record no longer holds that hash (a later edit here, or a pulled change,
///   replaced it), the entry goes as it is: its value has already lost to a later one,
///   on this device and so on every device;
/// - if the photo is not here with that hash (its file replaced or gone), the entry goes:
///   the bytes cannot be had, and the server holds them if they were ever uploaded;
/// - otherwise the photo is uploaded (`PUT /receipts/{sha256}`, idempotent): on success,
///   or a refusal that no retry can change (400, 413, 415), the entry goes, the refusal
///   logged by status only; any other failure (no network, the server's) holds the entry
///   back until the next session, without holding up the entries behind it.
///
/// One uploader serves one session: each hash is uploaded once, and one that failed is
/// not tried again in that session. Logs no hash, path or photo.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

final Logger _log = Logger('sync');

/// The receipt field of a transaction record.
const String receiptHashField = 'receipt_sha256';

/// Uploads the receipt photos a session's outbox names.
final class ReceiptUploader {
  /// An uploader for one session over [_store], reading photos from [_receipts] and
  /// uploading through [_api].
  ReceiptUploader(this._api, this._receipts, this._store);

  final FinanceApi _api;
  final ReceiptStore _receipts;
  final SyncStore _store;

  // Hashes this session settled: true once uploaded (or refused for good), false when
  // the upload failed and waits for the next session.
  final Map<String, bool> _settled = {};

  /// The entries of [batch] that may be pushed now, in order (`SyncSession.beforePush`).
  Future<List<ChangeLogEntry>> ready(List<ChangeLogEntry> batch) async => [
    for (final ChangeLogEntry e in batch)
      if (await _ready(e)) e,
  ];

  Future<bool> _ready(ChangeLogEntry entry) async {
    if (entry.entityType != EntityType.transaction) return true;
    final Object? hash = entry.payload[receiptHashField];
    if (hash is! String) return true;
    if (_settled[hash] case final bool done) return done;
    final EntityRecord? record = await _store.read(
      EntityType.transaction,
      entry.entityId,
    );
    if (record?.fields[receiptHashField] != hash) return true;
    final Uint8List? bytes = await _receipts.read(
      receiptPathFor(entry.entityId),
    );
    if (bytes == null || sha256.convert(bytes).toString() != hash) return true;
    try {
      await _api.putReceipt(hash, bytes);
      return _settled[hash] = true;
    } on ApiException catch (e) {
      if (e.status case 400 || 413 || 415) {
        _log.warning('a receipt upload was refused: ${e.status}');
        return _settled[hash] = true;
      }
      _log.warning('a receipt upload failed: ${e.runtimeType}');
      return _settled[hash] = false;
    }
  }
}
