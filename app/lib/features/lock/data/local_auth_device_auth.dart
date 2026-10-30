/// The [DeviceAuth] of every flavor on a device: `local_auth` 3, with the device-credential
/// fallback allowed (`biometricOnly: false`) so a device with only a PIN can lock the app,
/// and the prompt kept across a trip to the background (`persistAcrossBackgrounding`). Its
/// `LocalAuthException` codes become [AuthOutcome]s, which the lock screen words in the
/// app's own language; only the code is logged.
library;

import 'package:finance_tracker/features/lock/domain/device_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('lock');

/// The device's check through `local_auth`.
final class LocalAuthDeviceAuth implements DeviceAuth {
  /// A check through [plugin] (a new `LocalAuthentication` by default).
  LocalAuthDeviceAuth([LocalAuthentication? plugin])
    : _plugin = plugin ?? LocalAuthentication();

  final LocalAuthentication _plugin;

  @override
  Future<bool> isSupported() async {
    try {
      return await _plugin.isDeviceSupported();
    } on Object catch (e) {
      _log.warning('the device check failed: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Future<AuthOutcome> authenticate(String reason) async {
    try {
      final bool passed = await _plugin.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return passed ? AuthOutcome.success : AuthOutcome.failed;
    } on LocalAuthException catch (e) {
      _log.info('the unlock prompt ended: ${e.code.name}');
      return outcomeOf(e.code);
    } on Object catch (e) {
      _log.warning('the unlock prompt failed: ${e.runtimeType}');
      return AuthOutcome.unavailable;
    }
  }
}

/// The [AuthOutcome] that `local_auth`'s [code] means. The plugin may add codes; an
/// unknown one is [AuthOutcome.unavailable].
AuthOutcome outcomeOf(LocalAuthExceptionCode code) => switch (code) {
  LocalAuthExceptionCode.userCanceled ||
  LocalAuthExceptionCode.systemCanceled ||
  LocalAuthExceptionCode.timeout ||
  LocalAuthExceptionCode.userRequestedFallback => AuthOutcome.cancelled,
  LocalAuthExceptionCode.noCredentialsSet ||
  LocalAuthExceptionCode.noBiometricsEnrolled ||
  LocalAuthExceptionCode.noBiometricHardware => AuthOutcome.noCredentials,
  LocalAuthExceptionCode.temporaryLockout ||
  LocalAuthExceptionCode.biometricLockout => AuthOutcome.lockedOut,
  _ => AuthOutcome.unavailable,
};
