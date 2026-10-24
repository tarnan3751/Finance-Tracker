// buildDio: the HTTPS rule, the base URL, timeouts, the User-Agent, no certificate
// override, a build with no server, and the dev-only request log.
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/scripted_adapter.dart';

final Clock _clock = FixedClock(DateTime.utc(2026, 10, 24, 15), tz.UTC);

Future<String> _version() async => '1.0.0';

void main() {
  test('prod refuses a server URL that is not https', () {
    expect(
      () => buildDio(
        AppConfig.prod(),
        baseUrl: Uri.parse('http://example.com'),
        version: _version,
      ),
      throwsStateError,
    );
    expect(
      buildDio(
        AppConfig.prod(),
        baseUrl: Uri.parse('https://api.example.com/'),
        version: _version,
      ).options.baseUrl,
      'https://api.example.com/v1',
    );
  });

  test('dev talks to the development server under /v1, with the timeouts', () {
    final Dio dio = buildDio(AppConfig.dev(), version: _version);
    expect(dio.options.baseUrl, 'http://10.0.2.2:8080/v1');
    expect(dio.options.connectTimeout, const Duration(seconds: 10));
    expect(dio.options.receiveTimeout, const Duration(seconds: 30));
  });

  test('the default adapter keeps the platform certificate checks', () {
    final Dio dio = buildDio(
      AppConfig.prod(),
      baseUrl: Uri.parse('https://api.example.com'),
      version: _version,
    );
    final HttpClientAdapter adapter = dio.httpClientAdapter;
    expect(adapter, isA<IOHttpClientAdapter>());
    adapter as IOHttpClientAdapter;
    expect(adapter.createHttpClient, isNull);
    expect(adapter.validateCertificate, isNull);
  });

  test('every request names the app, its version and its flavor', () async {
    final ScriptedAdapter adapter = ScriptedAdapter(
      (_, _) => ok({'status': 'ok', 'version': contractVersion}),
    );
    final HttpFinanceApi api = HttpFinanceApi(
      buildDio(AppConfig.dev(), adapter: adapter, version: _version),
      tokens: InMemoryTokenStore(),
      clock: _clock,
    );
    await api.getHealth();
    expect(
      adapter.requests.single.headers['User-Agent'],
      'finance-tracker/1.0.0 (dev)',
    );
  });

  test('a build with no server fails every call as notConfigured', () async {
    final HttpFinanceApi api = HttpFinanceApi(
      buildDio(AppConfig.prod(), version: _version),
      tokens: InMemoryTokenStore(),
      clock: _clock,
    );
    await expectLater(
      api.getHealth(),
      throwsA(
        isA<NetworkError>().having(
          (e) => e.kind,
          'kind',
          NetworkErrorKind.notConfigured,
        ),
      ),
    );
  });

  test(
    'dev logs method, template, status and request id; prod logs none',
    () async {
      final List<String> lines = [];
      Logger.root.level = Level.ALL;
      final sub = Logger('api').onRecord.listen((r) => lines.add(r.message));
      addTearDown(sub.cancel);
      final ScriptedAdapter adapter = ScriptedAdapter(
        (_, _) => (
          status: 200,
          body: {'status': 'ok', 'version': contractVersion},
          headers: const {'X-Request-Id': 'req-7'},
        ),
      );
      await HttpFinanceApi(
        buildDio(AppConfig.dev(), adapter: adapter, version: _version),
        tokens: InMemoryTokenStore(),
        clock: _clock,
      ).getHealth();
      expect(lines, hasLength(1));
      expect(lines.single, matches(RegExp(r'^GET /health 200 \d+ms req-7$')));

      lines.clear();
      await HttpFinanceApi(
        buildDio(
          AppConfig.prod(),
          adapter: adapter,
          baseUrl: Uri.parse('https://api.example.com'),
          version: _version,
        ),
        tokens: InMemoryTokenStore(),
        clock: _clock,
      ).getHealth();
      expect(lines, isEmpty);
    },
  );
}
