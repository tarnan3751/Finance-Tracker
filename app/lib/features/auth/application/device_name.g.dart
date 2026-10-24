// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_name.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The device's name, at most 100 characters (the contract's limit).

@ProviderFor(deviceName)
final deviceNameProvider = DeviceNameProvider._();

/// The device's name, at most 100 characters (the contract's limit).

final class DeviceNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The device's name, at most 100 characters (the contract's limit).
  DeviceNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceNameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceNameHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return deviceName(ref);
  }
}

String _$deviceNameHash() => r'57ad5083e152539c7127c70ec2def5b8465eded8';
