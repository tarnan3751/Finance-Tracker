// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_user.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The id of the user this install's data belongs to, or null; read afresh by each
/// screen that watches it. A marker that cannot be read is an error.

@ProviderFor(installUser)
final installUserProvider = InstallUserProvider._();

/// The id of the user this install's data belongs to, or null; read afresh by each
/// screen that watches it. A marker that cannot be read is an error.

final class InstallUserProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// The id of the user this install's data belongs to, or null; read afresh by each
  /// screen that watches it. A marker that cannot be read is an error.
  InstallUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installUserHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return installUser(ref);
  }
}

String _$installUserHash() => r'299b18478613664f106abf37cb678db87e31695f';
