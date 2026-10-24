/// Registration, login, token rotation, logout and bearer resolution
/// (`docs/reference/server.md`, **Tokens**).
///
/// A device is one signed-in installation: registration and every login create one, with
/// a new refresh-token family. A refresh token is 32 random bytes (base64url), stored only
/// as its SHA-256, valid for [refreshLifetime] from issue. Refreshing rotates: the
/// presented token is revoked and a new one joins the family with `rotated_from` naming
/// it. Presenting a revoked token again is reuse: the whole family is revoked and the
/// answer is 401 `token_revoked`. A device is signed in while it has an unrevoked,
/// unexpired refresh token; the bearer check requires that, so revoking a family also
/// ends the device's access tokens at once.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/dart.dart' show DartSha256;
import 'package:finance_tracker_server/src/auth/access_tokens.dart';
import 'package:finance_tracker_server/src/auth/password_hasher.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/ids.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:logging/logging.dart';

/// How long a refresh token is valid after it is issued.
const refreshLifetime = Duration(days: 30);

/// The authentication flows.
final class AuthService {
  /// The service over [db].
  AuthService({
    required this.db,
    required this.hasher,
    required this.accessTokens,
    required this.now,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// The database.
  final AppDatabase db;

  /// The password hasher.
  final PasswordHasher hasher;

  /// The access-token issuer.
  final AccessTokens accessTokens;

  /// The server's clock.
  final DateTime Function() now;

  final Random _random;
  final Logger _log = Logger('auth');

  late final Future<String> _dummyHash = hasher.hash(
    'not a password of anyone',
  );

  int get _nowMillis => now().millisecondsSinceEpoch;

  /// Creates the user and its first device; the `AuthTokens` JSON. A taken email is 409
  /// `email_taken`.
  Future<Map<String, Object?>> register({
    required String email,
    required String password,
    required String deviceName,
    String? displayName,
  }) async {
    final folded = email.toLowerCase();
    final hash = await hasher.hash(password);
    return db.transaction((tx) async {
      if (tx.first('SELECT 1 FROM users WHERE email = ?', [folded]) != null) {
        throw const ProblemException(
          409,
          ProblemCode.emailTaken,
          detail: 'That email is already registered',
        );
      }
      final userId = newId();
      tx.execute(
        'INSERT INTO users (id, email, password_hash, display_name, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          userId,
          folded,
          hash,
          displayName ?? folded.substring(0, folded.indexOf('@')),
          _nowMillis,
        ],
      );
      _log.info(LogEvent('user_registered', {'user_id': userId}));
      return _signIn(tx, userId, deviceName);
    });
  }

  /// Checks the credentials and signs a new device in; the `AuthTokens` JSON. Wrong
  /// credentials are 401 `invalid_credentials`, after the same hashing work as right ones.
  Future<Map<String, Object?>> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final user = await db.read(
      (tx) => tx.first('SELECT id, password_hash FROM users WHERE email = ?', [
        email.toLowerCase(),
      ]),
    );
    final stored = user?['password_hash'] as String? ?? await _dummyHash;
    final matches = await hasher.verify(password, stored);
    if (user == null || !matches) {
      throw const ProblemException.unauthorized(
        ProblemCode.invalidCredentials,
        detail: 'Wrong email or password',
      );
    }
    final userId = user['id'] as String;
    final rehash = hasher.needsRehash(stored)
        ? await hasher.hash(password)
        : null;
    return db.transaction((tx) async {
      if (rehash != null) {
        tx.execute('UPDATE users SET password_hash = ? WHERE id = ?', [
          rehash,
          userId,
        ]);
        _log.info(LogEvent('password_rehashed', {'user_id': userId}));
      }
      return _signIn(tx, userId, deviceName);
    });
  }

  /// Rotates [refreshToken]; the new `AuthTokens` JSON.
  Future<Map<String, Object?>> refresh(String refreshToken) async {
    final hash = _hash(refreshToken);
    final outcome = await db.transaction((tx) async {
      final row = tx.first(
        'SELECT t.id, t.device_id, t.family_id, t.expires_at, t.revoked_at, '
        'd.user_id FROM refresh_tokens t JOIN devices d ON d.id = t.device_id '
        'WHERE t.token_hash = ?',
        [hash],
      );
      if (row == null) return (ProblemCode.tokenRevoked, null);
      final familyId = row['family_id'] as String;
      final deviceId = row['device_id'] as String;
      if (row['revoked_at'] != null) {
        _revokeFamily(tx, familyId);
        _log.warning(
          LogEvent('refresh_token_reuse', {
            'family_id': familyId,
            'device_id': deviceId,
            'user_id': row['user_id'],
          }),
        );
        return (ProblemCode.tokenRevoked, null);
      }
      if ((row['expires_at'] as int) <= _nowMillis) {
        return (ProblemCode.tokenExpired, null);
      }
      tx.execute('UPDATE refresh_tokens SET revoked_at = ? WHERE id = ?', [
        _nowMillis,
        row['id'],
      ]);
      final token = _insertRefreshToken(
        tx,
        deviceId,
        familyId,
        rotatedFrom: row['id'] as String,
      );
      _touchDevice(tx, deviceId);
      return (null, _authTokens(tx, row['user_id'] as String, deviceId, token));
    });
    final (problem, tokens) = outcome;
    if (problem != null) {
      throw ProblemException.unauthorized(
        problem,
        detail: problem == ProblemCode.tokenExpired
            ? 'The refresh token has expired; sign in again'
            : 'The refresh token is not valid; sign in again',
      );
    }
    return tokens!;
  }

  /// Signs [deviceId] out with its [refreshToken]: the token's family is revoked and the
  /// device removed. A token of another device is 401 `token_revoked`.
  Future<void> logout({
    required String deviceId,
    required String refreshToken,
  }) async {
    final hash = _hash(refreshToken);
    final ok = await db.transaction((tx) async {
      final row = tx.first(
        'SELECT family_id, device_id FROM refresh_tokens WHERE token_hash = ?',
        [hash],
      );
      if (row == null || row['device_id'] != deviceId) return false;
      _revokeFamily(tx, row['family_id'] as String);
      tx.execute('DELETE FROM devices WHERE id = ?', [deviceId]);
      return true;
    });
    if (!ok) {
      throw const ProblemException.unauthorized(
        ProblemCode.tokenRevoked,
        detail: 'That refresh token does not belong to this device',
      );
    }
  }

  /// Resolves an `Authorization` header to its user and device. The token must verify
  /// and its device must still be signed in (401 `token_revoked` otherwise).
  Future<AccessClaims> authenticate(String? authorization) async {
    final match = RegExp(
      r'^Bearer ([A-Za-z0-9._~+/=-]+)$',
      caseSensitive: false,
    ).firstMatch(authorization ?? '');
    if (match == null) {
      throw const ProblemException.unauthorized(
        ProblemCode.invalidCredentials,
        detail: 'A bearer access token is required',
      );
    }
    final claims = accessTokens.verify(match[1]!);
    final active = await db.read((tx) {
      final row = tx.first(
        'SELECT d.last_seen_at FROM devices d WHERE d.id = ? AND d.user_id = ? '
        'AND EXISTS (SELECT 1 FROM refresh_tokens t WHERE t.device_id = d.id '
        'AND t.revoked_at IS NULL AND t.expires_at > ?)',
        [claims.deviceId, claims.userId, _nowMillis],
      );
      if (row == null) return false;
      if (_nowMillis - (row['last_seen_at'] as int) >= 60000) {
        _touchDevice(tx, claims.deviceId);
      }
      return true;
    });
    if (!active) {
      throw const ProblemException.unauthorized(
        ProblemCode.tokenRevoked,
        detail: 'This device has been signed out',
      );
    }
    return claims;
  }

  /// Revokes every refresh-token family of [deviceId] and removes the device, inside [tx].
  void removeDevice(Tx tx, String deviceId) {
    tx.execute(
      'UPDATE refresh_tokens SET revoked_at = ? WHERE device_id = ? '
      'AND revoked_at IS NULL',
      [_nowMillis, deviceId],
    );
    tx.execute('DELETE FROM devices WHERE id = ?', [deviceId]);
  }

  Map<String, Object?> _signIn(Tx tx, String userId, String deviceName) {
    final deviceId = newId();
    tx.execute(
      'INSERT INTO devices (id, user_id, name, created_at, last_seen_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [deviceId, userId, deviceName, _nowMillis, _nowMillis],
    );
    final token = _insertRefreshToken(tx, deviceId, newId());
    _log.info(
      LogEvent('device_signed_in', {'user_id': userId, 'device_id': deviceId}),
    );
    return _authTokens(tx, userId, deviceId, token);
  }

  Map<String, Object?> _authTokens(
    Tx tx,
    String userId,
    String deviceId,
    String refreshToken,
  ) => {
    'access_token': accessTokens.issue(userId: userId, deviceId: deviceId),
    'refresh_token': refreshToken,
    'access_expires_in': AccessTokens.lifetime.inSeconds,
    'device': deviceJson(
      tx.first('SELECT * FROM devices WHERE id = ?', [deviceId])!,
    ),
  };

  String _insertRefreshToken(
    Tx tx,
    String deviceId,
    String familyId, {
    String? rotatedFrom,
  }) {
    final token = base64Url
        .encode([for (var i = 0; i < 32; i++) _random.nextInt(256)])
        .replaceAll('=', '');
    tx.execute(
      'INSERT INTO refresh_tokens (id, device_id, token_hash, family_id, created_at, '
      'expires_at, rotated_from) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        newId(),
        deviceId,
        _hash(token),
        familyId,
        _nowMillis,
        _nowMillis + refreshLifetime.inMilliseconds,
        rotatedFrom,
      ],
    );
    return token;
  }

  void _revokeFamily(Tx tx, String familyId) => tx.execute(
    'UPDATE refresh_tokens SET revoked_at = ? WHERE family_id = ? '
    'AND revoked_at IS NULL',
    [_nowMillis, familyId],
  );

  void _touchDevice(Tx tx, String deviceId) => tx.execute(
    'UPDATE devices SET last_seen_at = ? WHERE id = ?',
    [_nowMillis, deviceId],
  );

  static List<int> _hash(String token) =>
      const DartSha256().hashSync(utf8.encode(token)).bytes;
}

/// The contract's `Device` from a `devices` row.
Map<String, Object?> deviceJson(Map<String, Object?> row) => {
  'id': row['id'],
  'user_id': row['user_id'],
  'name': row['name'],
  'last_sync_at': optionalInstantJson(row['last_sync_at'] as int?),
};
