/// One operation of the contract and the handler that serves it (`docs/reference/server.md`,
/// **Routes**).
library;

import 'package:finance_tracker_server/src/auth/access_tokens.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A handler of one operation.
typedef ApiHandler = Future<Response> Function(ApiRequest request);

/// One row of the route table: the contract's `operationId`, method and path template
/// (`/plaid/items/{item_id}`), whether it takes a bearer token, whether the per-IP rate
/// limit applies, and the handler.
final class ApiRoute {
  /// A route.
  const ApiRoute(
    this.operationId,
    this.method,
    this.path,
    this.handler, {
    this.authenticated = true,
    this.rateLimited = false,
  });

  /// The contract's `operationId`.
  final String operationId;

  /// The lower-case HTTP method.
  final String method;

  /// The contract's path template, without the `/v1` prefix.
  final String path;

  /// The handler.
  final ApiHandler handler;

  /// Whether the operation requires `bearerAuth`.
  final bool authenticated;

  /// Whether the per-operation, per-IP token bucket applies.
  final bool rateLimited;

  /// [path] in `shelf_router`'s syntax (`<item_id>`).
  String get routerPath =>
      path.replaceAllMapped(RegExp(r'\{([a-z_]+)\}'), (m) => '<${m[1]}>');
}

/// A request as a handler sees it: the shelf request, its path parameters and, for an
/// authenticated route, the caller.
final class ApiRequest {
  /// A request.
  ApiRequest(this.raw, this._claims);

  /// The shelf request.
  final Request raw;

  final AccessClaims? _claims;

  /// The path parameter [name].
  String param(String name) => raw.params[name]!;

  /// The authenticated user.
  String get userId => _claims!.userId;

  /// The authenticated device.
  String get deviceId => _claims!.deviceId;

  /// The JSON object body, at most [limit] bytes.
  Future<Map<String, Object?>> json({int limit = defaultBodyLimit}) =>
      readJsonObject(raw, limit: limit);
}
