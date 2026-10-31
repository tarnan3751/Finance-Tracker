/// Where the signed-in session is kept: Android Keystore-backed secure storage in the app,
/// memory in tests, the demo flavor and the dev flavor's fake-server mode (`PLAN.md` §6.6).
///
/// The session is one JSON value under `session_v1`:
/// `{access_token, refresh_token, access_expires_at, user, device}`, with the user and the
/// device as `shared_models` writes them, so a restore needs no network. The install's
/// user, the one account this install's local data belongs to (one user per install), is
/// kept apart under `install_user_v1` and survives sign-out. Tokens never appear in a
/// log, an exception or a `toString`.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';

final Logger _log = Logger('auth');

/// A signed-in device's tokens, with the user and device they belong to.
final class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.user,
    required this.device,
  });

  /// The session stored as [json] (see the library comment).
  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    accessExpiresAt: const UtcInstantConverter().fromJson(
      json['access_expires_at'] as String,
    ),
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    device: Device.fromJson(json['device'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;

  /// When the access token expires, UTC, by the device's clock when it was issued.
  final DateTime accessExpiresAt;

  /// The signed-in user, as `GET /me` last returned it.
  final User user;

  /// This installation's device.
  final Device device;

  String get userId => user.id;
  String get deviceId => device.id;

  /// This session with [user] in place of its own.
  Session withUser(User user) => Session(
    accessToken: accessToken,
    refreshToken: refreshToken,
    accessExpiresAt: accessExpiresAt,
    user: user,
    device: device,
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'access_expires_at': const UtcInstantConverter().toJson(accessExpiresAt),
    'user': user.toJson(),
    'device': device.toJson(),
  };

  @override
  String toString() => 'Session(user: ${user.id}, device: ${device.id})';
}

/// Reads and writes the session and the install's user.
///
/// [write], [clear] and [update] run one after another, so an [update] reads and writes
/// the latest value with no other change landing between the two.
abstract interface class TokenStore {
  /// The stored session, or null when signed out.
  Future<Session?> read();

  /// The stored session read again from where it is kept, past any copy in memory: the
  /// background sync's isolate (`docs/reference/background.md`) may have refreshed it.
  Future<Session?> reload();

  /// Stores [session], replacing any other.
  Future<void> write(Session session);

  /// Removes the session. The install's user is kept.
  Future<void> clear();

  /// Replaces the session with [change] applied to the latest one, atomically: null
  /// clears it, and returning the same session leaves the store untouched.
  Future<void> update(Session? Function(Session? current) change);

  /// The id of the user this install's data belongs to, or null before the first
  /// sign-in. A storage failure throws: an unreadable marker must never read as "none".
  Future<String?> readInstallUserId();

  /// Records [userId] as the install's user.
  Future<void> writeInstallUserId(String userId);

  /// Forgets the install's user: only the local wipe, once the install's data is gone,
  /// lifts the one-user-per-install rule.
  Future<void> clearInstallUserId();
}

/// Runs the store's changes one after another.
final class _SerialQueue {
  Future<void> _last = Future<void>.value();

  Future<void> run(Future<void> Function() body) {
    final Future<void> next = _last.then((_) => body());
    // A failed change does not stop the ones queued after it.
    _last = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

/// The session in `flutter_secure_storage`, with the database key's options
/// (`resetOnError` off, the `finance_tracker` namespace), cached in memory after the first
/// read so a request does not cross the platform channel.
///
/// A session that cannot be read (a storage failure such as a decryption error, or a value
/// this build cannot parse, whatever the error) is deleted and read as signed out: the
/// user signs in again. Only the error's type is logged. The database key is a different
/// value and is never touched here.
final class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: androidOptions);

  static const AndroidOptions androidOptions = AndroidOptions(
    resetOnError: false,
    storageNamespace: 'finance_tracker',
  );

  static const String sessionKey = 'session_v1';
  static const String installUserKey = 'install_user_v1';

  final FlutterSecureStorage _storage;
  final _SerialQueue _queue = _SerialQueue();
  bool _loaded = false;
  Session? _session;

  @override
  Future<Session?> read() async {
    if (_loaded) return _session;
    String? text;
    try {
      text = await _storage.read(key: sessionKey);
    } on PlatformException catch (e) {
      return _discard(e);
    }
    Session? session;
    if (text != null) {
      try {
        session = Session.fromJson(jsonDecode(text) as Map<String, dynamic>);
      } on Object catch (e) {
        // A shape this build does not know: never let it stop startup.
        return _discard(e);
      }
    }
    _session = session;
    _loaded = true;
    return session;
  }

  Future<Session?> _discard(Object error) async {
    // Only the type: the value may hold tokens.
    _log.warning('the stored session could not be read: ${error.runtimeType}');
    await _storage.delete(key: sessionKey);
    _session = null;
    _loaded = true;
    return null;
  }

  @override
  Future<Session?> reload() async {
    Session? session;
    await _queue.run(() async {
      final String? text;
      try {
        text = await _storage.read(key: sessionKey);
      } on PlatformException catch (e) {
        // A storage that fails now says nothing about the session: the copy in memory
        // stands. Only the type is logged.
        _log.warning('the stored session was not read again: ${e.runtimeType}');
        session = _loaded ? _session : null;
        return;
      }
      if (text == null) {
        _session = null;
        _loaded = true;
        return;
      }
      try {
        _session = Session.fromJson(jsonDecode(text) as Map<String, dynamic>);
        _loaded = true;
        session = _session;
      } on Object catch (e) {
        // A value this build cannot parse is the one thing that is discarded.
        session = await _discard(e);
      }
    });
    return session;
  }

  @override
  Future<void> write(Session session) => _queue.run(() => _write(session));

  @override
  Future<void> clear() => _queue.run(_clear);

  @override
  Future<void> update(Session? Function(Session? current) change) =>
      _queue.run(() async {
        final Session? current = await read();
        final Session? next = change(current);
        if (identical(next, current)) return;
        await (next == null ? _clear() : _write(next));
      });

  Future<void> _write(Session session) async {
    await _storage.write(key: sessionKey, value: jsonEncode(session.toJson()));
    _session = session;
    _loaded = true;
  }

  Future<void> _clear() async {
    await _storage.delete(key: sessionKey);
    _session = null;
    _loaded = true;
  }

  @override
  Future<String?> readInstallUserId() => _storage.read(key: installUserKey);

  @override
  Future<void> writeInstallUserId(String userId) =>
      _storage.write(key: installUserKey, value: userId);

  @override
  Future<void> clearInstallUserId() => _storage.delete(key: installUserKey);
}

/// A [TokenStore] in memory.
final class InMemoryTokenStore implements TokenStore {
  InMemoryTokenStore({this.session, this.installUserId});

  /// The stored session.
  Session? session;

  /// The install's user.
  String? installUserId;

  final _SerialQueue _queue = _SerialQueue();

  @override
  Future<Session?> read() async => session;

  @override
  Future<Session?> reload() async => session;

  @override
  Future<void> write(Session session) =>
      _queue.run(() async => this.session = session);

  @override
  Future<void> clear() => _queue.run(() async => session = null);

  @override
  Future<void> update(Session? Function(Session? current) change) =>
      _queue.run(() async => session = change(session));

  @override
  Future<String?> readInstallUserId() async => installUserId;

  @override
  Future<void> writeInstallUserId(String userId) async =>
      installUserId = userId;

  @override
  Future<void> clearInstallUserId() async => installUserId = null;
}
