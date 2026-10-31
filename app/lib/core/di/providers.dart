/// The app-wide providers: the flavor's configuration, the clock, the repositories, and the
/// overrides `bootstrap` installs for a flavor.
///
/// Feature providers live in their feature's `application/` folder; what is here is what
/// every feature may depend on. With no override, the repositories are the in-memory ones
/// over one shared [InMemoryStore] (what tests get), recording into an in-memory sync
/// store, and the receipts are in memory; [overridesFor] gives dev and prod the Drift
/// repositories over the encrypted database, recording into the Drift sync store, with
/// the receipts as files in the app's support directory (which the local wipe deletes
/// with the database files), the bill reminders through
/// `flutter_local_notifications` and the exported files through the "Save as" dialog and
/// the share sheet, and the demo flavor the demo ones, which record nothing, with the
/// fake image source (and, as by default, the fake reminder scheduler and file
/// exporter); every flavor gets the window's secure flag and the monotonic clock through
/// the app's own channels, and the app lock's check through `local_auth`.
library;

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:finance_tracker/core/api/api_models.dart' as wire;
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/drift_plaid_pull_store.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart';
import 'package:finance_tracker/core/platform/app_shortcuts_provider.dart';
import 'package:finance_tracker/core/platform/backup_picker_provider.dart';
import 'package:finance_tracker/core/platform/channel_monotonic_clock.dart';
import 'package:finance_tracker/core/platform/channel_screen_security.dart';
import 'package:finance_tracker/core/platform/fake_image_source.dart';
import 'package:finance_tracker/core/platform/file_exporter_provider.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/core/platform/launch_intent_provider.dart';
import 'package:finance_tracker/core/platform/local_notifications_scheduler.dart';
import 'package:finance_tracker/core/platform/monotonic_clock_provider.dart';
import 'package:finance_tracker/core/platform/platform_backup_picker.dart';
import 'package:finance_tracker/core/platform/platform_file_exporter.dart';
import 'package:finance_tracker/core/platform/platform_launch_intent.dart';
import 'package:finance_tracker/core/platform/quick_actions_app_shortcuts.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/platform/screen_security_provider.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/device_clock.dart';
import 'package:finance_tracker/core/sync/http_sync_relay.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/data/demo_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/bills/data/demo_bill_repository.dart';
import 'package:finance_tracker/features/bills/data/demo_bills.dart';
import 'package:finance_tracker/features/bills/data/drift_bill_alert_store.dart';
import 'package:finance_tracker/features/bills/data/drift_bill_repository.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_alert_store.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/bills/domain/bill_alert_store.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';
import 'package:finance_tracker/features/budgets/data/demo_budget_repository.dart';
import 'package:finance_tracker/features/budgets/data/demo_budgets.dart';
import 'package:finance_tracker/features/budgets/data/drift_budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/data/drift_budget_repository.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:finance_tracker/features/budgets/domain/budget_alert_store.dart';
import 'package:finance_tracker/features/budgets/domain/budget_repository.dart';
import 'package:finance_tracker/features/categories/data/demo_category_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/categories/data/in_memory_category_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/conflicts/data/drift_conflict_store.dart';
import 'package:finance_tracker/features/conflicts/data/in_memory_conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/conflict_store.dart';
import 'package:finance_tracker/features/duplicates/data/drift_dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/data/in_memory_dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/dismissed_pair_store.dart';
import 'package:finance_tracker/features/goals/data/demo_goal_repository.dart';
import 'package:finance_tracker/features/goals/data/demo_goals.dart';
import 'package:finance_tracker/features/goals/data/drift_goal_repository.dart';
import 'package:finance_tracker/features/goals/data/in_memory_goal_repository.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:finance_tracker/features/investments/data/demo_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/demo_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/data/drift_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/drift_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart';
import 'package:finance_tracker/features/investments/data/in_memory_investment_transaction_repository.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/investments/domain/investment_transaction_repository.dart';
import 'package:finance_tracker/features/items/data/demo_item_repository.dart';
import 'package:finance_tracker/features/items/data/drift_item_repository.dart';
import 'package:finance_tracker/features/items/data/in_memory_item_repository.dart';
import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/liabilities/data/demo_liability_repository.dart';
import 'package:finance_tracker/features/liabilities/data/drift_liability_repository.dart';
import 'package:finance_tracker/features/liabilities/data/in_memory_liability_repository.dart';
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';
import 'package:finance_tracker/features/lock/application/device_auth_provider.dart';
import 'package:finance_tracker/features/lock/data/local_auth_device_auth.dart';
import 'package:finance_tracker/features/net_worth/data/demo_balance_snapshot_repository.dart';
import 'package:finance_tracker/features/net_worth/data/drift_balance_snapshot_repository.dart';
import 'package:finance_tracker/features/net_worth/data/in_memory_balance_snapshot_repository.dart';
import 'package:finance_tracker/features/net_worth/domain/balance_snapshot_repository.dart';
import 'package:finance_tracker/features/recurring/data/demo_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/data/drift_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/data/in_memory_recurring_stream_repository.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_stream_repository.dart';
import 'package:finance_tracker/features/rules/application/rule_runner.dart';
import 'package:finance_tracker/features/rules/data/demo_rule_repository.dart';
import 'package:finance_tracker/features/rules/data/demo_rules.dart';
import 'package:finance_tracker/features/rules/data/drift_rule_repository.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:finance_tracker/features/settings/data/demo_settings_repository.dart';
import 'package:finance_tracker/features/settings/data/drift_settings_repository.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/demo_saved_filters.dart';
import 'package:finance_tracker/features/transactions/data/demo_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_saved_filter_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_saved_filter_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:finance_tracker/features/widgets/data/home_widget_writer.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persona_engine/persona_engine.dart' show DemoSeed, PersonaId;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_engine/sync_engine.dart';

part 'providers.g.dart';

/// The running flavor's configuration. There is no default: `bootstrap` (or a test)
/// overrides it through [overridesFor].
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider is supplied by bootstrap through overridesFor(config)',
);

/// The clock every "now" and "today" comes from.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();

/// Where the database key is kept: the Keystore-backed secure storage.
@Riverpod(keepAlive: true)
DatabaseKeyStore databaseKeyStore(Ref ref) => SecureDatabaseKeyStore();

/// The close [databaseProvider] starts when its container is disposed, by database, for
/// what must wait until the file is free (`bootstrap`'s `stopApp`, before a restore).
/// Awaiting this close, rather than closing again, matters: two closes of one Drift
/// database at once race in its stream query store ("concurrent modification during
/// iteration"), and closing first, before the container is disposed, can hang while the
/// container's providers still use the database.
final Expando<Future<void>> databaseClosing = Expando('databaseClosing');

/// The local database of the dev and prod flavors, opened lazily on its first query
/// (`bootstrap` opens it at startup) and closed with the container ([databaseClosing]).
/// The demo flavor has none, and reading it there is a [StateError].
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final AppDatabase database = openAppDatabase(
    ref.watch(appConfigProvider),
    ref.watch(databaseKeyStoreProvider),
  );
  // Closing a database that failed to open rethrows the open failure, which bootstrap
  // has already handled; any other close error still surfaces.
  ref.onDispose(() {
    final Future<void> closing = database.close().catchError(
      (Object _) {},
      test: isDatabaseOpenFailure,
    );
    databaseClosing[database] = closing;
    unawaited(closing);
  });
  return database;
}

/// The state behind the in-memory and demo repositories: empty by default; the demo
/// flavor's holds the system categories and the selected persona's demo seed.
@Riverpod(keepAlive: true)
InMemoryStore inMemoryStore(Ref ref) {
  final InMemoryStore store = InMemoryStore(ref.watch(clockProvider));
  ref.onDispose(store.close);
  return store;
}

/// The sync store the in-memory repositories record into (tests read its outbox).
@Riverpod(keepAlive: true)
InMemorySyncStore inMemorySyncStore(Ref ref) => InMemorySyncStore();

/// The sync store over the local database of the dev and prod flavors.
@Riverpod(keepAlive: true)
DriftSyncStore driftSyncStore(Ref ref) =>
    DriftSyncStore(ref.watch(databaseProvider), ref.watch(clockProvider));

/// The device's sync clock and node, over [driftSyncStore]: one instance for every
/// local edit and every sync session.
@Riverpod(keepAlive: true)
DeviceClock deviceClock(Ref ref) =>
    DeviceClock(ref.watch(driftSyncStoreProvider));

/// Where the repositories record user-authored writes for sync: by default into
/// [inMemorySyncStore] on a fixed node; [overridesFor] gives dev and prod the Drift store
/// and the device clock, and the demo flavor no recording.
@Riverpod(keepAlive: true)
ChangeRecorder changeRecorder(Ref ref) {
  final Clock clock = ref.watch(clockProvider);
  final HlcClock hlc = HlcClock('local-memory');
  return EngineChangeRecorder(
    ref.watch(inMemorySyncStoreProvider),
    () async => hlc,
    () => clock.nowUtc().millisecondsSinceEpoch,
  );
}

/// The sync store [changeRecorder] records into, for what reads its records outside a
/// write (the rules on arrival): [inMemorySyncStore] by default, the Drift store in dev and
/// prod, none in the demo flavor, which never records.
@Riverpod(keepAlive: true)
SyncStore? recordingSyncStore(Ref ref) => ref.watch(inMemorySyncStoreProvider);

/// The server's id for this device while someone is signed in, else null: the node the
/// device's sync clock adopts.
@Riverpod(keepAlive: true)
String? syncDeviceId(Ref ref) => switch (ref.watch(sessionControllerProvider)) {
  SignedIn(:final Device device) => device.id,
  _ => null,
};

/// The relay the device syncs through while someone is signed in, else null: the API's
/// sync endpoints, as this device.
@Riverpod(keepAlive: true)
SyncRelay? syncRelay(Ref ref) {
  final String? deviceId = ref.watch(syncDeviceIdProvider);
  return deviceId == null
      ? null
      : HttpSyncRelay(
          FinanceApiSyncEndpoints(ref.watch(financeApiProvider)),
          deviceId: deviceId,
        );
}

/// Whether this build's local data syncs: the Drift data of dev and prod, through
/// [overridesFor]. The in-memory data of the tests and the demo flavor never does.
@Riverpod(keepAlive: true)
bool localDataSyncs(Ref ref) => false;

/// How long after the last local change a sync session starts.
@Riverpod(keepAlive: true)
Duration syncDebounce(Ref ref) => const Duration(seconds: 3);

/// The persona the demo flavor shows: [initialDemoPersona] at start, then what Settings →
/// Demo data selects.
@Riverpod(keepAlive: true)
class DemoPersona extends _$DemoPersona {
  @override
  PersonaId build() => initialDemoPersona();

  /// Shows [persona] instead.
  void select(PersonaId persona) => state = persona;
}

/// The demo seed of the selected persona as of the clock's today: what the demo flavor's
/// store is loaded from (and the in-app fake server's dataset).
@Riverpod(keepAlive: true)
DemoSeed demoSeed(Ref ref) => demoSeedFor(
  ref.watch(demoPersonaProvider),
  ref.watch(clockProvider).today(),
);

/// The accounts.
@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) => InMemoryAccountRepository(
  ref.watch(inMemoryStoreProvider),
  recorder: ref.watch(changeRecorderProvider),
);

/// The transactions.
@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    InMemoryTransactionRepository(
      ref.watch(inMemoryStoreProvider),
      recorder: ref.watch(changeRecorderProvider),
    );

/// The categories.
@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) => InMemoryCategoryRepository(
  ref.watch(inMemoryStoreProvider),
  recorder: ref.watch(changeRecorderProvider),
);

/// The user's Plaid Items.
@Riverpod(keepAlive: true)
ItemRepository itemRepository(Ref ref) =>
    InMemoryItemRepository(ref.watch(inMemoryStoreProvider));

/// The rules.
@Riverpod(keepAlive: true)
RuleRepository ruleRepository(Ref ref) {
  final InMemoryRuleRepository repository = InMemoryRuleRepository(
    ref.watch(clockProvider),
    recorder: ref.watch(changeRecorderProvider),
  );
  ref.onDispose(repository.close);
  return repository;
}

/// The budgets.
@Riverpod(keepAlive: true)
BudgetRepository budgetRepository(Ref ref) {
  final InMemoryBudgetRepository repository = InMemoryBudgetRepository(
    ref.watch(clockProvider),
    recorder: ref.watch(changeRecorderProvider),
  );
  ref.onDispose(repository.close);
  return repository;
}

/// The recurring streams and the user's overrides of them.
@Riverpod(keepAlive: true)
RecurringStreamRepository recurringStreamRepository(Ref ref) {
  final InMemoryRecurringStreamRepository repository =
      InMemoryRecurringStreamRepository(
        ref.watch(clockProvider),
        recorder: ref.watch(changeRecorderProvider),
      );
  ref.onDispose(repository.close);
  return repository;
}

/// The liabilities of the linked accounts.
@Riverpod(keepAlive: true)
LiabilityRepository liabilityRepository(Ref ref) {
  final InMemoryLiabilityRepository repository = InMemoryLiabilityRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// The holdings of the linked investment accounts and their securities.
@Riverpod(keepAlive: true)
HoldingRepository holdingRepository(Ref ref) {
  final InMemoryHoldingRepository repository = InMemoryHoldingRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// The investment transactions of the linked investment accounts.
@Riverpod(keepAlive: true)
InvestmentTransactionRepository investmentTransactionRepository(Ref ref) {
  final InMemoryInvestmentTransactionRepository repository =
      InMemoryInvestmentTransactionRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// The balance snapshots this device has observed: in memory by default, empty at launch
/// in the demo flavor, `balance_snapshots` in dev and prod.
@Riverpod(keepAlive: true)
BalanceSnapshotRepository balanceSnapshotRepository(Ref ref) {
  final InMemoryBalanceSnapshotRepository repository =
      InMemoryBalanceSnapshotRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// Which budget alerts this device has raised: in memory by default and in the demo
/// flavor, `budget_alerts` in dev and prod.
@Riverpod(keepAlive: true)
BudgetAlertStore budgetAlertStore(Ref ref) => InMemoryBudgetAlertStore();

/// Facts about this install (`app_meta`): in memory by default and in the demo flavor,
/// the database's in dev and prod.
@Riverpod(keepAlive: true)
AppMetaStore appMetaStore(Ref ref) => InMemoryAppMetaStore();

/// The bills.
@Riverpod(keepAlive: true)
BillRepository billRepository(Ref ref) {
  final InMemoryBillRepository repository = InMemoryBillRepository(
    ref.watch(clockProvider),
    recorder: ref.watch(changeRecorderProvider),
  );
  ref.onDispose(repository.close);
  return repository;
}

/// Which bill notifications this device has raised: in memory by default and in the
/// demo flavor, `bill_alerts` in dev and prod.
@Riverpod(keepAlive: true)
BillAlertStore billAlertStore(Ref ref) => InMemoryBillAlertStore();

/// The savings goals and their contributions.
@Riverpod(keepAlive: true)
GoalRepository goalRepository(Ref ref) {
  final InMemoryGoalRepository repository = InMemoryGoalRepository(
    ref.watch(clockProvider),
    recorder: ref.watch(changeRecorderProvider),
  );
  ref.onDispose(repository.close);
  return repository;
}

/// The transaction list's saved filters, on this device only.
@Riverpod(keepAlive: true)
SavedFilterRepository savedFilterRepository(Ref ref) {
  final InMemorySavedFilterRepository repository =
      InMemorySavedFilterRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// Where the app preferences are kept.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final InMemorySettingsRepository repository = InMemorySettingsRepository(
    recorder: ref.watch(changeRecorderProvider),
  );
  ref.onDispose(repository.close);
  return repository;
}

/// Where the receipt photos are kept: in memory by default (the tests, the demo flavor),
/// files in the app's support directory in dev and prod.
@Riverpod(keepAlive: true)
ReceiptStore receiptStore(Ref ref) => MemoryReceiptStore();

/// The local wipe (`local_wipe.dart`): the stores only by default (the tests, the demo
/// flavor), the database files too in dev and prod.
@Riverpod(keepAlive: true)
LocalWipe localWipe(Ref ref) => InMemoryLocalWipe(
  receipts: ref.watch(receiptStoreProvider),
  widgets: ref.watch(widgetWriterProvider),
  keys: ref.watch(databaseKeyStoreProvider),
  tokens: ref.watch(tokenStoreProvider),
  reminders: ref.watch(reminderSchedulerProvider),
);

/// Stops the app, wipes its local data, confirms and starts it again: `bootstrap`
/// supplies it; anywhere else (the tests) it is unavailable unless overridden.
@Riverpod(keepAlive: true)
WipeLocalData wipeLocalData(Ref ref) =>
    (_) => throw UnsupportedError('the local wipe is supplied by bootstrap');

/// Where the Plaid pull keeps its cursors: in memory by default (beside the in-memory
/// store, so a new store starts it afresh), `sync_meta` in dev and prod.
@Riverpod(keepAlive: true)
PlaidPullStore plaidPullStore(Ref ref) {
  ref.watch(inMemoryStoreProvider);
  return InMemoryPlaidPullStore();
}

/// The duplicate pairs the user dismissed, kept on the device and never synced: in memory
/// by default and in the demo (beside the in-memory store, so a new store starts it
/// afresh), `dismissed_pairs` in dev and prod.
@Riverpod(keepAlive: true)
DismissedPairStore dismissedPairStore(Ref ref) {
  ref.watch(inMemoryStoreProvider);
  final InMemoryDismissedPairStore store = InMemoryDismissedPairStore();
  ref.onDispose(store.close);
  return store;
}

/// This device's sync conflicts, kept on the device and never synced: in memory by
/// default and in the demo (which never syncs, so it stays empty), `conflicts` in dev
/// and prod.
@Riverpod(keepAlive: true)
ConflictStore conflictStore(Ref ref) {
  final InMemoryConflictStore store = InMemoryConflictStore();
  ref.onDispose(store.close);
  return store;
}

/// What the Plaid pull does with the transactions it inserts: the rules
/// (`docs/reference/rules.md`, **On arrival**).
@Riverpod(keepAlive: true)
ArrivalProcessor arrivalProcessor(Ref ref) => RuleRunner(
  rules: ref.watch(ruleRepositoryProvider),
  categories: ref.watch(categoryRepositoryProvider),
  transactions: ref.watch(transactionRepositoryProvider),
  syncStore: ref.watch(recordingSyncStoreProvider),
);

/// The Plaid pull over the API into the repositories (`core/plaid/plaid_pull.dart`):
/// run after each sync session and after each Item action.
@Riverpod(keepAlive: true)
PlaidPull plaidPull(Ref ref) => PlaidPull(
  api: ref.watch(financeApiProvider),
  store: ref.watch(plaidPullStoreProvider),
  items: ref.watch(itemRepositoryProvider),
  accounts: ref.watch(accountRepositoryProvider),
  transactions: ref.watch(transactionRepositoryProvider),
  streams: ref.watch(recurringStreamRepositoryProvider),
  liabilities: ref.watch(liabilityRepositoryProvider),
  holdings: ref.watch(holdingRepositoryProvider),
  investmentTransactions: ref.watch(investmentTransactionRepositoryProvider),
  clock: ref.watch(clockProvider),
  arrival: ref.watch(arrivalProcessorProvider),
);

/// What the legacy importer did at this launch (`bootstrap`), or null when it did nothing;
/// Phase 1d shows it once.
@Riverpod(keepAlive: true)
class LegacyImportResult extends _$LegacyImportResult {
  @override
  ImportSummary? build() => null;

  /// Records the importer's [summary].
  void record(ImportSummary? summary) => state = summary;
}

/// The provider overrides that make up the app for [config].
List<Override> overridesFor(AppConfig config) => [
  ...localDataOverridesFor(config),
  ...apiOverridesFor(config),
  ...filePickerOverridesFor(config),
  ..._platformOverrides,
];

/// Every flavor: the platform seams that behave the same in all three, through the app's
/// own channels to `MainActivity`, through `local_auth`, and through `home_widget` (the
/// home screen widgets, rendered from the demo seed in demo and from the database in dev
/// and prod) and `quick_actions` (the app shortcuts), with the launch links of both, one
/// process-wide instance.
final List<Override> _platformOverrides = [
  screenSecurityProvider.overrideWithValue(const ChannelScreenSecurity()),
  monotonicClockProvider.overrideWithValue(const ChannelMonotonicClock()),
  deviceAuthProvider.overrideWith((ref) => LocalAuthDeviceAuth()),
  widgetWriterProvider.overrideWithValue(const HomeWidgetWriter()),
  launchIntentProvider.overrideWithValue(_platformLaunchIntent),
  appShortcutsProvider.overrideWithValue(const QuickActionsAppShortcuts()),
];

final PlatformLaunchIntent _platformLaunchIntent = PlatformLaunchIntent();

/// The system's file dialogs in dev and prod (`flutter_file_dialog` and `share_plus`):
/// the file exporter and the backup picker; the fakes elsewhere. Apart from
/// [localDataOverridesFor], so a test on the dev wiring keeps the fakes.
List<Override> filePickerOverridesFor(AppConfig config) =>
    switch (config.flavor) {
      Flavor.dev || Flavor.prod => [
        fileExporterProvider.overrideWith(
          (ref) => PlatformFileExporter(getTemporaryDirectory),
        ),
        backupPickerProvider.overrideWith(
          (ref) => const PlatformBackupPicker(),
        ),
      ],
      Flavor.demo => const [],
    };

/// [overridesFor] without the API's: the flavor and its local data. For a test that
/// supplies its own API (a fake server shared by several app instances), whatever
/// `FT_FAKE_SERVER` says.
List<Override> localDataOverridesFor(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
  ...switch (config.flavor) {
    Flavor.dev || Flavor.prod => _driftOverrides,
    Flavor.demo => _demoOverrides,
  },
];

/// dev and prod: the Drift repositories over the encrypted database, recording into the
/// Drift sync store with the device clock, and that data syncs.
final List<Override> _driftOverrides = [
  localDataSyncsProvider.overrideWithValue(true),
  changeRecorderProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    return EngineChangeRecorder(
      ref.watch(driftSyncStoreProvider),
      ref.watch(deviceClockProvider).current,
      () => clock.nowUtc().millisecondsSinceEpoch,
    );
  }),
  accountRepositoryProvider.overrideWith(
    (ref) => DriftAccountRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  transactionRepositoryProvider.overrideWith(
    (ref) => DriftTransactionRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  categoryRepositoryProvider.overrideWith(
    (ref) => DriftCategoryRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  itemRepositoryProvider.overrideWith(
    (ref) => DriftItemRepository(ref.watch(databaseProvider)),
  ),
  plaidPullStoreProvider.overrideWith(
    (ref) => DriftPlaidPullStore(
      ref.watch(databaseProvider),
      ref.watch(driftSyncStoreProvider),
    ),
  ),
  recordingSyncStoreProvider.overrideWith(
    (ref) => ref.watch(driftSyncStoreProvider),
  ),
  ruleRepositoryProvider.overrideWith(
    (ref) => DriftRuleRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  budgetRepositoryProvider.overrideWith(
    (ref) => DriftBudgetRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  budgetAlertStoreProvider.overrideWith(
    (ref) => DriftBudgetAlertStore(ref.watch(databaseProvider)),
  ),
  billRepositoryProvider.overrideWith(
    (ref) => DriftBillRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  billAlertStoreProvider.overrideWith(
    (ref) => DriftBillAlertStore(ref.watch(databaseProvider)),
  ),
  goalRepositoryProvider.overrideWith(
    (ref) => DriftGoalRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  appMetaStoreProvider.overrideWith(
    (ref) => DriftAppMetaStore(ref.watch(databaseProvider)),
  ),
  recurringStreamRepositoryProvider.overrideWith(
    (ref) => DriftRecurringStreamRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  liabilityRepositoryProvider.overrideWith(
    (ref) => DriftLiabilityRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  holdingRepositoryProvider.overrideWith(
    (ref) => DriftHoldingRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  investmentTransactionRepositoryProvider.overrideWith(
    (ref) => DriftInvestmentTransactionRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  balanceSnapshotRepositoryProvider.overrideWith(
    (ref) => DriftBalanceSnapshotRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  savedFilterRepositoryProvider.overrideWith(
    (ref) => DriftSavedFilterRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  settingsRepositoryProvider.overrideWith(
    (ref) => DriftSettingsRepository(
      ref.watch(databaseProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  dismissedPairStoreProvider.overrideWith(
    (ref) => DriftDismissedPairStore(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  conflictStoreProvider.overrideWith(
    (ref) => DriftConflictStore(ref.watch(databaseProvider)),
  ),
  receiptStoreProvider.overrideWith(
    (ref) => FileReceiptStore(getApplicationSupportDirectory),
  ),
  localWipeProvider.overrideWith(
    (ref) => DriftLocalWipe(
      directory: getApplicationSupportDirectory,
      receipts: ref.watch(receiptStoreProvider),
      widgets: ref.watch(widgetWriterProvider),
      preferences: SharedPreferences.getInstance,
      keys: ref.watch(databaseKeyStoreProvider),
      tokens: ref.watch(tokenStoreProvider),
      reminders: ref.watch(reminderSchedulerProvider),
    ),
  ),
  reminderSchedulerProvider.overrideWith((ref) {
    final AppLocalizations l10n = lookupAppLocalizations(
      basicLocaleListResolution(
        PlatformDispatcher.instance.locales,
        AppLocalizations.supportedLocales,
      ),
    );
    return LocalNotificationsScheduler(
      FlutterLocalNotificationsPlugin(),
      channelName: l10n.billRemindersChannelName,
      channelDescription: l10n.billRemindersChannelDescription,
    );
  }),
];

/// The demo flavor: everything in memory, from the selected persona's demo seed dated to
/// the clock's today; choosing another persona rebuilds the store (the demo's edits go).
/// Receipt photos come from the fake image source (the bundled demo receipt) and stay in
/// memory.
final List<Override> _demoOverrides = [
  imageSourceProvider.overrideWith((ref) => FakeImageSource.demo()),
  databaseProvider.overrideWith(
    (ref) => throw StateError('The demo flavor has no database'),
  ),
  changeRecorderProvider.overrideWithValue(const NoChangeRecorder()),
  inMemoryStoreProvider.overrideWith((ref) {
    final InMemoryStore store = InMemoryStore(ref.watch(clockProvider))
      ..seedSystemCategories();
    loadDemoSeed(store, ref.watch(demoSeedProvider));
    ref.onDispose(store.close);
    return store;
  }),
  accountRepositoryProvider.overrideWith(
    (ref) => DemoAccountRepository(ref.watch(inMemoryStoreProvider)),
  ),
  transactionRepositoryProvider.overrideWith(
    (ref) => DemoTransactionRepository(ref.watch(inMemoryStoreProvider)),
  ),
  categoryRepositoryProvider.overrideWith(
    (ref) => DemoCategoryRepository(ref.watch(inMemoryStoreProvider)),
  ),
  itemRepositoryProvider.overrideWith(
    (ref) => DemoItemRepository(ref.watch(inMemoryStoreProvider)),
  ),
  // The store already holds the seed the fake server applied for the demo user: the
  // first pull starts after it (the version recorded at seeding, however late the store
  // is built), and brings only what a Link action adds.
  plaidPullStoreProvider.overrideWith((ref) {
    ref.watch(inMemoryStoreProvider);
    final int seeded = ref
        .watch(fakeServerProvider)
        .seededSyncVersionOf(demoEmail);
    return InMemoryPlaidPullStore(
      transactionsSince: seeded,
      investmentTransactionsSince: seeded,
    );
  }),
  recordingSyncStoreProvider.overrideWithValue(null),
  ruleRepositoryProvider.overrideWith((ref) {
    final DemoRuleRepository repository = DemoRuleRepository(
      ref.watch(clockProvider),
      initial: demoRules(ref.watch(demoPersonaProvider)),
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  goalRepositoryProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    final demo = demoGoals(ref.watch(demoSeedProvider), clock.today());
    final DemoGoalRepository repository = DemoGoalRepository(
      clock,
      goals: demo.goals,
      contributions: demo.contributions,
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  billRepositoryProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    final DemoBillRepository repository = DemoBillRepository(
      clock,
      initial: demoBills(ref.watch(demoSeedProvider), clock.today()),
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  budgetRepositoryProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    final DemoBudgetRepository repository = DemoBudgetRepository(
      clock,
      initial: demoBudgets(ref.watch(demoPersonaProvider), clock.today()),
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  recurringStreamRepositoryProvider.overrideWith((ref) {
    final DemoRecurringStreamRepository repository =
        DemoRecurringStreamRepository(
          ref.watch(clockProvider),
          initial: demoRecurringStreams(ref.watch(demoSeedProvider)),
        );
    ref.onDispose(repository.close);
    return repository;
  }),
  liabilityRepositoryProvider.overrideWith((ref) {
    final DemoLiabilityRepository repository = DemoLiabilityRepository(
      initial: demoLiabilities(ref.watch(demoSeedProvider)).toEntities(),
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  holdingRepositoryProvider.overrideWith((ref) {
    final ({List<Holding> holdings, List<Security> securities}) seed =
        demoHoldings(ref.watch(demoSeedProvider)).toEntities();
    final DemoHoldingRepository repository = DemoHoldingRepository(
      holdings: seed.holdings,
      securities: seed.securities,
    );
    ref.onDispose(repository.close);
    return repository;
  }),
  investmentTransactionRepositoryProvider.overrideWith((ref) {
    final DemoInvestmentTransactionRepository repository =
        DemoInvestmentTransactionRepository(
          initial: [
            for (final wire.InvestmentTransaction t
                in demoInvestmentTransactions(ref.watch(demoSeedProvider)))
              t.toEntity(),
          ],
        );
    ref.onDispose(repository.close);
    return repository;
  }),
  balanceSnapshotRepositoryProvider.overrideWith((ref) {
    ref.watch(inMemoryStoreProvider);
    final DemoBalanceSnapshotRepository repository =
        DemoBalanceSnapshotRepository();
    ref.onDispose(repository.close);
    return repository;
  }),
  savedFilterRepositoryProvider.overrideWith((ref) {
    final InMemorySavedFilterRepository repository =
        InMemorySavedFilterRepository(initial: demoSavedFilters);
    ref.onDispose(repository.close);
    return repository;
  }),
  settingsRepositoryProvider.overrideWith((ref) {
    final DemoSettingsRepository repository = DemoSettingsRepository();
    ref.onDispose(repository.close);
    return repository;
  }),
];
