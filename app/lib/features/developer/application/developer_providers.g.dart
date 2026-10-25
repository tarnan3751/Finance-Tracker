// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'developer_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The stored Items the Sandbox controls can act on: every one not `removed`, as
/// `ItemRepository.watchAll` orders them.

@ProviderFor(developerItems)
final developerItemsProvider = DeveloperItemsProvider._();

/// The stored Items the Sandbox controls can act on: every one not `removed`, as
/// `ItemRepository.watchAll` orders them.

final class DeveloperItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LinkedBank>>,
          List<LinkedBank>,
          Stream<List<LinkedBank>>
        >
    with $FutureModifier<List<LinkedBank>>, $StreamProvider<List<LinkedBank>> {
  /// The stored Items the Sandbox controls can act on: every one not `removed`, as
  /// `ItemRepository.watchAll` orders them.
  DeveloperItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'developerItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$developerItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<LinkedBank>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LinkedBank>> create(Ref ref) {
    return developerItems(ref);
  }
}

String _$developerItemsHash() => r'7bfb57b31b2b77e78941b9eadcd31d21b905a86c';

/// Item [itemId]'s live accounts on the device.

@ProviderFor(developerItemAccounts)
final developerItemAccountsProvider = DeveloperItemAccountsFamily._();

/// Item [itemId]'s live accounts on the device.

final class DeveloperItemAccountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Account>>,
          List<Account>,
          Stream<List<Account>>
        >
    with $FutureModifier<List<Account>>, $StreamProvider<List<Account>> {
  /// Item [itemId]'s live accounts on the device.
  DeveloperItemAccountsProvider._({
    required DeveloperItemAccountsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'developerItemAccountsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$developerItemAccountsHash();

  @override
  String toString() {
    return r'developerItemAccountsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Account>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Account>> create(Ref ref) {
    final argument = this.argument as String;
    return developerItemAccounts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DeveloperItemAccountsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$developerItemAccountsHash() =>
    r'69c7987247fcc040196b76a9b972f452f42aaa8b';

/// Item [itemId]'s live accounts on the device.

final class DeveloperItemAccountsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Account>>, String> {
  DeveloperItemAccountsFamily._()
    : super(
        retry: null,
        name: r'developerItemAccountsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Item [itemId]'s live accounts on the device.

  DeveloperItemAccountsProvider call(String itemId) =>
      DeveloperItemAccountsProvider._(argument: itemId, from: this);

  @override
  String toString() => r'developerItemAccountsProvider';
}
