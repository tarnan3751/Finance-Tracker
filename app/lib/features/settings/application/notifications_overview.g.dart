// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_overview.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The state, read when the screen asks.

@ProviderFor(notificationsOverview)
final notificationsOverviewProvider = NotificationsOverviewProvider._();

/// The state, read when the screen asks.

final class NotificationsOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationsOverview>,
          NotificationsOverview,
          FutureOr<NotificationsOverview>
        >
    with
        $FutureModifier<NotificationsOverview>,
        $FutureProvider<NotificationsOverview> {
  /// The state, read when the screen asks.
  NotificationsOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsOverviewHash();

  @$internal
  @override
  $FutureProviderElement<NotificationsOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationsOverview> create(Ref ref) {
    return notificationsOverview(ref);
  }
}

String _$notificationsOverviewHash() =>
    r'a3f412af50bc33ae88afbe15e50017f9ae332877';
