/// What the recurring screens read, and the user's actions on a stream
/// (`docs/reference/recurring.md`); the repository is `recurringStreamRepositoryProvider`
/// (`core/di/providers.dart`).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/stream_view.dart';
import 'package:finance_tracker/features/recurring/domain/subscriptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recurring_providers.g.dart';

/// Every stored stream with the user's override resolved, by merchant name ignoring
/// ASCII case, then id; muted ones are included, for the screen that unmutes them. The
/// screens read `mergedStreamsProvider` (`merged_streams.dart`): these streams merged
/// with the detector's and classified.
@riverpod
Stream<List<StreamView>> recurringStreams(Ref ref) =>
    ref.watch(recurringStreamRepositoryProvider).watchAll();

/// The active, unmuted streams counted as subscriptions, with each one's annual cost,
/// in [recurringStreams]' order: of the merged and classified streams.
@riverpod
Stream<List<Subscription>> subscriptions(Ref ref) async* {
  yield subscriptionsOf(await ref.watch(mergedStreamsProvider.future));
}

/// The user's actions on a stream.
@riverpod
StreamActions streamActions(Ref ref) =>
    StreamActions(ref.watch(recurringStreamRepositoryProvider));

/// Mutes, classifies, renames and resets streams; each writes only the field it changes,
/// read and written in one write, so another device's change to another field stands.
final class StreamActions {
  StreamActions(this._streams);

  final RecurringStreamRepository _streams;

  /// Mutes stream [id], or unmutes it.
  Future<void> mute(String id, {required bool muted}) =>
      _streams.setOverride(id, (o) => o.withMuted(muted));

  /// Says whether stream [id] is a subscription; null lets the app's classification
  /// stand.
  Future<void> setSubscription(String id, bool? isSubscription) =>
      _streams.setOverride(id, (o) => o.withSubscription(isSubscription));

  /// Names stream [id]; a blank or null name restores the merchant's.
  Future<void> rename(String id, String? name) {
    final String? trimmed = name?.trim();
    return _streams.setOverride(
      id,
      (o) => o.withDisplayName(
        trimmed == null || trimmed.isEmpty ? null : trimmed,
      ),
    );
  }

  /// Clears every choice about stream [id].
  Future<void> reset(String id) => _streams.clearOverride(id);
}
