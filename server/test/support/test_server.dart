// The server under test: a ServerApp over an in-memory database, a Plaid client (the
// fake by default, or another such as the HTTP client over recorded fixtures), a
// controllable clock and tiny Argon2 parameters, called through its shelf handler with
// no socket. Every call is checked against the contract: the request body with
// conformsToRequest (unless the test sends an invalid one on purpose), the response with
// conformsToResponse for the matched operation and status (strict), and its content type.
// An image/png answer's body is its bytes.
import 'dart:convert';
import 'dart:io';

import 'package:contract_test/contract_test.dart';
import 'package:finance_tracker_server/server.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// `api/openapi.yaml`; `dart test` runs in `server/`.
final OpenApiDocument contract = OpenApiDocument.load(
  File(p.join('..', 'api', 'openapi.yaml')),
);

/// A configuration for tests: fixed keys, tiny Argon2 parameters, no polling.
final ServerConfig testConfig = ServerConfig(
  jwtSecret: List.filled(32, 7),
  tokenEncryptionKey: List.filled(32, 9),
  argon2: const Argon2Parameters(memoryKib: 64, iterations: 1, parallelism: 1),
  // Tests run ticks themselves; nothing polls on its own.
  pollInterval: Duration.zero,
);

/// A clock the test moves.
final class TestClock {
  /// A clock at [start].
  TestClock([DateTime? start])
    : value = start ?? DateTime.utc(2026, 10, 24, 9, 30);

  /// The current time.
  DateTime value;

  /// The time, as the server reads it.
  DateTime call() => value;

  /// Moves the clock by [by].
  void advance(Duration by) => value = value.add(by);
}

/// A response, decoded.
final class TestResponse {
  TestResponse(this.status, this.headers, this.body);

  /// The status.
  final int status;

  /// The headers.
  final Map<String, String> headers;

  /// The decoded JSON body, the bytes of an image body, or null for an empty one.
  final Object? body;

  /// The body as an object.
  Map<String, Object?> get json => body! as Map<String, Object?>;

  /// The body as an array.
  List<Object?> get list => body! as List<Object?>;

  /// A problem's `code`.
  String? get code => body is Map ? json['code'] as String? : null;

  @override
  String toString() => 'TestResponse($status, $body)';
}

/// A signed-in device.
final class Session {
  Session(this.tokens);

  /// The `AuthTokens` JSON.
  final Map<String, Object?> tokens;

  /// The access token.
  String get access => tokens['access_token']! as String;

  /// The refresh token.
  String get refresh => tokens['refresh_token']! as String;

  /// The device id.
  String get deviceId =>
      (tokens['device']! as Map<String, Object?>)['id']! as String;

  /// The user id.
  String get userId =>
      (tokens['device']! as Map<String, Object?>)['user_id']! as String;
}

final _templates = [
  for (final op in contract.operations)
    (
      method: op.method,
      path: op.path,
      pattern: RegExp(
        '^${op.path.replaceAll(RegExp(r'\{[a-z0-9_]+\}'), '[^/]+')}\$',
      ),
    ),
];

/// The contract template [path] (without `/v1` and the query) matches for [method].
String? templateFor(String method, String path) {
  for (final t in _templates) {
    if (t.method == method && t.pattern.hasMatch(path)) return t.path;
  }
  return null;
}

/// The server under test.
final class TestServer {
  TestServer._(this.app, this.client, this.clock);

  /// A fresh server; [config] defaults to [testConfig], [plaid] (given the clock) to the
  /// fake client.
  static Future<TestServer> start({
    ServerConfig? config,
    PlaidClient Function(TestClock clock)? plaid,
  }) async {
    final clock = TestClock();
    final client =
        plaid?.call(clock) ?? await FakePlaidClient.load(now: clock.call);
    late final TestServer server;
    final receipts = Directory.systemTemp.createTempSync('ft-receipts-');
    addTearDown(() => receipts.deleteSync(recursive: true));
    server = TestServer._(
      ServerApp(
        receiptsDirectory: receipts,
        config: config ?? testConfig,
        db: AppDatabase.inMemory(),
        plaid: client,
        now: clock.call,
        clientIp: (r) => r.headers['x-test-ip'] ?? '10.0.0.1',
        delay: (wait) async => server.onDelay?.call(wait),
      ),
      client,
      clock,
    );
    addTearDown(server.app.db.close);
    return server;
  }

  /// The app.
  final ServerApp app;

  /// The Plaid client.
  final PlaidClient client;

  /// The Plaid client, when it is the fake.
  FakePlaidClient get plaid => client as FakePlaidClient;

  /// The clock.
  final TestClock clock;

  /// Runs instead of each wait between Plaid retries (which are otherwise instant), so a
  /// test can interleave requests with a retry in progress.
  Future<void> Function(Duration wait)? onDelay;

  late final Handler _handler = app.handler;

  /// Calls `method path` (a `/v1`-relative path, query allowed) with [body] as JSON, or
  /// [rawBody] verbatim, or [bytes] (an image body). [validRequest] false skips the
  /// request-body check.
  Future<TestResponse> call(
    String method,
    String path, {
    Object? body,
    String? rawBody,
    List<int>? bytes,
    String? token,
    String contentType = 'application/json',
    Map<String, String> headers = const {},
    bool validRequest = true,
  }) async {
    final uri = Uri.parse('http://localhost/v1$path');
    final template = templateFor(method, uri.path.substring(3));
    if (body != null && validRequest && template != null) {
      expect(body, conformsToRequest(contract, template, method));
    }
    final text = rawBody ?? (body == null ? null : jsonEncode(body));
    final Object? sent = bytes ?? text;
    final response = await _handler(
      Request(
        method.toUpperCase(),
        uri,
        body: sent,
        headers: {
          if (sent != null) 'content-type': contentType,
          if (token != null) 'authorization': 'Bearer $token',
          ...headers,
        },
      ),
    );
    final answer = [
      for (final chunk in await response.read().toList()) ...chunk,
    ];
    final image =
        response.headers['content-type']?.startsWith('image/') ?? false;
    final Object? decoded = image
        ? answer
        : answer.isEmpty
        ? null
        : jsonDecode(utf8.decode(answer));
    final result = TestResponse(response.statusCode, response.headers, decoded);
    if (template == null) {
      // A path or method outside the contract can only be the router's 404.
      expect(
        result.status,
        404,
        reason: '$method $path is not in the contract',
      );
    } else {
      expect(
        decoded,
        conformsToResponse(contract, template, method, response.statusCode),
        reason: '$method $path answered $result',
      );
      final type = response.headers['content-type'];
      if (response.statusCode >= 400) {
        expect(type, 'application/problem+json');
      } else if (decoded != null) {
        expect(
          contract.responseMediaTypes(template, method, response.statusCode),
          contains(type),
        );
      }
    }
    return result;
  }

  /// Registers [email] and returns its first device.
  Future<Session> register([
    String email = 'ada@example.com',
    String password = 'correct horse battery',
    String device = 'Pixel 8',
  ]) async {
    final r = await call(
      'post',
      '/auth/register',
      body: {'email': email, 'password': password, 'device_name': device},
    );
    expect(r.status, 201, reason: '$r');
    return Session(r.json);
  }

  /// Logs [email] in on a new device.
  Future<Session> login([
    String email = 'ada@example.com',
    String password = 'correct horse battery',
    String device = 'Pixel Tablet',
  ]) async {
    final r = await call(
      'post',
      '/auth/login',
      body: {'email': email, 'password': password, 'device_name': device},
    );
    expect(r.status, 200, reason: '$r');
    return Session(r.json);
  }

  /// The rows of [table] that belong to [userId] (by a `user_id` column, or for refresh
  /// tokens, through their device).
  Future<int> rowsOf(String table, String userId) => app.db.read((tx) {
    final columns = tx
        .select('PRAGMA table_info($table)')
        .map((r) => r['name'])
        .toSet();
    if (columns.contains('user_id')) {
      return tx.first('SELECT COUNT(*) AS n FROM $table WHERE user_id = ?', [
            userId,
          ])!['n']
          as int;
    }
    if (table == 'refresh_tokens') {
      return tx.first(
            'SELECT COUNT(*) AS n FROM refresh_tokens t '
            'JOIN devices d ON d.id = t.device_id WHERE d.user_id = ?',
            [userId],
          )!['n']
          as int;
    }
    if (table == 'users') {
      return tx.first('SELECT COUNT(*) AS n FROM users WHERE id = ?', [
            userId,
          ])!['n']
          as int;
    }
    return 0;
  });
}
