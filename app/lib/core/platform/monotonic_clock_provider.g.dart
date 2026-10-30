// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monotonic_clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The monotonic clock.

@ProviderFor(monotonicClock)
final monotonicClockProvider = MonotonicClockProvider._();

/// The monotonic clock.

final class MonotonicClockProvider
    extends $FunctionalProvider<MonotonicClock, MonotonicClock, MonotonicClock>
    with $Provider<MonotonicClock> {
  /// The monotonic clock.
  MonotonicClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monotonicClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monotonicClockHash();

  @$internal
  @override
  $ProviderElement<MonotonicClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MonotonicClock create(Ref ref) {
    return monotonicClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MonotonicClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MonotonicClock>(value),
    );
  }
}

String _$monotonicClockHash() => r'9861a451bd2d4fa264a06e32d73647e4375f331d';
