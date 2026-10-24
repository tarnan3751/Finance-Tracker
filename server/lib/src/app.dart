/// The server assembled: services, the route table and the pipeline
/// (`docs/reference/server.md`, **Request pipeline**).
///
/// Outermost to innermost: [requestLog] (a request id and one log line), [problemMapper]
/// (every error becomes a `Problem`), the router (an unknown path or method is 404
/// `not_found`), then per route the rate limiter, bearer authentication and the handler,
/// which reads its own body under its size limit.
library;

import 'package:finance_tracker_server/src/auth/access_tokens.dart';
import 'package:finance_tracker_server/src/auth/auth_routes.dart';
import 'package:finance_tracker_server/src/auth/auth_service.dart';
import 'package:finance_tracker_server/src/auth/password_hasher.dart';
import 'package:finance_tracker_server/src/config.dart';
import 'package:finance_tracker_server/src/contract_version.dart';
import 'package:finance_tracker_server/src/data/data_routes.dart';
import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/api_route.dart';
import 'package:finance_tracker_server/src/http/pipeline.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/rate_limiter.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';
import 'package:finance_tracker_server/src/plaid/plaid_routes.dart';
import 'package:finance_tracker_server/src/plaid/token_cipher.dart';
import 'package:finance_tracker_server/src/sync/change_log_relay.dart';
import 'package:finance_tracker_server/src/sync/sync_routes.dart';
import 'package:finance_tracker_server/src/users/user_routes.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// The server: its services, routes and handler.
final class ServerApp {
  /// A server over [db] and [plaid] configured by [config]. [now] is the clock (UTC),
  /// [clientIp] keys the rate limiter, [delay] waits between Plaid retries.
  ServerApp({
    required this.config,
    required this.db,
    required this.plaid,
    DateTime Function()? now,
    String Function(Request)? clientIp,
    Future<void> Function(Duration)? delay,
  }) : now = now ?? DateTime.now,
       clientIp = clientIp ?? socketClientIp {
    auth = AuthService(
      db: db,
      hasher: PasswordHasher(config.argon2),
      accessTokens: AccessTokens(
        secret: config.jwtSecret,
        previousSecret: config.jwtSecretPrevious,
        now: this.now,
      ),
      now: this.now,
    );
    items = ItemService(
      db: db,
      plaid: plaid,
      cipher: TokenCipher(config.tokenEncryptionKey),
      now: this.now,
      delay: delay,
    );
    limiter = RateLimiter(now: this.now);
    routes = [
      ...authRoutes(auth),
      ...userRoutes(db: db, auth: auth),
      ...plaidRoutes(items),
      ...dataRoutes(db),
      ...syncRoutes(ChangeLogRelay(db: db, now: this.now)),
      ApiRoute(
        'getHealth',
        'get',
        '/health',
        (_) async => jsonResponse({'status': 'ok', 'version': contractVersion}),
        authenticated: false,
      ),
    ];
  }

  /// The configuration.
  final ServerConfig config;

  /// The database.
  final AppDatabase db;

  /// The Plaid client.
  final PlaidClient plaid;

  /// The server's clock.
  final DateTime Function() now;

  /// The rate limiter's view of the caller's address.
  final String Function(Request) clientIp;

  /// Authentication.
  late final AuthService auth;

  /// Plaid Items.
  late final ItemService items;

  /// The token bucket.
  late final RateLimiter limiter;

  /// Every operation of the contract, one route each.
  late final List<ApiRoute> routes;

  final Logger _log = Logger('http');

  /// The handler serving every route under `/v1`.
  Handler get handler {
    final router = Router(
      notFoundHandler: (_) => problemResponse(
        404,
        ProblemCode.notFound,
        detail: 'No such operation',
      ),
    );
    for (final route in routes) {
      router.add(
        route.method.toUpperCase(),
        '/v1${route.routerPath}',
        (Request request) => _serve(route, request),
      );
    }
    return const Pipeline()
        .addMiddleware(requestLog(_log))
        .addMiddleware(problemMapper(_log))
        .addHandler(router.call);
  }

  Future<Response> _serve(ApiRoute route, Request request) async {
    final context = requestContextOf(request)..route = route.path;
    if (route.rateLimited) {
      final wait = limiter.take('${route.operationId}|${clientIp(request)}');
      if (wait != null) {
        throw ProblemException(
          429,
          ProblemCode.rateLimited,
          detail: 'Too many requests; retry in $wait s',
          headers: {'retry-after': '$wait'},
        );
      }
    }
    AccessClaims? claims;
    if (route.authenticated) {
      claims = await auth.authenticate(request.headers['authorization']);
      context
        ..userId = claims.userId
        ..deviceId = claims.deviceId;
    }
    return route.handler(ApiRequest(request, claims));
  }
}
