// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The stored Items, as `ItemRepository.watchAll` orders them; an Item unlinked with its
/// history kept (`removed`) only while one of its accounts is still live on the device.

@ProviderFor(linkedBanks)
final linkedBanksProvider = LinkedBanksProvider._();

/// The stored Items, as `ItemRepository.watchAll` orders them; an Item unlinked with its
/// history kept (`removed`) only while one of its accounts is still live on the device.

final class LinkedBanksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LinkedBank>>,
          List<LinkedBank>,
          Stream<List<LinkedBank>>
        >
    with $FutureModifier<List<LinkedBank>>, $StreamProvider<List<LinkedBank>> {
  /// The stored Items, as `ItemRepository.watchAll` orders them; an Item unlinked with its
  /// history kept (`removed`) only while one of its accounts is still live on the device.
  LinkedBanksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkedBanksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkedBanksHash();

  @$internal
  @override
  $StreamProviderElement<List<LinkedBank>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LinkedBank>> create(Ref ref) {
    return linkedBanks(ref);
  }
}

String _$linkedBanksHash() => r'57540bea7eb07366c9a7fb85640857494d2a79fe';

@ProviderFor(_liveAccounts)
final _liveAccountsProvider = _LiveAccountsProvider._();

final class _LiveAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Account>>,
          List<Account>,
          Stream<List<Account>>
        >
    with $FutureModifier<List<Account>>, $StreamProvider<List<Account>> {
  _LiveAccountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_liveAccountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_liveAccountsHash();

  @$internal
  @override
  $StreamProviderElement<List<Account>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Account>> create(Ref ref) {
    return _liveAccounts(ref);
  }
}

String _$_liveAccountsHash() => r'78030ac097b745f93841543aa084195349873429';
