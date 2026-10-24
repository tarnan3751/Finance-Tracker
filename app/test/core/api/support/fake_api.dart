// The real client stack (buildDio, HttpFinanceApi, the auth interceptor) over the in-app
// fake server, for the client and fake tests.
import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/timezone.dart' as tz;

/// 24 October 2026, 15:00 UTC: the fake server's clock and the client's in these tests.
final DateTime fakeNow = DateTime.utc(2026, 10, 24, 15);

final Clock fakeClientClock = FixedClock(fakeNow, tz.UTC);

/// A fake server over [dataset] (the sample one by default), on [fakeNow].
FakeServer newFakeServer({FakeDataset? dataset}) => FakeServer(
  dataset: dataset ?? FakeDataset.sample(LocalDate(2026, 10, 24)),
  now: () => fakeNow,
);

/// One client of a fake server: its API and its token store.
final class FakeClient {
  FakeClient(this.server, {Session? session})
    : store = InMemoryTokenStore(session: session) {
    api = HttpFinanceApi(
      buildDio(
        AppConfig.prod(),
        adapter: server.adapter,
        baseUrl: FakeServer.baseUrl,
        version: () async => '1.0.0',
      ),
      tokens: store,
      clock: fakeClientClock,
    );
  }

  final FakeServer server;
  final InMemoryTokenStore store;
  late final HttpFinanceApi api;

  /// A client signed in as a new user [email] on its own device.
  factory FakeClient.signedIn(
    FakeServer server, {
    String email = 'ada@example.com',
    String password = 'correct horse',
    String deviceName = 'Pixel 6',
  }) {
    if (!server.hasUser(email)) {
      server.seedUser(email: email, password: password, displayName: 'Ada');
    }
    return FakeClient(
      server,
      session: server.seedSession(
        email: email,
        password: password,
        deviceName: deviceName,
      ),
    );
  }

  Session get session => store.session!;
}
