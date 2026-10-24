/// Access tokens: HS256 JWTs (`docs/reference/server.md`, **Tokens**).
///
/// The header carries `kid`, the first 16 hex digits of the SHA-256 of the signing key, so
/// a previous key (`JWT_SECRET_PREVIOUS`) still verifies during a rotation. The claims are
/// `sub` (the user), `dev` (the device), `iat`, `exp` ([AccessTokens.lifetime] later) and
/// `jti`. The server's clock writes `iat` and `exp` and checks `exp`, so tests control
/// expiry; the header's `alg` must be HS256 and its `kid` known before the signature is
/// checked, so the algorithm cannot be chosen by the token. A token whose `iat` is more
/// than 60 s in the future, or whose `exp − iat` exceeds the lifetime by more than 60 s,
/// is refused as well.
library;

import 'dart:convert';

import 'package:cryptography/dart.dart' show DartSha256;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/ids.dart';

/// The verified claims of an access token.
typedef AccessClaims = ({String userId, String deviceId});

/// Issues and verifies access tokens.
final class AccessTokens {
  /// Tokens signed with [secret]; [previousSecret] verifies too. [now] is the server's
  /// clock.
  AccessTokens({
    required List<int> secret,
    List<int>? previousSecret,
    required this.now,
  }) : _current = _Key(secret),
       _keys = {
         for (final k in [secret, ?previousSecret]) _Key(k).id: _Key(k),
       };

  /// How long an access token lives.
  static const lifetime = Duration(minutes: 15);

  /// The clock skew tolerated on `iat` and on a token's lifetime.
  static const _skew = Duration(seconds: 60);

  /// The server's clock.
  final DateTime Function() now;

  final _Key _current;
  final Map<String, _Key> _keys;

  /// The `kid` of the current signing key.
  String get currentKeyId => _current.id;

  /// A token for [deviceId] of [userId].
  String issue({required String userId, required String deviceId}) {
    final iat = now().millisecondsSinceEpoch ~/ 1000;
    return JWT(
      {
        'sub': userId,
        'dev': deviceId,
        'iat': iat,
        'exp': iat + lifetime.inSeconds,
        'jti': newId(),
      },
      header: {'kid': _current.id},
    ).sign(_current.jwtKey, algorithm: JWTAlgorithm.HS256, noIssueAt: true);
  }

  /// The claims of [token]. Throws a 401 [ProblemException]: `token_expired` past `exp`,
  /// `invalid_credentials` for anything malformed, unsigned, or signed by an unknown key.
  AccessClaims verify(String token) {
    const invalid = ProblemException.unauthorized(
      ProblemCode.invalidCredentials,
      detail: 'The access token is not valid',
    );
    final parts = token.split('.');
    if (parts.length != 3) throw invalid;
    final Object? header;
    try {
      header = jsonDecode(
        utf8.decode(base64Url.decode(base64.normalize(parts[0]))),
      );
    } on FormatException {
      throw invalid;
    }
    if (header is! Map<String, Object?> || header['alg'] != 'HS256') {
      throw invalid;
    }
    final key = _keys[header['kid']];
    if (key == null) throw invalid;
    final Object? payload;
    try {
      payload = JWT
          .verify(
            token,
            key.jwtKey,
            checkExpiresIn: false,
            checkNotBefore: false,
          )
          .payload;
    } on JWTException {
      throw invalid;
    }
    if (payload is! Map<String, Object?>) throw invalid;
    final (sub, dev, iat, exp) = (
      payload['sub'],
      payload['dev'],
      payload['iat'],
      payload['exp'],
    );
    if (sub is! String || dev is! String || iat is! int || exp is! int) {
      throw invalid;
    }
    // Defence in depth: a token issued in the future or living longer than this server
    // issues was not issued by it as it is configured.
    final nowSeconds = now().millisecondsSinceEpoch ~/ 1000;
    if (iat > nowSeconds + _skew.inSeconds ||
        exp - iat > lifetime.inSeconds + _skew.inSeconds) {
      throw invalid;
    }
    if (exp * 1000 <= now().millisecondsSinceEpoch) {
      throw const ProblemException.unauthorized(
        ProblemCode.tokenExpired,
        detail: 'The access token has expired; refresh it',
      );
    }
    return (userId: sub, deviceId: dev);
  }
}

final class _Key {
  _Key(List<int> bytes)
    : id = _hex(const DartSha256().hashSync(bytes).bytes).substring(0, 16),
      jwtKey = SecretKey(base64.encode(bytes), isBase64Encoded: true);

  final String id;
  final SecretKey jwtKey;

  static String _hex(List<int> bytes) =>
      [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
}
