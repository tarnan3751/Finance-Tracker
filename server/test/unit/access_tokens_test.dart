import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:finance_tracker_server/src/auth/access_tokens.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:test/test.dart';

import '../support/test_server.dart';

Matcher _unauthorized(ProblemCode code) => throwsA(
  isA<ProblemException>()
      .having((e) => e.status, 'status', 401)
      .having((e) => e.code, 'code', code),
);

void main() {
  final secret = List.filled(32, 7);
  final clock = TestClock();
  final tokens = AccessTokens(secret: secret, now: clock.call);

  Map<String, Object?> part(String token, int i) => jsonDecode(
    utf8.decode(base64Url.decode(base64.normalize(token.split('.')[i]))),
  ) as Map<String, Object?>;

  test('issues HS256 with kid and the claims', () {
    final token = tokens.issue(userId: 'u1', deviceId: 'd1');
    final header = part(token, 0);
    expect(header['alg'], 'HS256');
    expect(header['kid'], tokens.currentKeyId);
    expect(tokens.currentKeyId, hasLength(16));
    final claims = part(token, 1);
    expect(claims['sub'], 'u1');
    expect(claims['dev'], 'd1');
    expect(claims['jti'], isA<String>());
    final iat = claims['iat']! as int;
    expect(iat, clock.value.millisecondsSinceEpoch ~/ 1000);
    expect(claims['exp'], iat + 900);
    expect(tokens.verify(token), (userId: 'u1', deviceId: 'd1'));
  });

  test('expires on the server clock', () {
    final t = TestClock();
    final short = AccessTokens(secret: secret, now: t.call);
    final token = short.issue(userId: 'u', deviceId: 'd');
    t.advance(const Duration(minutes: 15));
    expect(() => short.verify(token), _unauthorized(ProblemCode.tokenExpired));
  });

  test('a token signed by an unknown key, or tampered, is invalid', () {
    final other = AccessTokens(secret: List.filled(32, 8), now: clock.call);
    expect(
      () => tokens.verify(other.issue(userId: 'u', deviceId: 'd')),
      _unauthorized(ProblemCode.invalidCredentials),
    );
    final token = tokens.issue(userId: 'u', deviceId: 'd');
    final parts = token.split('.');
    final forged = base64Url
        .encode(utf8.encode(jsonEncode({...part(token, 1), 'sub': 'eve'})))
        .replaceAll('=', '');
    expect(
      () => tokens.verify('${parts[0]}.$forged.${parts[2]}'),
      _unauthorized(ProblemCode.invalidCredentials),
    );
  });

  test('the algorithm cannot be chosen by the token', () {
    final key = SecretKey(base64.encode(secret), isBase64Encoded: true);
    final hs512 = JWT(
      {'sub': 'u', 'dev': 'd', 'exp': 9999999999},
      header: {'kid': tokens.currentKeyId},
    ).sign(key, algorithm: JWTAlgorithm.HS512);
    expect(
      () => tokens.verify(hs512),
      _unauthorized(ProblemCode.invalidCredentials),
    );
    String b64(Map<String, Object?> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final none =
        '${b64({'alg': 'none', 'typ': 'JWT', 'kid': tokens.currentKeyId})}.'
        '${b64({'sub': 'u', 'dev': 'd', 'exp': 9999999999})}.';
    expect(
      () => tokens.verify(none),
      _unauthorized(ProblemCode.invalidCredentials),
    );
  });

  test('a token from the future or living too long is refused', () {
    final key = SecretKey(base64.encode(secret), isBase64Encoded: true);
    String forge(int iat, int exp) => JWT(
      {'sub': 'u', 'dev': 'd', 'iat': iat, 'exp': exp, 'jti': 'j'},
      header: {'kid': tokens.currentKeyId},
    ).sign(key, algorithm: JWTAlgorithm.HS256, noIssueAt: true);
    final now = clock.value.millisecondsSinceEpoch ~/ 1000;
    expect(tokens.verify(forge(now + 60, now + 900)).userId, 'u');
    expect(
      () => tokens.verify(forge(now + 61, now + 900)),
      _unauthorized(ProblemCode.invalidCredentials),
    );
    expect(tokens.verify(forge(now, now + 960)).userId, 'u');
    expect(
      () => tokens.verify(forge(now, now + 961)),
      _unauthorized(ProblemCode.invalidCredentials),
    );
    final noIat = JWT(
      {'sub': 'u', 'dev': 'd', 'exp': now + 900},
      header: {'kid': tokens.currentKeyId},
    ).sign(key, algorithm: JWTAlgorithm.HS256, noIssueAt: true);
    expect(
      () => tokens.verify(noIat),
      _unauthorized(ProblemCode.invalidCredentials),
    );
  });

  test('a previous key still verifies during a rotation', () {
    final old = AccessTokens(secret: List.filled(32, 3), now: clock.call);
    final rotated = AccessTokens(
      secret: secret,
      previousSecret: List.filled(32, 3),
      now: clock.call,
    );
    expect(rotated.verify(old.issue(userId: 'u', deviceId: 'd')).userId, 'u');
    expect(
      part(rotated.issue(userId: 'u', deviceId: 'd'), 0)['kid'],
      tokens.currentKeyId,
    );
  });
}
