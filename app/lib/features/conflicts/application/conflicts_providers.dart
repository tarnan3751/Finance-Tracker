/// The Conflicts screen's state and its two actions (`docs/reference/sync-app.md`,
/// **Conflicts**).
library;

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/conflicts/domain/conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart'
    show receiptHash;
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

part 'conflicts_providers.g.dart';

/// This device's conflicts, the most recently seen first.
@riverpod
Stream<List<SyncConflict>> conflicts(Ref ref) =>
    ref.watch(conflictStoreProvider).watch();

/// How many conflicts there are (0 until they load): Settings → Sync's count.
@riverpod
int conflictCount(Ref ref) => ref.watch(conflictsProvider).value?.length ?? 0;

/// The names of the user's devices by id, for the conflicts' "from" lines; empty when
/// the list cannot be had (offline, signed out), when the screen shows node ids instead.
@riverpod
Future<Map<String, String>> conflictDeviceNames(Ref ref) async {
  try {
    return {
      for (final Device d in await ref.watch(financeApiProvider).listDevices())
        d.id: d.name,
    };
  } on Object {
    return const {};
  }
}

/// The conflicts' actions.
@riverpod
ConflictActions conflictActions(Ref ref) => ConflictActions(
  ref.watch(conflictStoreProvider),
  ref.watch(changeRecorderProvider),
  ref.watch(clockProvider),
  ref.watch(transactionRepositoryProvider),
  receipts: ref.watch(receiptStoreProvider),
);

/// "Keep this device's value" and "Keep the other".
final class ConflictActions {
  ConflictActions(
    this._conflicts,
    this._recorder,
    this._clock,
    this._transactions, {
    this._receipts,
  });

  final ConflictStore _conflicts;
  final ChangeRecorder _recorder;
  final Clock _clock;
  final TransactionRepository _transactions;

  // Where a receipt photo's conflict checks its bytes are still here.
  final ReceiptStore? _receipts;

  /// "Keep the other": the value that won stays; the conflict is forgotten.
  Future<void> keepOther(SyncConflict conflict) => _conflicts.dismiss(conflict);

  /// "Keep this device's value": writes [conflict]'s lost value again as a new local
  /// change, through the engine's local edit path over the device's sync store (the
  /// recorder's), so the record is materialised exactly as a pulled merge is and the
  /// change syncs. It is stamped after the clock that won, so it wins on every device.
  /// When the entity is gone or deleted (a transaction whose row is, as a Plaid removal
  /// leaves one, whose record has no tombstone), or the field has moved on since,
  /// nothing is written and the conflict is only forgotten; on a build that records
  /// nothing (the demo), likewise. A receipt photo's conflict is refused, forgotten and
  /// answered false, when the file here no longer hashes to the kept photo (another
  /// photo fetched over it since the screen looked): keeping it would name a photo no
  /// device or server has. True otherwise.
  Future<bool> keepLocal(SyncConflict conflict) async {
    final ChangeRecorder recorder = _recorder;
    if (recorder is! EngineChangeRecorder) {
      await _conflicts.dismiss(conflict);
      return true;
    }
    final SyncStore store = recorder.store;
    return store.transaction(() async {
      if (!await _photoHere(conflict)) {
        await _conflicts.dismiss(conflict);
        return false;
      }
      final EntityRecord? record = await store.read(
        conflict.entityType,
        conflict.entityId,
      );
      if (record != null &&
          !record.isDeleted &&
          record.fieldClocks[conflict.field] == conflict.remoteClock &&
          await _live(conflict)) {
        final DateTime now = _clock.nowUtc();
        await LocalEditor(store, await recorder.clock()).recordChange(
          conflict.entityType,
          conflict.entityId,
          record.fields,
          {
            ...record.fields,
            conflict.field: conflict.localValue,
            if (record.fields.containsKey(_updatedAt))
              _updatedAt: const UtcInstantConverter().toJson(now),
          },
          now.millisecondsSinceEpoch,
        );
      }
      // The write settled it already where the store keeps conflicts by its records.
      await _conflicts.dismiss(conflict);
      return true;
    });
  }

  // Whether [conflict], when it is a receipt photo's, still has its photo's bytes here:
  // the file read and hashed now, not as the screen last saw it.
  Future<bool> _photoHere(SyncConflict conflict) async {
    final Object? hash = conflict.localValue;
    final ReceiptStore? receipts = _receipts;
    if (conflict.field != _receiptHashField ||
        hash is! String ||
        receipts == null) {
      return true;
    }
    final List<int>? bytes = await receipts.read(
      receiptPathFor(conflict.entityId),
    );
    return bytes != null && receiptHash(bytes) == hash;
  }

  // Whether [conflict]'s entity still has a live row where the record cannot say: a
  // transaction, whose Plaid removal tombstones the row only.
  Future<bool> _live(SyncConflict conflict) async =>
      conflict.entityType != EntityType.transaction ||
      await currentValue(_transactions.watchById(conflict.entityId)) != null;
}

const String _updatedAt = 'updated_at';
const String _receiptHashField = 'receipt_sha256';
