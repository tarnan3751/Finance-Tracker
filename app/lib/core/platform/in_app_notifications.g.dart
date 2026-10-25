// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_app_notifications.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The in-app list, newest first, at most [inAppNotificationLimit] long.

@ProviderFor(InAppNotifications)
final inAppNotificationsProvider = InAppNotificationsProvider._();

/// The in-app list, newest first, at most [inAppNotificationLimit] long.
final class InAppNotificationsProvider
    extends $NotifierProvider<InAppNotifications, List<InAppNotification>> {
  /// The in-app list, newest first, at most [inAppNotificationLimit] long.
  InAppNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inAppNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inAppNotificationsHash();

  @$internal
  @override
  InAppNotifications create() => InAppNotifications();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InAppNotification> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InAppNotification>>(value),
    );
  }
}

String _$inAppNotificationsHash() =>
    r'58feed949d7c06dfcf2d8308d440b61a7fd0aa18';

/// The in-app list, newest first, at most [inAppNotificationLimit] long.

abstract class _$InAppNotifications extends $Notifier<List<InAppNotification>> {
  List<InAppNotification> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<InAppNotification>, List<InAppNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<InAppNotification>, List<InAppNotification>>,
              List<InAppNotification>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Where the app's notifications go: the in-app list, in every flavor. Named explicitly:
/// the generator would drop the `Notifier` suffix, and a bare `notifier` would generate a
/// class clashing with Riverpod's own `NotifierProvider`.

@ProviderFor(appNotifier)
final appNotifierProvider = AppNotifierProvider._();

/// Where the app's notifications go: the in-app list, in every flavor. Named explicitly:
/// the generator would drop the `Notifier` suffix, and a bare `notifier` would generate a
/// class clashing with Riverpod's own `NotifierProvider`.

final class AppNotifierProvider
    extends $FunctionalProvider<Notifier, Notifier, Notifier>
    with $Provider<Notifier> {
  /// Where the app's notifications go: the in-app list, in every flavor. Named explicitly:
  /// the generator would drop the `Notifier` suffix, and a bare `notifier` would generate a
  /// class clashing with Riverpod's own `NotifierProvider`.
  AppNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appNotifierHash();

  @$internal
  @override
  $ProviderElement<Notifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Notifier create(Ref ref) {
    return appNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Notifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Notifier>(value),
    );
  }
}

String _$appNotifierHash() => r'3b44578553c2ae2566cc8ae226ce71c03417f6ee';
