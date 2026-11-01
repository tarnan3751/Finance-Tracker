// The demo inside dev and prod (the app mode `demo`) is wired as the demo flavor is: the
// same providers overridden, the same implementations read, but for the two the device
// needs to leave the demo (the wipe through the preferences and the app mode store);
// before a mode is chosen the app runs on the in-memory defaults, with no database.
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/finance_api.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/config/app_mode_store.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/background_work_provider.dart';
import 'package:finance_tracker/core/platform/backup_picker_provider.dart';
import 'package:finance_tracker/core/platform/csv_picker_provider.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/items/application/link_launcher_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:persona_engine/persona_engine.dart' show PersonaId;
import 'package:shared_models/shared_models.dart';

import '../api/support/fake_api.dart';

Set<Object?> _origins(List<Override> overrides) => {
  // ignore: invalid_use_of_visible_for_testing_member
  for (final Override o in overrides) o.origin,
};

void main() {
  final AppConfig demoMode = AppConfig.prod().withChoices(mode: AppMode.demo);

  test('the demo mode overrides what the demo flavor does, and two more', () {
    final Set<Object?> flavor = _origins(overridesFor(AppConfig.demo()));
    final Set<Object?> mode = _origins(overridesFor(demoMode));
    expect(flavor.difference(mode), isEmpty);
    expect(mode.difference(flavor), {localWipeProvider, appModeStoreProvider});
  });

  test('and reads the same implementations', () async {
    ProviderContainer container(AppConfig config) => ProviderContainer.test(
      overrides: [
        ...overridesFor(config),
        clockProvider.overrideWithValue(fakeClientClock),
      ],
    );
    final ProviderContainer flavor = container(AppConfig.demo());
    final ProviderContainer mode = container(demoMode);
    final List<ProviderListenable<Object?>> same = [
      accountRepositoryProvider,
      transactionRepositoryProvider,
      categoryRepositoryProvider,
      itemRepositoryProvider,
      ruleRepositoryProvider,
      budgetRepositoryProvider,
      budgetAlertStoreProvider,
      billRepositoryProvider,
      billAlertStoreProvider,
      goalRepositoryProvider,
      recurringStreamRepositoryProvider,
      liabilityRepositoryProvider,
      holdingRepositoryProvider,
      investmentTransactionRepositoryProvider,
      balanceSnapshotRepositoryProvider,
      savedFilterRepositoryProvider,
      settingsRepositoryProvider,
      appMetaStoreProvider,
      dismissedPairStoreProvider,
      conflictStoreProvider,
      plaidPullStoreProvider,
      receiptStoreProvider,
      changeRecorderProvider,
      recordingSyncStoreProvider,
      localDataSyncsProvider,
      tokenStoreProvider,
      financeApiProvider,
      linkLauncherProvider,
      imageSourceProvider,
      csvPickerProvider,
      backupPickerProvider,
      fileExporterProvider,
      reminderSchedulerProvider,
      backgroundWorkProvider,
      appNotifierProvider,
      serverAddressProvider,
    ];
    for (final ProviderListenable<Object?> p in same) {
      expect(
        mode.read(p).runtimeType,
        flavor.read(p).runtimeType,
        reason: '$p',
      );
    }
    expect(flavor.read(localDataSyncsProvider), isFalse);
    expect(mode.read(recordingSyncStoreProvider), isNull);
    expect(() => mode.read(databaseProvider), throwsA(anything));
    expect(mode.read(localWipeProvider), isA<DriftLocalWipe>());
    expect(flavor.read(localWipeProvider), isA<InMemoryLocalWipe>());
    expect(mode.read(appModeStoreProvider), isA<PreferencesAppModeStore>());

    // Signed in as the demo user on the fake, with the same household.
    await mode.read(sessionControllerProvider.notifier).restored();
    expect(
      (mode.read(sessionControllerProvider) as SignedIn).user.email,
      demoEmail,
    );
    final FinanceApi api = mode.read(financeApiProvider);
    expect(
      (await api.listAccounts()).map((a) => a.id).toSet(),
      (await flavor.read(financeApiProvider).listAccounts())
          .map((a) => a.id)
          .toSet(),
    );
  });

  test('the demo mode shows the household the device stores', () async {
    final ProviderContainer c = ProviderContainer.test(
      overrides: [
        ...overridesFor(
          AppConfig.prod().withChoices(
            mode: AppMode.demo,
            demoPersona: PersonaId.family,
          ),
        ),
        clockProvider.overrideWithValue(fakeClientClock),
      ],
    );
    expect(c.read(demoPersonaProvider), PersonaId.family);
    final List<Account> accounts = await c
        .read(accountRepositoryProvider)
        .watchAll()
        .first;
    expect(
      accounts.map((a) => a.id).toSet(),
      c.read(demoSeedProvider).household.accounts.map((a) => a.id).toSet(),
    );
  });

  test('before a mode is chosen: the in-memory defaults, no database', () {
    final List<Override> unset = overridesFor(
      AppConfig.prod().withChoices(mode: null),
    );
    final Set<Object?> origins = _origins(unset);
    expect(origins, isNot(contains(databaseProvider)));
    expect(origins, isNot(contains(accountRepositoryProvider)));
    expect(origins, contains(localWipeProvider));
    expect(origins, contains(appModeStoreProvider));
    final ProviderContainer c = ProviderContainer.test(overrides: unset);
    expect(c.read(localDataSyncsProvider), isFalse);
    // A wipe cut short is found through the preferences in every mode.
    expect(c.read(localWipeProvider), isA<DriftLocalWipe>());
    expect(c.read(appModeStoreProvider), isA<PreferencesAppModeStore>());
  });
}
