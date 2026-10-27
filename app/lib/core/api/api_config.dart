/// The `Dio` every API call goes through, built for a flavor's `AppConfig`.
///
/// - The base URL is the flavor's server URL with `/v1` appended (the dev default is
///   `http://10.0.2.2:8080/v1`, the development server as the emulator sees it).
/// - **HTTPS in prod** (`PLAN.md` §12): a prod build given a non-`https` URL fails here,
///   before any request, with a `StateError`; `bootstrap` refuses it earlier still. Dart's
///   `HttpClient` ignores Android's network security config, so this is where the rule
///   holds for the app's own traffic.
/// - **Certificates are never relaxed**: the adapter is Dio's default with no
///   `createHttpClient` or `validateCertificate`, so the platform's checks apply in every
///   flavor. Tests and the demo pass the fake server's adapter instead.
/// - A build with no server URL (a prod build without `FT_SERVER_URL`) gets a Dio whose
///   every request fails with `ServerNotConfiguredException`, which the problem mapper
///   reports as a `NetworkError` (`notConfigured`).
/// - Timeouts: 10 s to connect, 30 s to receive. Every request carries
///   `User-Agent: finance-tracker/<version> (<flavor>)`.
/// - In dev only, each answer is logged on the `api` logger: method, path template,
///   status, duration and the server's `X-Request-Id`. Never a body, a header value other
///   than the request id, a query string or a token.
library;

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:logging/logging.dart';

/// The contract version this client is built against (`api/openapi.yaml` `info.version`;
/// a test holds them equal). `GET /health` reports the server's.
const String contractVersion = '0.4.0';

/// The `RequestOptions.extra` key naming the operation's path template, for the log.
const String pathTemplateKey = 'ft.path';

const String _startedKey = 'ft.started';

/// Where the version in the `User-Agent` comes from.
typedef VersionReader = Future<String> Function();

/// The Dio for [config]: on [adapter] when given (the fake server), else Dio's default;
/// at [baseUrl] when given, else the flavor's server URL. See the library comment.
Dio buildDio(
  AppConfig config, {
  HttpClientAdapter? adapter,
  Uri? baseUrl,
  required VersionReader version,
}) {
  final Uri? server = baseUrl ?? config.serverBaseUrl;
  if (server != null && config.flavor == Flavor.prod) {
    if (server.scheme != 'https') {
      throw StateError('The prod flavor needs an https server URL');
    }
  }
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: server == null
          ? 'https://unconfigured.invalid/v1'
          : apiBaseUrl(server),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  dio.interceptors.add(_UserAgentInterceptor(config.flavor, version));
  if (server == null) dio.interceptors.add(const _NotConfiguredInterceptor());
  if (config.flavor == Flavor.dev) dio.interceptors.add(DevLogInterceptor());
  return dio;
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

final class _NotConfiguredInterceptor extends Interceptor {
  const _NotConfiguredInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      handler.reject(
        DioException(
          requestOptions: options,
          error: const ServerNotConfiguredException(),
        ),
      );
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
