/// The [MonotonicClock] of every flavor on a device: `MainActivity`'s
/// `dev.tarnan.financetracker/clock` channel, whose `elapsedRealtime` answers
/// `SystemClock.elapsedRealtime()`, milliseconds since boot, deep sleep included.
library;

import 'package:finance_tracker/core/platform/monotonic_clock.dart';
import 'package:flutter/services.dart';

/// Elapsed time through the app's own channel.
final class ChannelMonotonicClock implements MonotonicClock {
  /// The clock through [channel] (the app's clock channel by default).
  const ChannelMonotonicClock([
    this._channel = const MethodChannel('dev.tarnan.financetracker/clock'),
  ]);

  final MethodChannel _channel;

  @override
  Future<Duration> elapsed() async {
    final int? millis = await _channel.invokeMethod<int>('elapsedRealtime');
    return Duration(milliseconds: millis!);
  }
}
