// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merged_streams.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every live transaction, which the detector and the classifier read.

@ProviderFor(recurringLedger)
final recurringLedgerProvider = RecurringLedgerProvider._();

/// Every live transaction, which the detector and the classifier read.

final class RecurringLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          Stream<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $StreamProvider<List<Transaction>> {
  /// Every live transaction, which the detector and the classifier read.
  RecurringLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringLedgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringLedgerHash();

  @$internal
  @override
  $StreamProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Transaction>> create(Ref ref) {
    return recurringLedger(ref);
  }
}

String _$recurringLedgerHash() => r'f975f75b01f0e531a99bfefd8c1ce2bf69a88ec6';

/// The stored streams merged and classified ([mergedViews]), in the repository's order
/// (merchant name ignoring ASCII case, then id); muted ones included.

@ProviderFor(mergedStreams)
final mergedStreamsProvider = MergedStreamsProvider._();

/// The stored streams merged and classified ([mergedViews]), in the repository's order
/// (merchant name ignoring ASCII case, then id); muted ones included.

final class MergedStreamsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StreamView>>,
          List<StreamView>,
          Stream<List<StreamView>>
        >
    with $FutureModifier<List<StreamView>>, $StreamProvider<List<StreamView>> {
  /// The stored streams merged and classified ([mergedViews]), in the repository's order
  /// (merchant name ignoring ASCII case, then id); muted ones included.
  MergedStreamsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mergedStreamsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mergedStreamsHash();

  @$internal
  @override
  $StreamProviderElement<List<StreamView>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StreamView>> create(Ref ref) {
    return mergedStreams(ref);
  }
}

String _$mergedStreamsHash() => r'5e05bc530e0f51748dc8703abbbf9643b2117b93';
