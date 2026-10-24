/// The middleware every request passes through (`docs/reference/server.md`, **Request
/// pipeline**): a [RequestContext], one log line, and the problem mapper.
library;

import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/ids.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

const _contextKey = 'finance_tracker.context';

/// What the layers learn about one request, for its log line.
final class RequestContext {
  /// A context for a new request.
  RequestContext(this.requestId);

  /// A uuid, also sent back as `X-Request-Id` and used as a 500's `instance`.
  final String requestId;

  /// The contract path template the router matched (`/plaid/items/{item_id}`).
  String? route;

  /// The authenticated user, once the bearer layer has resolved it.
  String? userId;

  /// The authenticated device, likewise.
  String? deviceId;
}

/// The [RequestContext] of [request].
RequestContext requestContextOf(Request request) =>
    request.context[_contextKey]! as RequestContext;

/// Gives each request a [RequestContext] and logs one `request` line after it is answered:
/// method, route template, status, duration and the user and device ids. Never the path's
/// values, the query, a header or a body.
Middleware requestLog(Logger log) =>
    (inner) => (request) async {
      final context = RequestContext(newId());
      final stopwatch = Stopwatch()..start();
      final response = await inner(
        request.change(context: {_contextKey: context}),
      );
      log.info(
        LogEvent('request', {
          'request_id': context.requestId,
          'method': request.method,
          'route': context.route,
          'status': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'user_id': context.userId,
          'device_id': context.deviceId,
        }),
      );
      return response.change(headers: {'x-request-id': context.requestId});
    };

/// Turns every [ProblemException] and [ValidationException] into its problem response, and
/// anything else into a 500 `internal` whose `instance` is the request id; the error's
/// type (`errorFields`, never its `toString()`) and its stack go to the log only.
Middleware problemMapper(Logger log) =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on ProblemException catch (e) {
        return problemResponse(
          e.status,
          e.code,
          detail: e.detail,
          headers: e.headers,
        );
      } on ValidationException catch (e) {
        return problemResponse(
          400,
          ProblemCode.validationFailed,
          errors: e.errors,
        );
      } catch (error, stack) {
        final id = requestContextOf(request).requestId;
        log.severe(
          LogEvent('unhandled_error', {'request_id': id}),
          error,
          stack,
        );
        return problemResponse(500, ProblemCode.internal, instance: id);
      }
    };
