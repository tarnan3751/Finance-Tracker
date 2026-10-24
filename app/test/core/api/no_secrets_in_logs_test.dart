// Nothing secret reaches a log: a whole auth flow in the dev flavor (whose request log is
// on), against the fake server, with every record of every logger captured, holds no
// password, email, access token or refresh token, in a message or in an error.
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'support/fake_api.dart';

void main() {
  test('an auth flow logs no secret', () async {
    final List<String> lines = [];
    Logger.root.level = Level.ALL;
    final sub = Logger.root.onRecord.listen(
      (r) => lines.add('${r.loggerName} ${r.message} ${r.error ?? ''}'),
    );
    addTearDown(sub.cancel);

    final FakeServer server = newFakeServer();
    final InMemoryTokenStore store = InMemoryTokenStore();
    final HttpFinanceApi api = HttpFinanceApi(
      buildDio(
        AppConfig.dev(),
        adapter: server.adapter,
        baseUrl: FakeServer.baseUrl,
        version: () async => '1.0.0',
      ),
      tokens: store,
      clock: fakeClientClock,
    );
    const String email = 'secret.person@example.com';
    const String password = 'hunter2-hunter2';
    final List<String> secrets = [email, password];

    final AuthResult tokens = await api.register(
      email: email,
      password: password,
      deviceName: 'Pixel 6',
    );
    secrets.addAll([tokens.accessToken, tokens.refreshToken]);
    store.session = Session(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      accessExpiresAt: fakeNow,
      user: await api.getMe(accessToken: tokens.accessToken),
      device: tokens.device,
    );
    server.advanceClock(const Duration(minutes: 16));
    await api.getMe();
    secrets.addAll([store.session!.accessToken, store.session!.refreshToken]);
    await expectLater(
      api.login(email: email, password: 'wrong-password', deviceName: 'x'),
      throwsA(isA<InvalidCredentials>()),
    );
    await api.logout(store.session!.refreshToken);

    expect(lines.where((l) => l.startsWith('api ')), isNotEmpty);
    for (final String line in lines) {
      for (final String secret in secrets) {
        expect(line, isNot(contains(secret)));
      }
      expect(line, isNot(contains('wrong-password')));
    }
  });
}
