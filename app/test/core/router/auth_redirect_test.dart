// The session gate's redirect rules, case by case; the widget tests drive them through
// the router in each flavor (test/features/auth/auth_screens_test.dart).
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  final SignedIn signedIn = SignedIn(
    User(
      id: 'user-1',
      email: 'ada@example.com',
      displayName: 'Ada',
      createdAt: DateTime.utc(2026),
    ),
    const Device(id: 'device-1', userId: 'user-1', name: 'Pixel 6'),
  );

  test('no gate (demo) and an unknown session only redirect /', () {
    for (final SessionState? session in [null, const SessionUnknown()]) {
      expect(redirectFor('/', session), '/accounts');
      expect(redirectFor('/settings', session), isNull);
      expect(redirectFor('/sign-in', session), isNull);
    }
  });

  test('signed out goes to sign-in, and may move between the auth screens', () {
    expect(redirectFor('/', const SignedOut()), '/sign-in');
    expect(redirectFor('/accounts/a1', const SignedOut()), '/sign-in');
    expect(redirectFor('/sign-in', const SignedOut()), isNull);
    expect(redirectFor('/register', const SignedOut()), isNull);
  });

  test('signed in leaves the auth screens for the shell', () {
    expect(redirectFor('/sign-in', signedIn), '/accounts');
    expect(redirectFor('/register', signedIn), '/accounts');
    expect(redirectFor('/', signedIn), '/accounts');
    expect(redirectFor('/transactions', signedIn), isNull);
  });
}
