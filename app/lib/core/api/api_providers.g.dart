// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the session is kept: secure storage.

@ProviderFor(tokenStore)
final tokenStoreProvider = TokenStoreProvider._();

/// Where the session is kept: secure storage.

final class TokenStoreProvider
    extends $FunctionalProvider<TokenStore, TokenStore, TokenStore>
    with $Provider<TokenStore> {
  /// Where the session is kept: secure storage.
  TokenStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStoreHash();

  @$internal
  @override
  $ProviderElement<TokenStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStore create(Ref ref) {
    return tokenStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStore>(value),
    );
  }
}

String _$tokenStoreHash() => r'e1af499041ec8e3fd653ab4576cba8185f657d98';

/// The in-app fake server; only the flavors and tests that run on it supply one.

@ProviderFor(fakeServer)
final fakeServerProvider = FakeServerProvider._();

/// The in-app fake server; only the flavors and tests that run on it supply one.

final class FakeServerProvider
    extends $FunctionalProvider<FakeServer, FakeServer, FakeServer>
    with $Provider<FakeServer> {
  /// The in-app fake server; only the flavors and tests that run on it supply one.
  FakeServerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fakeServerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fakeServerHash();

  @$internal
  @override
  $ProviderElement<FakeServer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FakeServer create(Ref ref) {
    return fakeServer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FakeServer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FakeServer>(value),
    );
  }
}

String _$fakeServerHash() => r'0065010ad7f9cdc26bd5990ca1e358cee036a793';

/// The API, over the network.

@ProviderFor(financeApi)
final financeApiProvider = FinanceApiProvider._();

/// The API, over the network.

final class FinanceApiProvider
    extends $FunctionalProvider<FinanceApi, FinanceApi, FinanceApi>
    with $Provider<FinanceApi> {
  /// The API, over the network.
  FinanceApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'financeApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$financeApiHash();

  @$internal
  @override
  $ProviderElement<FinanceApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FinanceApi create(Ref ref) {
    return financeApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinanceApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinanceApi>(value),
    );
  }
}

String _$financeApiHash() => r'b906f4e9a51c1a9bfd648dcbeb6d88dee47db68d';
