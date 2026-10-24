/// The errors the API layer throws: every non-2xx answer and every failure to get one,
/// mapped from the contract's problem responses (`docs/reference/api.md`, **Errors**).
///
/// A caller branches on the type, never on a message. [ApiException.toString] names only
/// the type, the status and the code: no header, body, token or address ever reaches it.
library;

import 'dart:convert';

import 'package:dio/dio.dart';

/// Why a request got no answer.
enum NetworkErrorKind {
  /// The connection could not be made or broke.
  connection,

  /// A connect, send or receive timeout.
  timeout,

  /// The request was cancelled.
  cancelled,

  /// The server's certificate was refused.
  badCertificate,

  /// The build has no server URL (a prod build without `FT_SERVER_URL`).
  notConfigured,

  /// Anything else that left no response.
  unknown,
}

/// One field's problem in a `validation_failed` answer.
final class FieldError {
  const FieldError(this.field, this.message);

  /// The request field, as a JSON path (`password`, `entries[3].hlc`), or empty.
  final String field;

  /// The server's description, for logs; the UI shows its own text.
  final String message;
}

/// A failed API call.
sealed class ApiException implements Exception {
  const ApiException({this.status, this.code});

  /// The HTTP status, or null when there was no answer.
  final int? status;

  /// The problem's `code`, or null when there was none.
  final String? code;

  /// The exception for [error], a failure of a request made through Dio.
  factory ApiException.fromDio(DioException error) {
    final Response<Object?>? response = error.response;
    if (response == null) {
      return NetworkError(switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => NetworkErrorKind.timeout,
        DioExceptionType.cancel => NetworkErrorKind.cancelled,
        DioExceptionType.badCertificate => NetworkErrorKind.badCertificate,
        DioExceptionType.connectionError => NetworkErrorKind.connection,
        DioExceptionType.badResponse ||
        DioExceptionType.unknown => switch (error.error) {
          ServerNotConfiguredException() => NetworkErrorKind.notConfigured,
          _ => NetworkErrorKind.unknown,
        },
      });
    }
    final int? status = response.statusCode;
    if (status == null || (status >= 200 && status < 300)) {
      // A 2xx whose body the generated client could not read.
      return ServerError(status: status);
    }
    return fromProblem(
      status,
      _decoded(response.data),
      retryAfter: response.headers.value('retry-after'),
      since: error.requestOptions.queryParameters['since'],
    );
  }

  /// The exception for a [status] answer with [body], which should be a problem object.
  /// [retryAfter] is the `Retry-After` header; [since] the request's `since` parameter.
  static ApiException fromProblem(
    int status,
    Object? body, {
    String? retryAfter,
    Object? since,
  }) {
    final Object? code = body is Map ? body['code'] : null;
    if (code is! String) return ServerError(status: status);
    return switch (code) {
      'validation_failed' => ValidationFailed(_fieldErrors(body)),
      'invalid_credentials' => InvalidCredentials(status: status),
      'email_taken' => EmailTaken(status: status),
      'token_expired' => TokenExpired(status: status),
      'token_revoked' => TokenRevoked(status: status),
      'not_found' => NotFound(status: status),
      'conflict' => Conflict(status: status),
      'item_login_required' => ItemLoginRequired(status: status),
      'plaid_error' => PlaidError(status: status),
      'rate_limited' => RateLimited(
        retryAfter: switch (int.tryParse(retryAfter?.trim() ?? '')) {
          final int seconds when seconds >= 0 => Duration(seconds: seconds),
          _ => null,
        },
        status: status,
      ),
      'sync_cursor_invalid' => SyncCursorInvalid(
        since: switch (since) {
          final int value => value,
          final String value => int.tryParse(value),
          _ => null,
        },
        status: status,
      ),
      // internal, webhook_unverified (the app never receives webhooks) and any code
      // this build does not know.
      _ => ServerError(status: status, code: code),
    };
  }

  /// A body read as bytes (an operation whose success is an image) is the problem's
  /// JSON text; any other body is already decoded.
  static Object? _decoded(Object? data) {
    if (data is! List<int>) return data;
    try {
      return jsonDecode(utf8.decode(data));
    } on FormatException {
      return null;
    }
  }

  static List<FieldError> _fieldErrors(Object? body) {
    final Object? errors = body is Map ? body['errors'] : null;
    if (errors is! List) return const [];
    return [
      for (final Object? e in errors)
        if (e is Map && e['field'] is String && e['message'] is String)
          FieldError(e['field'] as String, e['message'] as String),
    ];
  }

  @override
  String toString() => '$runtimeType(${status ?? '-'} ${code ?? '-'})';
}

/// 400 `validation_failed`: the request does not match the contract.
final class ValidationFailed extends ApiException {
  const ValidationFailed(this.errors)
    : super(status: 400, code: 'validation_failed');

  /// The fields at fault.
  final List<FieldError> errors;
}

/// 401 `invalid_credentials`: a wrong email or password, or a missing or malformed token.
final class InvalidCredentials extends ApiException {
  const InvalidCredentials({super.status = 401})
    : super(code: 'invalid_credentials');
}

/// 409 `email_taken`: registration with an email that already has an account.
final class EmailTaken extends ApiException {
  const EmailTaken({super.status = 409}) : super(code: 'email_taken');
}

/// 401 `token_expired`: the access token (or, on refresh, the refresh token) expired.
final class TokenExpired extends ApiException {
  const TokenExpired({super.status = 401}) : super(code: 'token_expired');
}

/// 401 `token_revoked`: the session was ended (logout, reuse detection, device removed).
final class TokenRevoked extends ApiException {
  const TokenRevoked({super.status = 401}) : super(code: 'token_revoked');
}

/// 404 `not_found`.
final class NotFound extends ApiException {
  const NotFound({super.status = 404}) : super(code: 'not_found');
}

/// 409 `conflict`.
final class Conflict extends ApiException {
  const Conflict({super.status = 409}) : super(code: 'conflict');
}

/// 409 `item_login_required`: the Item needs Link in update mode.
final class ItemLoginRequired extends ApiException {
  const ItemLoginRequired({super.status = 409})
    : super(code: 'item_login_required');
}

/// 502 `plaid_error`: Plaid failed or refused the server's call.
final class PlaidError extends ApiException {
  const PlaidError({super.status = 502}) : super(code: 'plaid_error');
}

/// 429 `rate_limited`, with the server's `Retry-After` when it gave one.
final class RateLimited extends ApiException {
  const RateLimited({this.retryAfter, super.status = 429})
    : super(code: 'rate_limited');

  /// How long to wait, or null when the server did not say.
  final Duration? retryAfter;
}

/// 409 `sync_cursor_invalid`: a `since` past the server's end; reset to 0 and read again.
final class SyncCursorInvalid extends ApiException {
  const SyncCursorInvalid({this.since, super.status = 409})
    : super(code: 'sync_cursor_invalid');

  /// The `since` the request sent.
  final int? since;
}

/// A server failure: 500 `internal`, a code this build does not know, or an answer the
/// client cannot read.
final class ServerError extends ApiException {
  const ServerError({super.status, super.code});
}

/// No answer at all.
final class NetworkError extends ApiException {
  const NetworkError(this.kind);

  /// Why.
  final NetworkErrorKind kind;

  @override
  String toString() => 'NetworkError(${kind.name})';
}

/// The error a request fails with when the build has no server URL; mapped to
/// [NetworkError] with [NetworkErrorKind.notConfigured].
final class ServerNotConfiguredException implements Exception {
  const ServerNotConfiguredException();

  @override
  String toString() => 'ServerNotConfiguredException';
}
