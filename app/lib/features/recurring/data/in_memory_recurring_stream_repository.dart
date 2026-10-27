/// A [RecurringStreamRepository] held in memory: what tests use, and the base of the
/// demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:shared_models/shared_models.dart';

/// Streams and overrides kept in memory for the life of the object; they depend on no
/// other repository, so they keep their own state. Clears are stamped from the clock.
/// Every override write records what it changed through [recorder].
base class InMemoryRecurringStreamRepository
    implements RecurringStreamRepository {
  /// A repository holding [initial] streams, stamping clears from [_clock] and recording
  /// through [recorder].
  InMemoryRecurringStreamRepository(
    this._clock, {
    required this.recorder,
    List<RecurringStream> initial = const [],
  }) {
    for (final RecurringStream stream in initial) {
      _streams[stream.id] = stream;
    }
  }

  /// Where the override writes are recorded.
  final ChangeRecorder recorder;

  final Clock _clock;
  final Map<String, RecurringStream> _streams = {};
  final Map<String, ({StreamOverride override, DateTime? deletedAt})>
  _overrides = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  StreamOverride? _live(String id) {
    final entry = _overrides[id];
    return entry == null || entry.deletedAt != null ? null : entry.override;
  }

  List<StreamView> _all() =>
      [
        for (final RecurringStream s in _streams.values)
          StreamView(s, _live(s.id)),
      ]..sort((a, b) {
        final int byMerchant = compareNoCase(
          a.stream.merchantName,
          b.stream.merchantName,
        );
        return byMerchant != 0
            ? byMerchant
            : compareBinary(a.stream.id, b.stream.id);
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
  Stream<List<StreamView>> watchAll() => _watch(_all, sameList);

  @override
  Stream<StreamView?> watchById(String id) => _watch(() {
    final RecurringStream? stream = _streams[id];
    return stream == null ? null : StreamView(stream, _live(id));
  }, (a, b) => a == b);

  @override
  Future<void> applyPlaid(List<RecurringStream> streams) async =>
      _replace(streams, serverStreamSources);

  @override
  Future<void> replaceDetected(List<RecurringStream> streams) async =>
      _replace(streams, const {RecurringSource.detected});

  void _replace(List<RecurringStream> streams, Set<RecurringSource> sources) {
    checkStreamBatch(streams, sources);
    _streams.removeWhere((_, s) => sources.contains(s.source));
    for (final RecurringStream s in streams) {
      _streams[s.id] = s;
    }
    _changes.add(null);
  }

  @override
  Future<void> setOverride(
    String streamId,
    StreamOverride Function(StreamOverride current) change,
  ) async {
    final stored = _overrides[streamId];
    final StreamOverride current = _live(streamId) ?? const StreamOverride();
    final StreamOverride next = change(current);
    if (next == current) return;
    _overrides[streamId] = (override: next, deletedAt: null);
    _changes.add(null);
    await recorder.record(
      EntityType.recurringStream,
      streamId,
      stored == null
          ? streamOverrideRecordJson(const StreamOverride())
          : streamOverrideRecordJson(
              stored.override,
              deletedAt: stored.deletedAt,
            ),
      streamOverrideRecordJson(next),
    );
  }

  @override
  Future<void> clearOverride(String streamId) async {
    final stored = _overrides[streamId];
    if (stored == null || stored.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    _overrides[streamId] = (override: stored.override, deletedAt: now);
    _changes.add(null);
    await recorder.record(
      EntityType.recurringStream,
      streamId,
      streamOverrideRecordJson(stored.override),
      streamOverrideRecordJson(stored.override, deletedAt: now),
    );
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}

/// The sources of the streams the server supplies: `plaid`, and `demo` from a fake.
const Set<RecurringSource> serverStreamSources = {
  RecurringSource.plaid,
  RecurringSource.demo,
};

/// Throws [ArgumentError] when a stream of [streams] is not of [sources] or two share
/// an id.
void checkStreamBatch(
  List<RecurringStream> streams,
  Set<RecurringSource> sources,
) {
  final Set<String> ids = {};
  for (final RecurringStream s in streams) {
    if (!sources.contains(s.source)) {
      throw ArgumentError.value(s.source, 'source', 'stream ${s.id}');
    }
    if (!ids.add(s.id)) {
      throw ArgumentError.value(s.id, 'id', 'two streams share it');
    }
  }
}
