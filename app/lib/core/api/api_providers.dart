/// The API's providers: the token store, the fake server and the `FinanceApi`, and the
/// overrides that put a flavor on the fake (`apiOverridesFor`).
///
/// - dev and prod: `HttpFinanceApi` on the network, the session in secure storage.
/// - demo: the in-app fake server behind the real client, over the persona engine's
///   household the demo shows, seeded with the demo user (`demoEmail`), its Items linked
///   and synced, and that user signed in, so the demo never shows sign-in and makes no
///   network call.
/// - dev with `--dart-define=FT_FAKE_SERVER=true`: the same fake, empty and signed out,
///   with the session in memory, for the auth flow on the emulator without a server. The
///   define is ignored in every other flavor.
library;

import 'package:finance_tracker/core/api/api_config.dart';
import 'package:finance_tracker/core/api/fake/fake_dataset.dart';
import 'package:finance_tracker/core/api/fake/fake_server.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/http_finance_api.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_providers.g.dart';

/// The demo user of the fake server. Its password is a fixed string of the fake, which
/// guards nothing: the fake never leaves the process.
const String demoEmail = 'demo@financetracker.test';
const String demoPassword = 'demo-password';

/// Whether the dev flavor runs on the fake server (`FT_FAKE_SERVER`).
const bool fakeServerInDev = bool.fromEnvironment('FT_FAKE_SERVER');

/// The installed version, for the `User-Agent`.
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;

/// Where the session is kept: secure storage.
@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => SecureTokenStore();

/// The in-app fake server; only the flavors and tests that run on it supply one.
@Riverpod(keepAlive: true)
FakeServer fakeServer(Ref ref) => throw UnimplementedError(
  'fakeServerProvider is supplied by apiOverridesFor',
);

/// The API, over the network.
@Riverpod(keepAlive: true)
FinanceApi financeApi(Ref ref) {
  final HttpFinanceApi api = HttpFinanceApi(
    buildDio(
      ref.watch(appConfigProvider),
      version: () => ref.read(appVersionProvider.future),
    ),
    tokens: ref.watch(tokenStoreProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(api.close);
  return api;
}

/// The API's overrides for [config]: none for dev and prod on the network, the fake
/// server for demo (signed in) and for dev under `FT_FAKE_SERVER` (signed out).
List<Override> apiOverridesFor(AppConfig config) => switch (config.flavor) {
  Flavor.demo => fakeApiOverrides(signedIn: true, personaSeed: true),
  Flavor.dev when fakeServerInDev => fakeApiOverrides(signedIn: false),
  Flavor.dev || Flavor.prod => const [],
};

/// The fake server over a dataset, a session in memory and the API on the fake: the
/// dataset is the demo flavor's persona seed (`demoSeedProvider`) when [personaSeed],
/// else the sample dated to the clock's today. When [signedIn], the demo user exists,
/// its Items are linked and synced, and its session is stored.
List<Override> fakeApiOverrides({
  required bool signedIn,
  bool personaSeed = false,
}) => [
  fakeServerProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    final FakeServer server = FakeServer(
      dataset: personaSeed
          ? FakeDataset.fromDemoSeed(ref.watch(demoSeedProvider))
          : FakeDataset.sample(clock.today()),
      now: clock.nowUtc,
    );
    if (signedIn) {
      server
        ..seedUser(
          email: demoEmail,
          password: demoPassword,
          displayName: 'Demo',
        )
        ..seedLinkedItems(demoEmail);
    }
    return server;
  }),
  tokenStoreProvider.overrideWith((ref) {
    if (!signedIn) return InMemoryTokenStore();
    final Session session = ref
        .watch(fakeServerProvider)
        .seedSession(
          email: demoEmail,
          password: demoPassword,
          deviceName: 'Demo device',
        );
    return InMemoryTokenStore(session: session, installUserId: session.userId);
  }),
  fakeFinanceApiOverride,
];

/// The API over `fakeServerProvider`, whatever supplies it.
final Override fakeFinanceApiOverride = financeApiProvider.overrideWith((ref) {
  final HttpFinanceApi api = HttpFinanceApi(
    buildDio(
      ref.watch(appConfigProvider),
      adapter: ref.watch(fakeServerProvider).adapter,
      baseUrl: FakeServer.baseUrl,
      version: () => ref.read(appVersionProvider.future),
    ),
    tokens: ref.watch(tokenStoreProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(api.close);
  return api;
});
