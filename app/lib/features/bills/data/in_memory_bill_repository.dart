/// A [BillRepository] held in memory: what tests use, and the base of the demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Bills kept in memory for the life of the object; deletes are stamped from the clock.
/// Every write records the bill it changed through [recorder].
base class InMemoryBillRepository implements BillRepository {
  /// A repository holding [initial], stamping deletes from [_clock] and recording
  /// through [recorder].
  InMemoryBillRepository(
    this._clock, {
    required this.recorder,
    List<BillReminder> initial = const [],
  }) {
    for (final BillReminder bill in initial) {
      _bills[bill.id] = (bill: bill, deletedAt: null);
    }
  }

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  final Clock _clock;
  final Map<String, ({BillReminder bill, DateTime? deletedAt})> _bills = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<BillReminder> _live() =>
      [
        for (final entry in _bills.values)
          if (entry.deletedAt == null) entry.bill,
      ]..sort((a, b) {
        final int byDate = a.dueDate.compareTo(b.dueDate);
        return byDate != 0 ? byDate : compareBinary(a.id, b.id);
      });

  Stream<T> _watch<T>(T Function() read, bool Function(T, T) same) =>
      Stream<T>.multi((controller) {
        controller.add(read());
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(read()),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(same);

  @override
  Stream<List<BillReminder>> watchAll() => _watch(_live, sameList);

  @override
  Stream<BillReminder?> watchById(String id) => _watch(() {
    final entry = _bills[id];
    return entry == null || entry.deletedAt != null ? null : entry.bill;
  }, (a, b) => a == b);

  @override
  Future<void> upsert(BillReminder bill) async {
    final existing = _bills[bill.id];
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('bill', bill.id);
    }
    _bills[bill.id] = (bill: bill, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.billReminder,
      bill.id,
      existing == null ? null : billRecordJson(existing.bill),
      billRecordJson(bill),
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = _bills[id];
    if (existing == null || existing.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    _bills[id] = (bill: existing.bill, deletedAt: now);
    _changes.add(null);
    await recorder.record(
      EntityType.billReminder,
      id,
      billRecordJson(existing.bill),
      billRecordJson(existing.bill, deletedAt: now),
    );
  }

  @override
  Future<void> restore(String id) async {
    final existing = _bills[id];
    final DateTime? deletedAt = existing?.deletedAt;
    if (existing == null || deletedAt == null) return;
    _bills[id] = (bill: existing.bill, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.billReminder,
      id,
      billRecordJson(existing.bill, deletedAt: deletedAt),
      billRecordJson(existing.bill),
    );
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
