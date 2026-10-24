/// The Finance Tracker development server's request handler.
///
/// Phase 0 skeleton: one route, `GET /v1/health`. Phase 2 adds authentication, sync, the
/// Plaid proxy and the webhook receiver behind `api/openapi.yaml`. The handler is built
/// here, apart from `bin/server.dart`, so tests exercise it without opening a socket.
library;

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Builds the handler that serves every route of the API under `/v1`.
Handler buildHandler() {
  final router = Router()..get('/v1/health', _health);
  return router.call;
}

Response _health(Request request) => Response.ok(
  jsonEncode(const {'status': 'ok'}),
  headers: const {'content-type': 'application/json'},
);
