// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detector_runner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How long after the last change the detector runs.

@ProviderFor(detectorDebounce)
final detectorDebounceProvider = DetectorDebounceProvider._();

/// How long after the last change the detector runs.

final class DetectorDebounceProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How long after the last change the detector runs.
  DetectorDebounceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectorDebounceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectorDebounceHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return detectorDebounce(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$detectorDebounceHash() => r'b68df20e5271e3614e3d0c2487ce98e463610740';

/// The ledger size above which the detector runs on a background isolate.

@ProviderFor(detectorIsolateThreshold)
final detectorIsolateThresholdProvider = DetectorIsolateThresholdProvider._();

/// The ledger size above which the detector runs on a background isolate.

final class DetectorIsolateThresholdProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The ledger size above which the detector runs on a background isolate.
  DetectorIsolateThresholdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectorIsolateThresholdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectorIsolateThresholdHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return detectorIsolateThreshold(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$detectorIsolateThresholdHash() =>
    r'6c282657a1bd9422ea17c5a2153e3194ce1cb3cf';

/// Runs the detector [detectorDebounce] after its input last changed, while something
/// listens.

@ProviderFor(DetectorRunner)
final detectorRunnerProvider = DetectorRunnerProvider._();

/// Runs the detector [detectorDebounce] after its input last changed, while something
/// listens.
final class DetectorRunnerProvider
    extends $NotifierProvider<DetectorRunner, void> {
  /// Runs the detector [detectorDebounce] after its input last changed, while something
  /// listens.
  DetectorRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectorRunnerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectorRunnerHash();

  @$internal
  @override
  DetectorRunner create() => DetectorRunner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$detectorRunnerHash() => r'3dd511652604e294c831ad569be0db82e7bad347';

/// Runs the detector [detectorDebounce] after its input last changed, while something
/// listens.

abstract class _$DetectorRunner extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
