/// The [RecurringStreamRepository] of the dev and prod flavors, over the
/// `recurring_streams` and `stream_overrides` tables (`docs/reference/data.md`).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart'
    show checkStreamBatch, serverStreamSources;
import 'package:finance_tracker/features/recurring/data/stream_override_rows.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:shared_models/shared_models.dart';

/// Streams and overrides in [AppDatabase]. Rows are stamped from the clock. Every
/// override write records what it changed through [_recorder] in the same database
/// transaction; the stream replacements record nothing.
final class DriftRecurringStreamRepository
    implements RecurringStreamRepository {
  /// The repository over [_database], stamping writes from [_clock] and recording
  /// override writes through `recorder`.
  DriftRecurringStreamRepository(
    this._database,
    this._clock, {
    required this._recorder,
  });

  final AppDatabase _database;
  final Clock _clock;
  final ChangeRecorder _recorder;

  $RecurringStreamsTable get _streams => _database.recurringStreams;
  $StreamOverridesTable get _overrides => _database.streamOverrides;

  JoinedSelectStatement<HasResultSet, dynamic> _joined() =>
      _database.select(_streams).join([
        leftOuterJoin(
          _overrides,
          _overrides.streamId.equalsExp(_streams.id) &
              _overrides.deletedAt.isNull(),
        ),
      ]);

  StreamView _view(TypedResult row) {
    final StreamOverrideRow? override = row.readTableOrNull(_overrides);
    return StreamView(
      recurringStreamFromRow(row.readTable(_streams)),
      override == null ? null : streamOverrideFromRow(override),
    );
  }

  @override
  Stream<List<StreamView>> watchAll() =>
      (_joined()..orderBy([
            OrderingTerm.asc(_streams.merchantName.collate(Collate.noCase)),
            OrderingTerm.asc(_streams.id),
          ]))
          .watch()
          .map((rows) => rows.map(_view).toList())
          .distinct(sameList);

  @override
  Stream<StreamView?> watchById(String id) =>
      (_joined()..where(_streams.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _view(row))
          .distinct();

  @override
  Future<void> applyPlaid(List<RecurringStream> streams) =>
      _replace(streams, serverStreamSources);

  @override
  Future<void> replaceDetected(List<RecurringStream> streams) =>
      _replace(streams, const {RecurringSource.detected});

  Future<void> _replace(
    List<RecurringStream> streams,
    Set<RecurringSource> sources,
  ) async {
    checkStreamBatch(streams, sources);
    final DateTime now = _clock.nowUtc();
    await _database.transaction(() async {
      await (_database.delete(
        _streams,
      )..where((s) => s.source.isInValues(sources))).go();
      await _database.batch(
        (batch) => batch.insertAllOnConflictUpdate(_streams, [
          for (final RecurringStream s in streams)
            recurringStreamCompanion(s, pulledAt: now),
        ]),
      );
    });
  }

  @override
  Future<void> setOverride(
    String streamId,
    StreamOverride Function(StreamOverride current) change,
  ) => _database.transaction(() async {
    final StreamOverrideRow? row = await _row(streamId);
    final StreamOverride current = row == null || row.deletedAt != null
        ? const StreamOverride()
        : streamOverrideFromRow(row);
    final StreamOverride next = change(current);
    if (next == current) return;
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_overrides)
        .insertOnConflictUpdate(
          streamOverrideCompanion(
            streamId,
            next,
            createdAt: row?.createdAt ?? now,
            now: now,
            deletedAt: const Value(null),
          ),
        );
    await _recorder.record(
      EntityType.recurringStream,
      streamId,
      row == null
          ? streamOverrideRecordJson(const StreamOverride())
          : streamOverrideRecordJson(
              streamOverrideFromRow(row),
              deletedAt: row.deletedAt,
            ),
      streamOverrideRecordJson(next),
    );
  });

  @override
  Future<void> clearOverride(String streamId) => _database.transaction(
    () async {
      final StreamOverrideRow? row = await _row(streamId);
      if (row == null || row.deletedAt != null) return;
      final DateTime now = _clock.nowUtc();
      await (_database.update(
        _overrides,
      )..where((o) => o.streamId.equals(streamId))).write(
        StreamOverridesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      final StreamOverride override = streamOverrideFromRow(row);
      await _recorder.record(
        EntityType.recurringStream,
        streamId,
        streamOverrideRecordJson(override),
        streamOverrideRecordJson(override, deletedAt: now),
      );
    },
  );

  Future<StreamOverrideRow?> _row(String streamId) => (_database.select(
    _overrides,
  )..where((o) => o.streamId.equals(streamId))).getSingleOrNull();
}

/// The row of [stream], written at [pulledAt]; the amount is `average_amount_minor` in
/// the row's `currency`, the members a JSON array.
RecurringStreamsCompanion recurringStreamCompanion(
  RecurringStream stream, {
  required DateTime pulledAt,
}) => RecurringStreamsCompanion(
  id: Value(stream.id),
  accountId: Value(stream.accountId),
  merchantName: Value(stream.merchantName),
  cadence: Value(stream.cadence),
  averageAmountMinor: Value(stream.averageAmount.minorUnits),
  currency: Value(stream.averageAmount.currencyCode),
  lastExpected: Value(stream.lastExpected),
  nextExpected: Value(stream.nextExpected),
  status: Value(stream.status),
  isSubscription: Value(stream.isSubscription),
  source: Value(stream.source),
  transactionIds: Value(jsonEncode(stream.transactionIds)),
  pulledAt: Value(pulledAt),
);

/// The [RecurringStream] a row holds.
RecurringStream recurringStreamFromRow(RecurringStreamRow row) =>
    RecurringStream(
      id: row.id,
      accountId: row.accountId,
      merchantName: row.merchantName,
      cadence: row.cadence,
      averageAmount: Money(row.averageAmountMinor, row.currency),
      lastExpected: row.lastExpected,
      nextExpected: row.nextExpected,
      status: row.status,
      isSubscription: row.isSubscription,
      source: row.source,
      transactionIds: [
        for (final Object? id
            in jsonDecode(row.transactionIds) as List<Object?>)
          id! as String,
      ],
    );
