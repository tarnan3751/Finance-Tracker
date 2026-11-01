/// The `Dio` every API call goes through, built for a flavor's `AppConfig`.
///
/// - The base URL is the server's ([ServerAddress]: the flavor's compiled URL, or the one
///   entered on the sign-in screen) with `/v1` appended (the dev default is
///   `http://10.0.2.2:8080/v1`, the development server as the emulator sees it), read for
///   every request, so an address entered while the app runs is used from the next one.
/// - **HTTPS in prod** (`PLAN.md` §12): a prod build given a non-`https` compiled URL
///   fails here, before any request, with a `StateError` (`bootstrap` refuses it earlier
///   still), and a request to a non-`https` entered one fails with a `StateError` too.
///   Dart's `HttpClient` ignores Android's network security config, so this is where the
///   rule holds for the app's own traffic.
/// - **Certificates are never relaxed**: the adapter is Dio's default with no
///   `createHttpClient` or `validateCertificate`, so the platform's checks apply in every
///   flavor, wrapped by [ResettableHttpClientAdapter] so its connections can be dropped
///   after a network change. Tests and the demo pass the fake server's adapter instead.
/// - With no server URL (a prod build without `FT_SERVER_URL`, before one is entered),
///   every request fails with `ServerNotConfiguredException`, which the problem mapper
///   reports as a `NetworkError` (`notConfigured`).
/// - Timeouts: 10 s to connect, 30 s to send a body, 30 s to receive. Every request carries
///   `User-Agent: finance-tracker/<version> (<flavor>)`.
/// - In dev only, each answer is logged on the `api` logger: method, path template,
///   status, duration and the server's `X-Request-Id`. Never a body, a header value other
///   than the request id, a query string or a token.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/server_address.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:logging/logging.dart';

/// The contract version this client is built against (`api/openapi.yaml` `info.version`;
/// a test holds them equal). `GET /health` reports the server's.
const String contractVersion = '0.7.0';

/// The `RequestOptions.extra` key naming the operation's path template, for the log.
const String pathTemplateKey = 'ft.path';

const String _startedKey = 'ft.started';

/// Where the version in the `User-Agent` comes from.
typedef VersionReader = Future<String> Function();

/// The Dio for [config]: on [adapter] when given (the fake server), else Dio's default;
/// at [baseUrl] when given, else at [address] (the flavor's server URL by default). See
/// the library comment.
Dio buildDio(
  AppConfig config, {
  HttpClientAdapter? adapter,
  Uri? baseUrl,
  ServerAddress? address,
  required VersionReader version,
}) {
  final ServerAddress server = baseUrl != null
      ? ServerAddress(compiled: baseUrl)
      : address ?? ServerAddress(compiled: config.serverBaseUrl);
  final Uri? compiled = server.compiled;
  if (compiled != null && !_allowed(config, compiled)) {
    throw StateError('The prod flavor needs an https server URL');
  }
  final Uri? initial = server.current;
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: initial == null
          ? 'https://unconfigured.invalid/v1'
          : apiBaseUrl(initial),
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.add(_ServerInterceptor(config, server));
  dio.interceptors.add(_UserAgentInterceptor(config.flavor, version));
  if (config.flavor == Flavor.dev) dio.interceptors.add(DevLogInterceptor());
  return dio;
}

bool _allowed(AppConfig config, Uri server) =>
    config.flavor != Flavor.prod || server.scheme == 'https';

/// Connections that can be dropped: [reset] makes the next request open a new one.
abstract interface class HttpConnections {
  /// Drops the idle connections; a request in flight finishes on its own.
  void reset();
}

/// Dio's default adapter, replaced by a new one on [reset]: the old one is closed without
/// force, so its idle connections go and a request in flight finishes, and every request
/// after it opens a new connection. Sync now and a returning network reset it
/// (`core/sync/sync_controller.dart`), so nothing a network change left behind in the
/// old connection pool is used again.
final class ResettableHttpClientAdapter
    implements HttpClientAdapter, HttpConnections {
  /// The adapter, starting on [create]'s (Dio's default by default).
  ResettableHttpClientAdapter([HttpClientAdapter Function()? create])
    : _create = create ?? HttpClientAdapter.new,
      _inner = (create ?? HttpClientAdapter.new)();

  final HttpClientAdapter Function() _create;
  HttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _inner.fetch(options, requestStream, cancelFuture);

  @override
  void reset() {
    final HttpClientAdapter old = _inner;
    _inner = _create();
    old.close();
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

/// The API base URL on [server]: its path with `/v1` appended.
String apiBaseUrl(Uri server) {
  final String path = server.path.endsWith('/')
      ? server.path.substring(0, server.path.length - 1)
      : server.path;
  return server.replace(path: '$path/v1').toString();
}

final class _UserAgentInterceptor extends Interceptor {
  _UserAgentInterceptor(this._flavor, this._version);

  final Flavor _flavor;
  final VersionReader _version;
  Future<String>? _userAgent;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String version;
    try {
      version = await (_userAgent ??= _version());
    } on Object {
      // A missing platform implementation must not fail the request.
      version = 'unknown';
    }
    options.headers['User-Agent'] =
        'finance-tracker/$version (${_flavor.name})';
    handler.next(options);
  }
}

/// Points each request at the server's current address, or refuses it: with
/// `ServerNotConfiguredException` while there is none, with a `StateError` for a
/// non-`https` one in prod.
final class _ServerInterceptor extends Interceptor {
  const _ServerInterceptor(this._config, this._server);

  final AppConfig _config;
  final ServerAddress _server;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Uri? server = _server.current;
    if (server == null) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const ServerNotConfiguredException(),
        ),
      );
      return;
    }
    if (!_allowed(_config, server)) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError('The prod flavor needs an https server URL'),
        ),
      );
      return;
    }
    options.baseUrl = apiBaseUrl(server);
    handler.next(options);
  }
}

/// The dev flavor's request log: one line per answer, with no body, token or query.
final class DevLogInterceptor extends Interceptor {
  final Logger _log = Logger('api');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _write(response.requestOptions, response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write(err.requestOptions, err.response);
    handler.next(err);
  }

  void _write(RequestOptions options, Response<dynamic>? response) {
    final Object? started = options.extra[_startedKey];
    final int millis = started is int
        ? DateTime.now().millisecondsSinceEpoch - started
        : -1;
    final Object path = options.extra[pathTemplateKey] as Object? ?? '?';
    _log.fine(
      '${options.method} $path ${response?.statusCode ?? 'no-response'} '
      '${millis}ms ${response?.headers.value('x-request-id') ?? '-'}',
    );
  }
}
