/// The app's own channel to `MainActivity` for the system's settings screens and the
/// background restriction (`docs/reference/background.md`, **Settings**):
/// `dev.tarnan.financetracker/system_settings` with `openChannelSettings(channelId)`
/// (`android.settings.CHANNEL_NOTIFICATION_SETTINGS`), `openAppDetails()` (the app's
/// details, where its battery use is set) and `backgroundRestricted()` (whether Android
/// holds the app's background work back: restricted by the user, or in the restricted
/// standby bucket). [ChannelSystemSettings] is the channel in every flavor;
/// [FakeSystemSettings] stands in for the tests.
library;

import 'package:flutter/services.dart';

/// The system's settings and background state.
abstract interface class SystemSettings {
  /// Opens the system's settings of the notification channel [channelId].
  Future<void> openChannelSettings(String channelId);

  /// Opens the app's details in the system's settings.
  Future<void> openAppDetails();

  /// Whether Android restricts the app's background work.
  Future<bool> backgroundRestricted();
}

/// [SystemSettings] through `MainActivity`.
final class ChannelSystemSettings implements SystemSettings {
  const ChannelSystemSettings();

  static const MethodChannel _channel = MethodChannel(
    'dev.tarnan.financetracker/system_settings',
  );

  @override
  Future<void> openChannelSettings(String channelId) =>
      _channel.invokeMethod<void>('openChannelSettings', channelId);

  @override
  Future<void> openAppDetails() =>
      _channel.invokeMethod<void>('openAppDetails');

  @override
  Future<bool> backgroundRestricted() async =>
      await _channel.invokeMethod<bool>('backgroundRestricted') ?? false;
}

/// [SystemSettings] without a platform: restricted when told, every opening recorded.
final class FakeSystemSettings implements SystemSettings {
  /// Restricted when [restricted].
  FakeSystemSettings({this.restricted = false});

  /// Whether background work is restricted.
  bool restricted;

  /// The settings opened, in order: a channel's id, or `details`.
  final List<String> opened = [];

  @override
  Future<void> openChannelSettings(String channelId) async =>
      opened.add(channelId);

  @override
  Future<void> openAppDetails() async => opened.add('details');

  @override
  Future<bool> backgroundRestricted() async => restricted;
}
