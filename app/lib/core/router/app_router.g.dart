// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The router the app runs on, created once and disposed with the container, opening
/// at [LaunchLocation]'s location when the app was started at a launch link.

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

/// The router the app runs on, created once and disposed with the container, opening
/// at [LaunchLocation]'s location when the app was started at a launch link.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The router the app runs on, created once and disposed with the container, opening
  /// at [LaunchLocation]'s location when the app was started at a launch link.
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'8cb3ff531395480bb6ce95a451ac1d476d688738';

/// The location of the launch link the app was started at, or null; read once, when the
/// router is built.

@ProviderFor(LaunchLocation)
final launchLocationProvider = LaunchLocationProvider._();

/// The location of the launch link the app was started at, or null; read once, when the
/// router is built.
final class LaunchLocationProvider
    extends $NotifierProvider<LaunchLocation, String?> {
  /// The location of the launch link the app was started at, or null; read once, when the
  /// router is built.
  LaunchLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchLocationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchLocationHash();

  @$internal
  @override
  LaunchLocation create() => LaunchLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$launchLocationHash() => r'009a40454e4f8270c9745f38bcf8dce6fe29f377';

/// The location of the launch link the app was started at, or null; read once, when the
/// router is built.

abstract class _$LaunchLocation extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
