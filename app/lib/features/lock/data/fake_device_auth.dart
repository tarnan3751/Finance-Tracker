/// The [DeviceAuth] of the tests and the lock's integration run: no prompt; each check
/// completes with what the test says, and the checks are counted.
library;

import 'package:finance_tracker/features/lock/domain/device_auth.dart';

/// The device's check without a device.
final class FakeDeviceAuth implements DeviceAuth {
  /// A check on a device that is [supported], whose every prompt completes with [next].
  FakeDeviceAuth({this.supported = true, Future<AuthOutcome> Function()? next})
    : next = next ?? (() async => AuthOutcome.success);

  /// Whether the device can check its user.
  bool supported;

  /// What the next prompt completes with.
  Future<AuthOutcome> Function() next;

  /// The reasons the prompts were shown with, in order.
  final List<String> prompts = [];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<AuthOutcome> authenticate(String reason) {
    prompts.add(reason);
    return next();
  }
}
