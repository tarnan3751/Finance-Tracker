/// The contract's error model: RFC 9457 problem details (`docs/reference/api.md`,
/// **Errors**).
///
/// Handlers throw a [ProblemException] or a [ValidationException]; the pipeline's mapper
/// turns it into an `application/problem+json` response. Anything else thrown becomes a
/// 500 `internal`.
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';

/// The contract's `ProblemCode`, with the title each is answered with.
enum ProblemCode {
  validationFailed('validation_failed', 'Validation failed'),
  invalidCredentials('invalid_credentials', 'Invalid credentials'),
  emailTaken('email_taken', 'Email already registered'),
  tokenExpired('token_expired', 'Token expired'),
  tokenRevoked('token_revoked', 'Token revoked'),
  notFound('not_found', 'Not found'),
  conflict('conflict', 'Conflict'),
  itemLoginRequired('item_login_required', 'Item login required'),
  plaidError('plaid_error', 'Plaid error'),
  rateLimited('rate_limited', 'Too many requests'),
  internal('internal', 'Internal error'),
  syncCursorInvalid('sync_cursor_invalid', 'Sync cursor invalid'),
  webhookUnverified('webhook_unverified', 'Webhook unverified');

  const ProblemCode(this.wire, this.title);

  /// The snake_case value on the wire.
  final String wire;

  /// The problem's `title`.
  final String title;
}

/// An error answered as a `Problem` with [status] and [code].
final class ProblemException implements Exception {
  /// A problem; [detail] is for people, never parsed by a client.
  const ProblemException(
    this.status,
    this.code, {
    this.detail,
    this.headers = const {},
  });

  /// 401 with [code].
  const ProblemException.unauthorized(ProblemCode code, {String? detail})
    : this(401, code, detail: detail);

  /// 404 `not_found`.
  const ProblemException.notFound([String? detail])
    : this(404, ProblemCode.notFound, detail: detail);

  /// The HTTP status.
  final int status;

  /// The machine-readable reason.
  final ProblemCode code;

  /// The optional `detail`.
  final String? detail;

  /// Extra response headers (`Retry-After`).
  final Map<String, String> headers;

  @override
  String toString() => 'ProblemException($status ${code.wire}: $detail)';
}

/// One offending field of a request.
final class FieldError {
  /// [field] is a path into the request (`password`, `entries[3].hlc`, a query
  /// parameter's name, or the empty string for the body as a whole).
  const FieldError(this.field, this.message);

  /// Where.
  final String field;

  /// What is wrong.
  final String message;

  /// The contract's `FieldError`.
  Map<String, Object?> toJson() => {'field': field, 'message': message};

  @override
  String toString() => '$field: $message';
}

/// A request that does not match the contract, answered as a 400 `ValidationProblem`.
final class ValidationException implements Exception {
  /// The [errors], at least one.
  ValidationException(this.errors) : assert(errors.isNotEmpty);

  /// A single error.
  ValidationException.single(String field, String message)
    : errors = [FieldError(field, message)];

  /// Every offending field.
  final List<FieldError> errors;

  @override
  String toString() => 'ValidationException(${errors.join('; ')})';
}

/// The `application/problem+json` response for [status] and [code].
Response problemResponse(
  int status,
  ProblemCode code, {
  String? detail,
  String? instance,
  List<FieldError>? errors,
  Map<String, String> headers = const {},
}) => Response(
  status,
  body: jsonEncode({
    'type': 'urn:finance-tracker:problem:${code.wire}',
    'title': code.title,
    'status': status,
    'code': code.wire,
    'detail': ?detail,
    'instance': ?instance,
    if (errors != null) 'errors': [for (final e in errors) e.toJson()],
  }),
  headers: {
    'content-type': 'application/problem+json',
    if (status == 401) 'www-authenticate': 'Bearer',
    ...headers,
  },
);
