// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every stored stream with the user's override resolved, by merchant name ignoring
/// ASCII case, then id. Phase 5's detector merges its own streams in later; muted ones
/// are included, for the screen that unmutes them.

@ProviderFor(recurringStreams)
final recurringStreamsProvider = RecurringStreamsProvider._();

/// Every stored stream with the user's override resolved, by merchant name ignoring
/// ASCII case, then id. Phase 5's detector merges its own streams in later; muted ones
/// are included, for the screen that unmutes them.

final class RecurringStreamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StreamView>>,
          List<StreamView>,
          Stream<List<StreamView>>
        >
    with $FutureModifier<List<StreamView>>, $StreamProvider<List<StreamView>> {
  /// Every stored stream with the user's override resolved, by merchant name ignoring
  /// ASCII case, then id. Phase 5's detector merges its own streams in later; muted ones
  /// are included, for the screen that unmutes them.
  RecurringStreamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringStreamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringStreamsHash();

  @$internal
  @override
  $StreamProviderElement<List<StreamView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StreamView>> create(Ref ref) {
    return recurringStreams(ref);
  }
}

String _$recurringStreamsHash() => r'b78e5979c906f9c564da194815b91234a940466b';

/// The active, unmuted streams counted as subscriptions, with each one's annual cost,
/// in [recurringStreams]' order.

@ProviderFor(subscriptions)
final subscriptionsProvider = SubscriptionsProvider._();

/// The active, unmuted streams counted as subscriptions, with each one's annual cost,
/// in [recurringStreams]' order.

final class SubscriptionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subscription>>,
          List<Subscription>,
          Stream<List<Subscription>>
        >
    with
        $FutureModifier<List<Subscription>>,
        $StreamProvider<List<Subscription>> {
  /// The active, unmuted streams counted as subscriptions, with each one's annual cost,
  /// in [recurringStreams]' order.
  SubscriptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subscription>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subscription>> create(Ref ref) {
    return subscriptions(ref);
  }
}

String _$subscriptionsHash() => r'd83852204301ceaa208d68e1b63f563466b045e8';

/// The user's actions on a stream.

@ProviderFor(streamActions)
final streamActionsProvider = StreamActionsProvider._();

/// The user's actions on a stream.

final class StreamActionsProvider
    extends $FunctionalProvider<StreamActions, StreamActions, StreamActions>
    with $Provider<StreamActions> {
  /// The user's actions on a stream.
  StreamActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streamActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streamActionsHash();

  @$internal
  @override
  $ProviderElement<StreamActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StreamActions create(Ref ref) {
    return streamActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StreamActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StreamActions>(value),
    );
  }
}

String _$streamActionsHash() => r'6745e7d747e518c093eecb7a4ac8fde557d7eaaf';
