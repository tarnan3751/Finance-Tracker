/// The session: restored from the token store at startup, changed by sign-in,
/// registration and sign-out, and ended by the API client when the server ends it
/// (`docs/reference/auth.md`).
///
/// - **Restore.** A stored session is `SignedIn` at once, from its stored user and
///   device, so the app opens offline; whatever the store throws, startup goes on signed
///   out. `GET /me` then runs in the background: its user replaces the stored one; a 401
///   (after the client's own refresh) signs out, unless a newer session was stored
///   meanwhile; any other failure keeps the session.
/// - **Sign-in and registration** store the session only once `GET /me` has answered for
///   the new token; if it fails, the new device is logged out best-effort and nothing is
///   stored.
/// - **One user per install** (`PLAN.md` §6.6). The first account to sign in is recorded
///   as the install's user. Registration is refused before any network call once one is
///   recorded (it would always create another user); a sign-in that yields another user is
///   logged out best-effort and refused. Both throw `OtherAccountOnDeviceException`. The
///   marker is read before any network call, and a failure to read it propagates.
/// - **Sign-out** calls logout best-effort (after one refresh if the access token had
///   expired) and clears the stored session whatever the answer. The install's user stays.
library;

import 'dart:async';

import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/device_name.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'session_controller.g.dart';

final Logger _log = Logger('auth');

/// The session.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  final Completer<void> _ready = Completer<void>();

  /// Completes once the stored session has been read: the state is then `SignedIn` or
  /// `SignedOut`. `bootstrap` waits for it before the first frame.
  Future<void> restored() => _ready.future;

  FinanceApi get _api => ref.read(financeApiProvider);
  TokenStore get _store => ref.read(tokenStoreProvider);

  @override
  SessionState build() {
    final StreamSubscription<void> ended = ref
        .watch(financeApiProvider)
        .sessionEnded
        .listen((_) => _signedOut());
    ref.onDispose(ended.cancel);
    unawaited(_restore());
    return const SessionUnknown();
  }

  Future<void> _restore() async {
    Session? stored;
    try {
      stored = await _store.read();
      if (!ref.mounted) return;
      state = stored == null
          ? const SignedOut()
          : SignedIn(stored.user, stored.device);
    } on Object catch (e) {
      // Startup must go on whatever the store does: signed out, the type logged.
      _log.warning('the session could not be restored: ${e.runtimeType}');
      stored = null;
      _signedOut();
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
    if (stored != null) await _confirm(stored);
  }

  /// `GET /me` for a restored session.
  Future<void> _confirm(Session stored) async {
    try {
      final User user = await _api.getMe();
      // Applied to the latest session, so a refresh that landed meanwhile is kept.
      Session? updated;
      await _store.update((latest) {
        if (latest == null || latest.deviceId != stored.deviceId) return latest;
        return updated = latest.withUser(user);
      });
      if (updated != null && ref.mounted && state is SignedIn) {
        state = SignedIn(user, updated!.device);
      }
    } on ApiException catch (e) {
      // The client has already refreshed and, for token_revoked, cleared; anything else
      // (offline, a 5xx) keeps the session.
      if (e.status != 401) return;
      // A 401 for [stored] says nothing about a newer session signed in meanwhile.
      bool ended = false;
      await _store.update((latest) {
        if (latest != null && latest.deviceId != stored.deviceId) return latest;
        ended = true;
        return null;
      });
      if (ended) _signedOut();
    }
  }

  /// Signs in with [email] and [password] on this device.
  Future<void> signIn({required String email, required String password}) async {
    // Read before any network call: a marker that cannot be read stops here.
    final String? installUser = await _store.readInstallUserId();
    final String device = await ref.read(deviceNameProvider.future);
    await _complete(
      await _api.login(email: email, password: password, deviceName: device),
      installUser,
    );
  }

  /// Creates an account and signs this device in.
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (await _store.readInstallUserId() != null) {
      throw const OtherAccountOnDeviceException();
    }
    final String device = await ref.read(deviceNameProvider.future);
    await _complete(
      await _api.register(
        email: email,
        password: password,
        deviceName: device,
        displayName: displayName,
      ),
      null,
    );
  }

  /// Stores the session [tokens] open, for the install whose user was [installUser].
  Future<void> _complete(AuthResult tokens, String? installUser) async {
    final User user;
    try {
      user = await _api.getMe(accessToken: tokens.accessToken);
    } on ApiException {
      await _logoutQuietly(tokens);
      rethrow;
    }
    if (installUser != null && installUser != user.id) {
      await _logoutQuietly(tokens);
      throw const OtherAccountOnDeviceException();
    }
    await _store.write(
      Session(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessExpiresAt: ref
            .read(clockProvider)
            .nowUtc()
            .add(tokens.accessExpiresIn),
        user: user,
        device: tokens.device,
      ),
    );
    if (installUser == null) await _store.writeInstallUserId(user.id);
    if (ref.mounted) state = SignedIn(user, tokens.device);
  }

  Future<void> _logoutQuietly(AuthResult tokens) async {
    try {
      await _api.logout(tokens.refreshToken, accessToken: tokens.accessToken);
    } on ApiException {
      // Best effort: the device stays listed on the server until its tokens expire.
    }
  }

  /// Signs this device out.
  Future<void> signOut() async {
    final Session? session = await _store.read();
    if (session != null) {
      try {
        await _api.logout(session.refreshToken);
      } on TokenExpired {
        // Logout is never refreshed on its own (its body is the refresh token a refresh
        // revokes): refresh once through any authenticated call, then log out again.
        try {
          await _api.getMe();
          final Session? refreshed = await _store.read();
          if (refreshed != null) await _api.logout(refreshed.refreshToken);
        } on ApiException {
          // Best effort.
        }
      } on ApiException {
        // Best effort: offline, or the server already ended the session.
      }
    }
    await _store.clear();
    _signedOut();
  }

  void _signedOut() {
    if (ref.mounted) state = const SignedOut();
  }
}
