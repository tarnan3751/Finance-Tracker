// The flavors' API wiring: demo runs on the fake server and starts signed in as the demo
// user with its Items linked; dev and prod talk to the network and keep the session in
// secure storage.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/fake/fake_http_adapter.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  test('demo starts signed in on the fake, with the sample data', () async {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        ...overridesFor(AppConfig.demo()),
        clockProvider.overrideWithValue(fakeClientClock),
      ],
    );
    await c.read(sessionControllerProvider.notifier).restored();
    final SessionState state = c.read(sessionControllerProvider);
    expect((state as SignedIn).user.email, demoEmail);
    expect(c.read(tokenStoreProvider), isA<InMemoryTokenStore>());
    expect(c.read(fakeServerProvider).adapter, isA<FakeHttpAdapter>());

    final FinanceApi api = c.read(financeApiProvider);
    expect(await api.listAccounts(), hasLength(3));
    expect((await api.listTransactions()).items, hasLength(12));
  });

  test('dev and prod use the network and secure storage', () {
    for (final AppConfig config in [AppConfig.dev(), AppConfig.prod()]) {
      final ProviderContainer c = ProviderContainer.test(
        overrides: overridesFor(config),
      );
      expect(c.read(tokenStoreProvider), isA<SecureTokenStore>());
      expect(() => c.read(fakeServerProvider), throwsA(anything));
    }
  });
}
