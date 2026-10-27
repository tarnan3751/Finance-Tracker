/// The user's choices about one recurring stream (`docs/reference/recurring.md`): kept
/// in `stream_overrides` by stream id and synced as the `recurring_stream` record
/// (`PLAN.md` §12, "Recurring streams"). Pure Dart, no Flutter import.
library;

/// What the user chose for a stream: [muted] hides it; [isSubscription] and
/// [displayName], when not null, replace the stream's own classification and merchant
/// name. The default (nothing chosen) is unmuted with both null.
final class StreamOverride {
  /// An override.
  const StreamOverride({
    this.muted = false,
    this.isSubscription,
    this.displayName,
  });

  /// Whether the stream is hidden from the recurring lists.
  final bool muted;

  /// The user's answer to "is this a subscription", or null for the app's.
  final bool? isSubscription;

  /// The user's name for the stream, or null for its merchant's.
  final String? displayName;

  /// A copy muted or not.
  StreamOverride withMuted(bool muted) => StreamOverride(
    muted: muted,
    isSubscription: isSubscription,
    displayName: displayName,
  );

  /// A copy with [isSubscription] (null: the app's classification stands).
  StreamOverride withSubscription(bool? isSubscription) => StreamOverride(
    muted: muted,
    isSubscription: isSubscription,
    displayName: displayName,
  );

  /// A copy named [displayName] (null: the merchant's name stands).
  StreamOverride withDisplayName(String? displayName) => StreamOverride(
    muted: muted,
    isSubscription: isSubscription,
    displayName: displayName,
  );

  @override
  bool operator ==(Object other) =>
      other is StreamOverride &&
      other.muted == muted &&
      other.isSubscription == isSubscription &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(muted, isSubscription, displayName);

  @override
  String toString() =>
      'StreamOverride(muted: $muted, isSubscription: $isSubscription, '
      'named: ${displayName != null})';
}
