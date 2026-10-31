// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_sync_watcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps the schedule and the screens in step with the background sync.

@ProviderFor(BackgroundSyncWatcher)
final backgroundSyncWatcherProvider = BackgroundSyncWatcherProvider._();

/// Keeps the schedule and the screens in step with the background sync.
final class BackgroundSyncWatcherProvider
    extends $NotifierProvider<BackgroundSyncWatcher, void> {
  /// Keeps the schedule and the screens in step with the background sync.
  BackgroundSyncWatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundSyncWatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundSyncWatcherHash();

  @$internal
  @override
  BackgroundSyncWatcher create() => BackgroundSyncWatcher();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$backgroundSyncWatcherHash() =>
    r'364b78b39aa6d66a9108c42a6e5b2ffe8e3bca83';

/// Keeps the schedule and the screens in step with the background sync.

abstract class _$BackgroundSyncWatcher extends $Notifier<void> {
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
