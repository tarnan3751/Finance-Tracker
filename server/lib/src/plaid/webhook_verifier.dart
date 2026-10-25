/// Verification of Plaid's webhook deliveries (`docs/reference/server.md`, **Webhooks**;
/// `PLAN.md` §4 and §6.5).
///
/// A delivery carries a `Plaid-Verification` header: an ES256 JWT whose header names the
/// key (`kid`) and whose claims carry `iat` and `request_body_sha256`. [WebhookVerifier]
/// checks, in order, and on the first failure throws [WebhookRejected] naming the class of
/// the failure (never the token or the body):
///
/// 1. the header is present and is three base64url parts (`missing_header`, `malformed`);
/// 2. the JWT header says `alg: ES256` and names a `kid` (`bad_alg`, `malformed`), checked
///    before anything is fetched or verified, so the token cannot choose its algorithm;
/// 3. the key: from a per-`kid` cache younger than an hour, else from
///    `/webhook_verification_key/get`, one fetch per `kid` in flight at a time
///    (`unknown_kid` when Plaid does not know it, `key_unavailable` when the fetch fails);
///    it must be an EC P-256 key (`bad_key`) whose `expired_at` is null: Plaid sets it
///    only once a key has expired, so any value is `key_expired` (as Plaid's own sample
///    verifier does);
/// 4. a 64-byte signature that verifies with `dart_jsonwebtoken` (`bad_signature`);
/// 5. `iat` within five minutes of the server's clock, either way (`stale`);
/// 6. `request_body_sha256` equal, in constant time, to the SHA-256 of the exact bytes
///    received (`body_mismatch`).
library;

import 'dart:async';
import 'dart:convert';

import 'package:cryptography/dart.dart' show DartSha256;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';

/// How long a fetched key is used before it is fetched again, so an `expired_at` Plaid
/// sets later is seen within the hour.
const webhookKeyMaxAge = Duration(hours: 1);

/// How far `iat` may be from the server's clock.
const webhookMaxAge = Duration(minutes: 5);

/// A delivery that did not verify; [reason] is the class of the failure, for logs.
final class WebhookRejected implements Exception {
  /// A rejection.
  const WebhookRejected(this.reason);

  /// `missing_header`, `malformed`, `bad_alg`, `unknown_kid`, `key_unavailable`,
  /// `bad_key`, `key_expired`, `bad_signature`, `stale` or `body_mismatch`.
  final String reason;

  @override
  String toString() => 'WebhookRejected($reason)';
}

/// The verifier.
final class WebhookVerifier {
  /// A verifier fetching keys through [plaid], on the server's clock [now].
  WebhookVerifier({required this.plaid, required this.now});

  /// The Plaid client.
  final PlaidClient plaid;

  /// The server's clock.
  final DateTime Function() now;

  final Map<String, ({Map<String, Object?> jwk, DateTime fetchedAt})> _keys =
      {};
  final Map<String, Future<Map<String, Object?>>> _fetching = {};

  /// Verifies the delivery of [body] (its exact bytes) under the header value [token];
  /// throws [WebhookRejected] when it does not verify.
  Future<void> verify(List<int> body, String? token) async {
    if (token == null || token.isEmpty) {
      throw const WebhookRejected('missing_header');
    }
    final parts = token.split('.');
    if (parts.length != 3) throw const WebhookRejected('malformed');
    final header = _jsonPart(parts[0]);
    if (header['alg'] != 'ES256') throw const WebhookRejected('bad_alg');
    final kid = header['kid'];
    if (kid is! String || kid.isEmpty) throw const WebhookRejected('malformed');

    final jwk = await _key(kid);
    if (jwk['kty'] != 'EC' || jwk['crv'] != 'P-256') {
      throw const WebhookRejected('bad_key');
    }
    // Plaid sets expired_at only once the key has expired: any value rejects it.
    if (jwk['expired_at'] != null) throw const WebhookRejected('key_expired');

    final List<int> signature;
    try {
      signature = base64Url.decode(base64Url.normalize(parts[2]));
    } on FormatException {
      throw const WebhookRejected('malformed');
    }
    if (signature.length != 64) throw const WebhookRejected('bad_signature');
    final JWTKey key;
    try {
      key = JWTKey.fromJWK(jwk);
    } on Object {
      throw const WebhookRejected('bad_key');
    }
    if (key is! ECPublicKey) throw const WebhookRejected('bad_key');
    final JWT jwt;
    try {
      jwt = JWT.verify(
        token,
        key,
        checkHeaderType: false,
        checkExpiresIn: false,
        checkNotBefore: false,
      );
    } on JWTException {
      throw const WebhookRejected('bad_signature');
    }
    final claims = jwt.payload;
    if (claims is! Map) throw const WebhookRejected('malformed');

    final iat = claims['iat'];
    if (iat is! int) throw const WebhookRejected('stale');
    final skew = now().millisecondsSinceEpoch - iat * 1000;
    if (skew.abs() > webhookMaxAge.inMilliseconds) {
      throw const WebhookRejected('stale');
    }

    final claimed = claims['request_body_sha256'];
    final actual = _hex(const DartSha256().hashSync(body).bytes);
    if (claimed is! String ||
        !_constantTimeEquals(claimed.toLowerCase(), actual)) {
      throw const WebhookRejected('body_mismatch');
    }
  }

  static Map<String, Object?> _jsonPart(String part) {
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(part))),
      );
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Falls through to the rejection.
    }
    throw const WebhookRejected('malformed');
  }

  Future<Map<String, Object?>> _key(String kid) async {
    final cached = _keys[kid];
    if (cached != null &&
        now().difference(cached.fetchedAt) < webhookKeyMaxAge) {
      return cached.jwk;
    }
    // One fetch per kid in flight; every delivery waiting on that kid shares it. (The
    // callback must not return the removed future, which whenComplete would await.)
    return _fetching[kid] ??= _fetch(kid).whenComplete(() {
      _fetching.remove(kid);
    });
  }

  Future<Map<String, Object?>> _fetch(String kid) async {
    try {
      final jwk = await plaid.webhookVerificationKeyGet(kid);
      _keys[kid] = (jwk: jwk, fetchedAt: now());
      return jwk;
    } on PlaidException catch (e) {
      _keys.remove(kid);
      throw WebhookRejected(
        e.errorCode == 'INVALID_WEBHOOK_VERIFICATION_KEY_ID'
            ? 'unknown_kid'
            : 'key_unavailable',
      );
    }
  }

  static String _hex(List<int> bytes) =>
      [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
