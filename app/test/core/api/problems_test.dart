// The problem mapper: every contract code to its exception, the answers it cannot read,
// and failures with no answer.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _answer(
  int status,
  Object? body, {
  Map<String, List<String>> headers = const {},
  Map<String, dynamic> query = const {},
}) {
  final RequestOptions options = RequestOptions(
    path: '/x',
    queryParameters: query,
  );
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap(headers),
    ),
  );
}

Map<String, Object?> _problem(int status, String code) => {
  'type': 'urn:finance-tracker:problem:$code',
  'title': code,
  'status': status,
  'code': code,
};

void main() {
  test('every problem code maps to its exception', () {
    final Map<String, (int, Type)> cases = {
      'invalid_credentials': (401, InvalidCredentials),
      'email_taken': (409, EmailTaken),
      'token_expired': (401, TokenExpired),
      'token_revoked': (401, TokenRevoked),
      'not_found': (404, NotFound),
      'conflict': (409, Conflict),
      'item_login_required': (409, ItemLoginRequired),
      'plaid_error': (502, PlaidError),
      'rate_limited': (429, RateLimited),
      'sync_cursor_invalid': (409, SyncCursorInvalid),
      'internal': (500, ServerError),
      'webhook_unverified': (401, ServerError),
    };
    for (final MapEntry(key: code, value: (status, type)) in cases.entries) {
      final ApiException e = ApiException.fromDio(
        _answer(status, _problem(status, code)),
      );
      expect(e.runtimeType, type, reason: code);
      expect(e.status, status, reason: code);
      expect(e.code, code, reason: code);
    }
  });

  test('validation_failed carries the field errors', () {
    final ApiException e = ApiException.fromDio(
      _answer(400, {
        ..._problem(400, 'validation_failed'),
        'errors': [
          {'field': 'password', 'message': 'must be at least 8 characters'},
        ],
      }),
    );
    expect(e, isA<ValidationFailed>());
    final ValidationFailed failed = e as ValidationFailed;
    expect(failed.errors.single.field, 'password');
  });

  test(
    'rate_limited reads Retry-After; sync_cursor_invalid the since sent',
    () {
      final ApiException limited = ApiException.fromDio(
        _answer(
          429,
          _problem(429, 'rate_limited'),
          headers: {
            'retry-after': ['7'],
          },
        ),
      );
      expect((limited as RateLimited).retryAfter, const Duration(seconds: 7));
      final ApiException noHeader = ApiException.fromDio(
        _answer(429, _problem(429, 'rate_limited')),
      );
      expect((noHeader as RateLimited).retryAfter, isNull);

      final ApiException cursor = ApiException.fromDio(
        _answer(
          409,
          _problem(409, 'sync_cursor_invalid'),
          query: {'since': 42},
        ),
      );
      expect((cursor as SyncCursorInvalid).since, 42);
    },
  );

  test(
    'a problem read as bytes (an image operation) maps to its exception',
    () {
      final ApiException e = ApiException.fromDio(
        _answer(
          404,
          utf8.encode(jsonEncode({'code': 'not_found', 'status': 404})),
        ),
      );
      expect(e, isA<NotFound>());
    },
  );

  test('an answer that is not a problem is a ServerError', () {
    for (final Object? body in [
      null,
      'Bad gateway',
      <String, Object?>{},
      [1],
    ]) {
      final ApiException e = ApiException.fromDio(_answer(502, body));
      expect(e, isA<ServerError>(), reason: '$body');
      expect(e.status, 502);
    }
    // A 2xx the generated client could not deserialize.
    final RequestOptions options = RequestOptions(path: '/x');
    final ApiException unreadable = ApiException.fromDio(
      DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: {'nope': true},
        ),
      ),
    );
    expect(unreadable, isA<ServerError>());
  });

  test('a failure with no answer is a NetworkError of its kind', () {
    final RequestOptions options = RequestOptions(path: '/x');
    final Map<DioExceptionType, NetworkErrorKind> kinds = {
      DioExceptionType.connectionTimeout: NetworkErrorKind.timeout,
      DioExceptionType.sendTimeout: NetworkErrorKind.timeout,
      DioExceptionType.receiveTimeout: NetworkErrorKind.timeout,
      DioExceptionType.cancel: NetworkErrorKind.cancelled,
      DioExceptionType.badCertificate: NetworkErrorKind.badCertificate,
      DioExceptionType.connectionError: NetworkErrorKind.connection,
      DioExceptionType.unknown: NetworkErrorKind.unknown,
    };
    for (final MapEntry(key: type, value: kind) in kinds.entries) {
      final ApiException e = ApiException.fromDio(
        DioException(requestOptions: options, type: type),
      );
      expect((e as NetworkError).kind, kind, reason: '$type');
      expect(e.status, isNull);
    }
    final ApiException unconfigured = ApiException.fromDio(
      DioException(
        requestOptions: options,
        error: const ServerNotConfiguredException(),
      ),
    );
    expect((unconfigured as NetworkError).kind, NetworkErrorKind.notConfigured);
  });

  test('toString names only the type, status and code', () {
    final ApiException e = ApiException.fromDio(
      _answer(401, {
        ..._problem(401, 'token_revoked'),
        'detail': 'secret-detail',
      }),
    );
    expect(e.toString(), 'TokenRevoked(401 token_revoked)');
  });
}
