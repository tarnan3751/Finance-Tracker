// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_check.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The server check for the running configuration.

@ProviderFor(serverCheck)
final serverCheckProvider = ServerCheckProvider._();

/// The server check for the running configuration.

final class ServerCheckProvider
    extends $FunctionalProvider<ServerCheck, ServerCheck, ServerCheck>
    with $Provider<ServerCheck> {
  /// The server check for the running configuration.
  ServerCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverCheckHash();

  @$internal
  @override
  $ProviderElement<ServerCheck> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServerCheck create(Ref ref) {
    return serverCheck(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerCheck value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerCheck>(value),
    );
  }
}

String _$serverCheckHash() => r'a7048ab12170af9ae036ef5f89c17eed85fdbd1f';
