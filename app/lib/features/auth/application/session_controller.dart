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
/// - **Sign-out** has two halves. [logOutOnServer] calls logout best-effort (after one
///   refresh if the access token had expired) and changes nothing here; [signOut], which
///   Settings' Sign out calls, runs it and then clears the stored session and signs out,
///   whatever the answer. The install's user stays. Erasing the device
///   (`AccountActions.eraseDevice`) calls [logOutOnServer] alone and leaves the clearing to
///   the local wipe, which runs with the app stopped.
/// - **Ended elsewhere.** A session the server ended (the client's `sessionEnded`: a
///   `token_revoked` answer or a refused refresh, or the restore's 401) signs out and
///   leaves a notice the sign-in screen takes once ([takeRemoteSignOutNotice]); the local
///   data stays. A user's own [signOut] never leaves one, even when its logout's refresh
///   is refused and the client fires `sessionEnded` meanwhile. [endLocally] signs out
///   after this device removed itself, with no logout call and no notice.
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
  bool _endedRemotely = false;
  bool _signingOut = false;

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
        .listen((_) => _signedOutRemotely());
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
    // Read before the await: the container may be gone when it returns (a restore
    // restarts the app), and a disposed ref cannot be read.
    final FinanceApi api = _api;
    final TokenStore store = _store;
    try {
      final User user = await api.getMe();
      // Applied to the latest session, so a refresh that landed meanwhile is kept.
      Session? updated;
      await store.update((latest) {
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
      await store.update((latest) {
        if (latest != null && latest.deviceId != stored.deviceId) return latest;
        ended = true;
        return null;
      });
      if (ended) _signedOutRemotely();
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
    _endedRemotely = false;
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
    // Its logout's refresh may be refused, which ends the session through the client
    // too: that is still the user's own sign-out, with no notice.
    _signingOut = true;
    try {
      await logOutOnServer();
      await _store.clear();
      _signedOut();
    } finally {
      _signingOut = false;
    }
  }

  /// Logs this device out on the server, best effort, and keeps the stored session and
  /// the state: [signOut]'s first half, and the erase's, whose wipe then clears the store
  /// with the app stopped, so nothing moves to the sign-in screen meanwhile.
  Future<void> logOutOnServer() async {
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
  }

  /// Signs out with the stored session already gone on the server: this device removed
  /// itself (`DELETE /devices/{id}`), so a logout would only be refused.
  Future<void> endLocally() async {
    await _store.clear();
    _signedOut();
  }

  /// Whether the last session ended on the server's word rather than the user's here;
  /// true at most once per such ending.
  bool takeRemoteSignOutNotice() {
    final bool notice = _endedRemotely;
    _endedRemotely = false;
    return notice;
  }

  /// Records that the session ended on the server's word while the app was not running
  /// (the background sync met it, `core/background/`), so the sign-in screen says so
  /// once. Nothing happens while someone is signed in.
  void noteEndedRemotely() {
    if (state is SignedOut) _endedRemotely = true;
  }

  void _signedOutRemotely() {
    if (!_signingOut) _endedRemotely = true;
    _signedOut();
  }

  void _signedOut() {
    if (ref.mounted) state = const SignedOut();
  }
}
