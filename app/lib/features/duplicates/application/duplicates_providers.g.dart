// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duplicates_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The transactions the detector looks at: every live one.

@ProviderFor(duplicateSource)
final duplicateSourceProvider = DuplicateSourceProvider._();

/// The transactions the detector looks at: every live one.

final class DuplicateSourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  /// The transactions the detector looks at: every live one.
  DuplicateSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'duplicateSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$duplicateSourceHash();

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    return duplicateSource(ref);
  }
}

String _$duplicateSourceHash() => r'5d2da665efa7ef80996138b7250f339a6201c978';

/// The pairs the user dismissed.

@ProviderFor(dismissedPairs)
final dismissedPairsProvider = DismissedPairsProvider._();

/// The pairs the user dismissed.

final class DismissedPairsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<PairKey>>,
          Set<PairKey>,
          Stream<Set<PairKey>>
        >
    with $FutureModifier<Set<PairKey>>, $StreamProvider<Set<PairKey>> {
  /// The pairs the user dismissed.
  DismissedPairsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dismissedPairsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dismissedPairsHash();

  @$internal
  @override
  $StreamProviderElement<Set<PairKey>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<PairKey>> create(Ref ref) {
    return dismissedPairs(ref);
  }
}

String _$dismissedPairsHash() => r'fc4e0ff48b7b0f8327f270e7fe98d38013c945ef';

/// The likely duplicate pairs, ranked (`findDuplicates`), recomputed when the
/// transactions or the dismissed pairs change.

@ProviderFor(duplicateCandidates)
final duplicateCandidatesProvider = DuplicateCandidatesProvider._();

/// The likely duplicate pairs, ranked (`findDuplicates`), recomputed when the
/// transactions or the dismissed pairs change.

final class DuplicateCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DuplicateCandidate>>,
          List<DuplicateCandidate>,
          FutureOr<List<DuplicateCandidate>>
        >
    with
        $FutureModifier<List<DuplicateCandidate>>,
        $FutureProvider<List<DuplicateCandidate>> {
  /// The likely duplicate pairs, ranked (`findDuplicates`), recomputed when the
  /// transactions or the dismissed pairs change.
  DuplicateCandidatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'duplicateCandidatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$duplicateCandidatesHash();

  @$internal
  @override
  $FutureProviderElement<List<DuplicateCandidate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DuplicateCandidate>> create(Ref ref) {
    return duplicateCandidates(ref);
  }
}

String _$duplicateCandidatesHash() =>
    r'323d610cb0e67ddae9054473778507d331c72cf6';

/// The writes of the duplicate review.

@ProviderFor(duplicateActions)
final duplicateActionsProvider = DuplicateActionsProvider._();

/// The writes of the duplicate review.

final class DuplicateActionsProvider
    extends
        $FunctionalProvider<
          DuplicateActions,
          DuplicateActions,
          DuplicateActions
        >
    with $Provider<DuplicateActions> {
  /// The writes of the duplicate review.
  DuplicateActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'duplicateActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$duplicateActionsHash();

  @$internal
  @override
  $ProviderElement<DuplicateActions> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DuplicateActions create(Ref ref) {
    return duplicateActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DuplicateActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DuplicateActions>(value),
    );
  }
}

String _$duplicateActionsHash() => r'1c975163ffc8884bce4ce6055dd2c7006c496157';
