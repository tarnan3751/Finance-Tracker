/// Whether this install is signed in, and as whom (`docs/reference/auth.md`).
library;

import 'package:shared_models/shared_models.dart';

/// The session as the app sees it.
sealed class SessionState {
  const SessionState();
}

/// Not known yet: the stored session is being read at startup.
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// Nobody is signed in.
final class SignedOut extends SessionState {
  const SignedOut();

  @override
  bool operator ==(Object other) => other is SignedOut;

  @override
  int get hashCode => 0;
}

/// [user] is signed in on [device], this installation.
final class SignedIn extends SessionState {
  const SignedIn(this.user, this.device);

  final User user;
  final Device device;

  @override
  bool operator ==(Object other) =>
      other is SignedIn && other.user == user && other.device == device;

  @override
  int get hashCode => Object.hash(user, device);
}

/// A sign-in or registration refused because this install's local data belongs to
/// another account (one user per install, `PLAN.md` §6.6).
final class OtherAccountOnDeviceException implements Exception {
  const OtherAccountOnDeviceException();

  @override
  String toString() => 'OtherAccountOnDeviceException';
}
