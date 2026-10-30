// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_security_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The screen security.

@ProviderFor(screenSecurity)
final screenSecurityProvider = ScreenSecurityProvider._();

/// The screen security.

final class ScreenSecurityProvider
    extends $FunctionalProvider<ScreenSecurity, ScreenSecurity, ScreenSecurity>
    with $Provider<ScreenSecurity> {
  /// The screen security.
  ScreenSecurityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'screenSecurityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$screenSecurityHash();

  @$internal
  @override
  $ProviderElement<ScreenSecurity> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScreenSecurity create(Ref ref) {
    return screenSecurity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScreenSecurity value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScreenSecurity>(value),
    );
  }
}

String _$screenSecurityHash() => r'935cbfd904b5ca122b53bb3e0cdfb6a69a2173dd';
