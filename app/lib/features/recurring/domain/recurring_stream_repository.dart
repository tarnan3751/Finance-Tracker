/// The recurring streams and the user's overrides of them
/// (`docs/reference/recurring.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// the persona's streams); all pass
/// `test/contract/recurring_stream_repository_contract.dart`.
library;

import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:shared_models/shared_models.dart';

/// Reads the streams with their overrides, replaces the streams, and writes the
/// overrides. Every stream starts with the current value and emits again only when that
/// value changes. The streams are never recorded for sync (the server's are
/// server-authoritative, the detector's recomputed on each device); the overrides are
/// user data, recorded as updates only (`sync-app.md`, **Recording**), so the first
/// choices two devices make about one stream merge field by field.
abstract interface class RecurringStreamRepository {
  /// Every stored stream with its live override, by merchant name ignoring ASCII case,
  /// then by id.
  Stream<List<StreamView>> watchAll();

  /// Stream [id] with its live override, or null when there is no such stream.
  Stream<StreamView?> watchById(String id);

  /// Replaces every stream the server supplied (`plaid` and `demo`) with [streams], the
  /// server's whole list, in one write; the detector's are left alone, and so are the
  /// overrides. Records nothing. A stream of another source, or two with one id, is an
  /// [ArgumentError] before anything is written.
  Future<void> applyPlaid(List<RecurringStream> streams);

  /// Replaces every `detected` stream with [streams] in one write, the others left
  /// alone. Records nothing. A stream of another source, or two with one id, is an
  /// [ArgumentError] before anything is written.
  Future<void> replaceDetected(List<RecurringStream> streams);

  /// Writes the override of stream [streamId] that [change] makes of the current one
  /// (the stored live override, else the default), read and written in one write, and
  /// records only the fields that changed. A cleared override is restored from the
  /// default with the change applied. Nothing happens when the result equals the
  /// current one, so a change that keeps the default leaves a cleared override cleared.
  Future<void> setOverride(
    String streamId,
    StreamOverride Function(StreamOverride current) change,
  );

  /// Clears the override of stream [streamId] (a tombstone, recorded as a delete, so it
  /// wins over another device's concurrent edit); does nothing when there is no live
  /// one.
  Future<void> clearOverride(String streamId);
}
