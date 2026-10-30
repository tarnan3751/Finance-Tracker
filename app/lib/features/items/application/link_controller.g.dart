// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The wait between two sync requests.

@ProviderFor(linkPollInterval)
final linkPollIntervalProvider = LinkPollIntervalProvider._();

/// The wait between two sync requests.

final class LinkPollIntervalProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// The wait between two sync requests.
  LinkPollIntervalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkPollIntervalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkPollIntervalHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return linkPollInterval(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$linkPollIntervalHash() => r'58b62ec647102f288214fb4268afb67a87673c09';

/// The state of every action on linked banks, and the actions.

@ProviderFor(LinkController)
final linkControllerProvider = LinkControllerProvider._();

/// The state of every action on linked banks, and the actions.
final class LinkControllerProvider
    extends $NotifierProvider<LinkController, LinkState> {
  /// The state of every action on linked banks, and the actions.
  LinkControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linkControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linkControllerHash();

  @$internal
  @override
  LinkController create() => LinkController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinkState>(value),
    );
  }
}

String _$linkControllerHash() => r'26dae881b4c0b18b4ff074b67e3d5b1a55967703';

/// The state of every action on linked banks, and the actions.

abstract class _$LinkController extends $Notifier<LinkState> {
  LinkState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LinkState, LinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LinkState, LinkState>,
              LinkState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
