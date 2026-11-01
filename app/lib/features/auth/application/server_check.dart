/// The check an entered server URL passes before the first request goes to it
/// (`docs/reference/onboarding.md`, **The server URL**): `GET /v1/health` on a client of
/// its own, which answers whether the address is a Spendthrift server, cannot be
/// reached, or answered as something else.
library;

import 'package:dio/dio.dart';
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/api_models.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_check.g.dart';

final Logger _log = Logger('auth');

/// What the check found.
enum ServerCheckOutcome {
  /// A Spendthrift server answered.
  ok,

  /// Nothing answered: no network, no such host, nothing listening, or too slow.
  unreachable,

  /// Something answered, but not as a Spendthrift server.
  notAServer,
}

/// Checks a server URL with `GET /v1/health`.
final class ServerCheck {
  /// The check for [config], over [adapter] when given (the tests'), else Dio's default.
  ServerCheck({
    required this.config,
    required this.clock,
    required this.version,
    this.adapter,
  });

  final AppConfig config;
  final Clock clock;
  final VersionReader version;
  final HttpClientAdapter? adapter;

  /// What [server] answers.
  Future<ServerCheckOutcome> check(Uri server) async {
    final HttpFinanceApi api = HttpFinanceApi(
      buildDio(
        config,
        adapter: adapter ?? HttpClientAdapter(),
        baseUrl: server,
        version: version,
      ),
      tokens: InMemoryTokenStore(),
      clock: clock,
    );
    try {
      final Health health = await api.getHealth();
      return health.status == 'ok'
          ? ServerCheckOutcome.ok
          : ServerCheckOutcome.notAServer;
    } on NetworkError {
      return ServerCheckOutcome.unreachable;
    } on Object catch (e) {
      // Only the type: the answer may hold anything.
      _log.info('the server check was answered with ${e.runtimeType}');
      return ServerCheckOutcome.notAServer;
    } finally {
      await api.close();
    }
  }
}

/// The server check for the running configuration.
@Riverpod(keepAlive: true)
ServerCheck serverCheck(Ref ref) => ServerCheck(
  config: ref.watch(appConfigProvider),
  clock: ref.watch(clockProvider),
  version: () => ref.read(appVersionProvider.future),
);
