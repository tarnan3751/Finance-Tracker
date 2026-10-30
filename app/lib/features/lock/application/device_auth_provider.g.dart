// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The device's check.

@ProviderFor(deviceAuth)
final deviceAuthProvider = DeviceAuthProvider._();

/// The device's check.

final class DeviceAuthProvider
    extends $FunctionalProvider<DeviceAuth, DeviceAuth, DeviceAuth>
    with $Provider<DeviceAuth> {
  /// The device's check.
  DeviceAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceAuthHash();

  @$internal
  @override
  $ProviderElement<DeviceAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceAuth create(Ref ref) {
    return deviceAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceAuth>(value),
    );
  }
}

String _$deviceAuthHash() => r'c22e5476dbc8f4412fba970cdea63497619a1223';

/// Whether this device has biometrics or a screen lock to check with.

@ProviderFor(deviceAuthSupported)
final deviceAuthSupportedProvider = DeviceAuthSupportedProvider._();

/// Whether this device has biometrics or a screen lock to check with.

final class DeviceAuthSupportedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether this device has biometrics or a screen lock to check with.
  DeviceAuthSupportedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceAuthSupportedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceAuthSupportedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return deviceAuthSupported(ref);
  }
}

String _$deviceAuthSupportedHash() =>
    r'ad403c636263d3e1fcd624571fd39f63a4b40b57';
