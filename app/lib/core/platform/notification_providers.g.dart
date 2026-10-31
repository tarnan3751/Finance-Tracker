// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The channels.

@ProviderFor(notificationChannels)
final notificationChannelsProvider = NotificationChannelsProvider._();

/// The channels.

final class NotificationChannelsProvider
    extends
        $FunctionalProvider<
          NotificationChannels,
          NotificationChannels,
          NotificationChannels
        >
    with $Provider<NotificationChannels> {
  /// The channels.
  NotificationChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationChannelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationChannelsHash();

  @$internal
  @override
  $ProviderElement<NotificationChannels> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationChannels create(Ref ref) {
    return notificationChannels(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationChannels value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationChannels>(value),
    );
  }
}

String _$notificationChannelsHash() =>
    r'd07a814a541eec5811e3b1ad5f151ca5829d40f1';

/// The system's settings screens and the background restriction.

@ProviderFor(systemSettings)
final systemSettingsProvider = SystemSettingsProvider._();

/// The system's settings screens and the background restriction.

final class SystemSettingsProvider
    extends $FunctionalProvider<SystemSettings, SystemSettings, SystemSettings>
    with $Provider<SystemSettings> {
  /// The system's settings screens and the background restriction.
  SystemSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemSettingsHash();

  @$internal
  @override
  $ProviderElement<SystemSettings> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SystemSettings create(Ref ref) {
    return systemSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemSettings>(value),
    );
  }
}

String _$systemSettingsHash() => r'abfcb362f545e9be702feedfea185a5b7f5c43dd';

/// The channels' names and descriptions in the device's locale, read at each start.

@ProviderFor(channelTexts)
final channelTextsProvider = ChannelTextsProvider._();

/// The channels' names and descriptions in the device's locale, read at each start.

final class ChannelTextsProvider
    extends
        $FunctionalProvider<
          Map<AppChannel, ChannelText>,
          Map<AppChannel, ChannelText>,
          Map<AppChannel, ChannelText>
        >
    with $Provider<Map<AppChannel, ChannelText>> {
  /// The channels' names and descriptions in the device's locale, read at each start.
  ChannelTextsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelTextsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelTextsHash();

  @$internal
  @override
  $ProviderElement<Map<AppChannel, ChannelText>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<AppChannel, ChannelText> create(Ref ref) {
    return channelTexts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<AppChannel, ChannelText> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<AppChannel, ChannelText>>(value),
    );
  }
}

String _$channelTextsHash() => r'e7699230cb6b3cfbb2370ecf8896cd2c3b107ab1';

/// What each kind says in the tray, in the device's locale, and the route its tap opens;
/// a bill due has no tray notice of its own (its reminder is one).

@ProviderFor(systemNoticeText)
final systemNoticeTextProvider = SystemNoticeTextProvider._();

/// What each kind says in the tray, in the device's locale, and the route its tap opens;
/// a bill due has no tray notice of its own (its reminder is one).

final class SystemNoticeTextProvider
    extends $FunctionalProvider<NoticeText, NoticeText, NoticeText>
    with $Provider<NoticeText> {
  /// What each kind says in the tray, in the device's locale, and the route its tap opens;
  /// a bill due has no tray notice of its own (its reminder is one).
  SystemNoticeTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemNoticeTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemNoticeTextHash();

  @$internal
  @override
  $ProviderElement<NoticeText> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoticeText create(Ref ref) {
    return systemNoticeText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoticeText value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoticeText>(value),
    );
  }
}

String _$systemNoticeTextHash() => r'dd7774766dedef20bbfecbcb056c3edadd72d21b';

/// The permission.

@ProviderFor(notificationPermission)
final notificationPermissionProvider = NotificationPermissionProvider._();

/// The permission.

final class NotificationPermissionProvider
    extends
        $FunctionalProvider<
          NotificationPermission,
          NotificationPermission,
          NotificationPermission
        >
    with $Provider<NotificationPermission> {
  /// The permission.
  NotificationPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionHash();

  @$internal
  @override
  $ProviderElement<NotificationPermission> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationPermission create(Ref ref) {
    return notificationPermission(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPermission>(value),
    );
  }
}

String _$notificationPermissionHash() =>
    r'13fd98abfbc37fb80fe9aab5d01996fdcc675804';
