// The server check: a Finance Tracker server answers ok; no answer is unreachable; any
// other answer (a 404, a page that is not the health's JSON, a health that is not ok) is
// not a Finance Tracker server; and it asks only GET /v1/health, at the address given.
import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/features/auth/application/server_check.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/api/support/fake_api.dart';
import '../../../core/api/support/scripted_adapter.dart';

void main() {
  ServerCheck check(HttpClientAdapter adapter) => ServerCheck(
    config: AppConfig.prod(),
    clock: fakeClientClock,
    version: () async => '1.0.0',
    adapter: adapter,
  );
  final Uri server = Uri.parse('https://money.example.com/ft');

  test('a Finance Tracker server answers ok', () async {
    final List<Uri> asked = [];
    final ScriptedAdapter adapter = ScriptedAdapter((options, _) {
      asked.add(options.uri);
      return ok({'status': 'ok', 'version': contractVersion});
    });
    expect(await check(adapter).check(server), ServerCheckOutcome.ok);
    expect(asked, [Uri.parse('https://money.example.com/ft/v1/health')]);
  });

  test('no answer is unreachable', () async {
    final ScriptedAdapter adapter = ScriptedAdapter(
      (options, _) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'refused',
      ),
    );
    expect(await check(adapter).check(server), ServerCheckOutcome.unreachable);
  });

  test('any other answer is not a Finance Tracker server', () async {
    for (final Answer answer in [
      problem(404, 'not_found'),
      ok('<html>hello</html>'),
      ok({'status': 'degraded', 'version': contractVersion}),
      ok({'hello': 'world'}),
    ]) {
      expect(
        await check(ScriptedAdapter((_, _) => answer)).check(server),
        ServerCheckOutcome.notAServer,
        reason: '$answer',
      );
    }
  });
}
