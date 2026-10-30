/// Which [DeviceAuth] checks the user for the app lock: the fake by default (the tests),
/// `local_auth` in every flavor (`overridesFor`); and whether this device can check at
/// all, asked afresh whenever the Security section asks.
library;

import 'package:finance_tracker/features/lock/data/fake_device_auth.dart';
import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_auth_provider.g.dart';

/// The device's check.
@Riverpod(keepAlive: true)
DeviceAuth deviceAuth(Ref ref) => FakeDeviceAuth();

/// Whether this device has biometrics or a screen lock to check with.
@riverpod
Future<bool> deviceAuthSupported(Ref ref) =>
    ref.watch(deviceAuthProvider).isSupported();
