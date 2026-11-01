// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merged_streams.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

String _$mergedStreamsHash() => r'e168907cc5dcf113da36ea8c131afc62283cca6a';
