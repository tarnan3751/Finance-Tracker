/// A recurring stream as the screens see it: the stored stream with the user's override
/// resolved (`docs/reference/recurring.md`). Pure Dart, no Flutter import.
library;

import 'package:finance_tracker/features/recurring/domain/stream_override.dart';
import 'package:shared_models/shared_models.dart';

/// [stream] and the user's live [userOverride] of it (null when there is none, or it was
/// cleared).
final class StreamView {
  /// A view.
  const StreamView(this.stream, [this.userOverride]);

  /// The stream as stored: the server's, or the detector's.
  final RecurringStream stream;

  /// What the user chose, or null.
  final StreamOverride? userOverride;

  /// Whether the user muted the stream.
  bool get muted => userOverride?.muted ?? false;

  /// The user's answer, else the stream's own classification.
  bool get isSubscription =>
      userOverride?.isSubscription ?? stream.isSubscription;

  /// The user's name for the stream, else its merchant's.
  String get displayName => userOverride?.displayName ?? stream.merchantName;

  @override
  bool operator ==(Object other) =>
      other is StreamView &&
      other.stream == stream &&
      other.userOverride == userOverride;

  @override
  int get hashCode => Object.hash(stream, userOverride);

  @override
  String toString() => 'StreamView(${stream.id}, $userOverride)';
}
