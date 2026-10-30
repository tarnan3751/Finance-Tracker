/// The [ScreenSecurity] of every flavor on a device: `MainActivity`'s
/// `dev.tarnan.financetracker/screen_security` channel, whose `setSecure` adds or clears
/// `FLAG_SECURE` on the activity's window.
library;

import 'package:finance_tracker/core/platform/screen_security.dart';
import 'package:flutter/services.dart';

/// The window's secure flag through the app's own channel.
final class ChannelScreenSecurity implements ScreenSecurity {
  /// The flag through [channel] (the app's screen-security channel by default).
  const ChannelScreenSecurity([
    this._channel = const MethodChannel(
      'dev.tarnan.financetracker/screen_security',
    ),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> set(bool secure) =>
      _channel.invokeMethod<void>('setSecure', secure);
}
