// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liabilities_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every liability of the user's linked accounts, by account, then kind.

@ProviderFor(liabilities)
final liabilitiesProvider = LiabilitiesProvider._();

/// Every liability of the user's linked accounts, by account, then kind.

final class LiabilitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Liability>>,
          List<Liability>,
          Stream<List<Liability>>
        >
    with $FutureModifier<List<Liability>>, $StreamProvider<List<Liability>> {
  /// Every liability of the user's linked accounts, by account, then kind.
  LiabilitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liabilitiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liabilitiesHash();

  @$internal
  @override
  $StreamProviderElement<List<Liability>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Liability>> create(Ref ref) {
    return liabilities(ref);
  }
}

String _$liabilitiesHash() => r'5e5034bfed25fcf618b5c36c53e42cf9909bc9bf';
