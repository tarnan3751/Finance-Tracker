// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_hold.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's one suppression count.

@ProviderFor(lockHold)
final lockHoldProvider = LockHoldProvider._();

/// The app's one suppression count.

final class LockHoldProvider
    extends $FunctionalProvider<LockHold, LockHold, LockHold>
    with $Provider<LockHold> {
  /// The app's one suppression count.
  LockHoldProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockHoldProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockHoldHash();

  @$internal
  @override
  $ProviderElement<LockHold> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LockHold create(Ref ref) {
    return lockHold(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockHold value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockHold>(value),
    );
  }
}

String _$lockHoldHash() => r'71e4888ca1abd41dbe6efbfe5bf4d5969376b7af';
