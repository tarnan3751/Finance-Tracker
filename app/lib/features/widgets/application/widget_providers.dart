/// The home screen widgets in the app (`docs/reference/widgets.md`): the writer, the
/// snapshot of what the screens show, and the runner that keeps the widgets current.
///
/// [WidgetRefreshRunner] writes the snapshot ([widgetDataProvider], stamped with the
/// time of the write) through [widgetWriterProvider] [widgetDebounceProvider]'s wait
/// (two seconds) after the last change to anything the snapshot reads (the
/// repositories' streams behind it, the session, today, the lock setting), and after
/// every whole Plaid pull and every sync session even when nothing changed, so the
/// footer moves; one write at a time, a failure logged by type
/// and never stopping the next. Nothing runs unless something listens: `bootstrap` does,
/// after the first frame, in every flavor. The background cycle calls [writeWidgetsNow]
/// on its own container.
library;

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/domain/session_state.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/net_worth/application/net_worth_providers.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/features/widgets/application/widget_data_builder.dart';
import 'package:finance_tracker/features/widgets/data/fake_widget_writer.dart';
import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:finance_tracker/features/widgets/domain/widget_writer.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show basicLocaleListResolution;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'widget_providers.g.dart';

final Logger _log = Logger('widgets');

/// How long the runner waits after a change before it writes: two seconds, so a burst of
/// writes (a pull, a bulk edit) redraws the widgets once.
@Riverpod(keepAlive: true)
Duration widgetDebounce(Ref ref) => const Duration(seconds: 2);

/// Where the snapshot goes: the fake by default (the tests), `home_widget` in every
/// flavor (`overridesFor`).
@Riverpod(keepAlive: true)
WidgetWriter widgetWriter(Ref ref) => FakeWidgetWriter();

/// The strings the snapshot is written in: the device's locale, resolved against the
/// app's.
@Riverpod(keepAlive: true)
AppLocalizations widgetLocalizations(Ref ref) => lookupAppLocalizations(
  basicLocaleListResolution(
    PlatformDispatcher.instance.locales,
    AppLocalizations.supportedLocales,
  ),
);

/// The snapshot of what the screens show now (`buildWidgetData`), or the signed-out one
/// in dev and prod while nobody is signed in; recomputed whenever any of it changes, the
/// lock setting included. Whether the lock is enabled is read from `app_meta`, so a
/// container whose lock controller has not restored (the background cycle's) never
/// writes an unlocked snapshot by mistake.
@riverpod
Future<WidgetData> widgetData(Ref ref) async {
  final Clock clock = ref.watch(clockProvider);
  final AppLocalizations l10n = ref.watch(widgetLocalizationsProvider);
  final bool demo = ref.watch(appConfigProvider).flavor == Flavor.demo;
  final SessionState session = ref.watch(sessionControllerProvider);
  // Before the stored session is read (a fresh container's first moments) nothing is
  // known: the snapshot waits for the read rather than say "signed out".
  if (!demo && session is SessionUnknown) return Completer<WidgetData>().future;
  if (!demo && session is! SignedIn) {
    final DateTime now = clock.nowUtc();
    return WidgetData.signedOut(
      updatedAt: now,
      updatedText: widgetUpdatedText(now, clock.location, l10n),
    );
  }
  // The controller's setting is what changes; app_meta, written first, is the record.
  ref.watch(lockControllerProvider.select((s) => s.enabled));
  final bool locked =
      await ref.watch(appMetaStoreProvider).read(AppMetaKeys.lockEnabled) ==
      'true';
  final LocalDate today = ref.watch(todayProvider);
  final List<Account> accounts = await ref.watch(accountsProvider.future);
  final Map<String, Money?> derived = await ref.watch(
    derivedBalancesProvider.future,
  );
  final List<BalanceSnapshot> snapshots = await ref.watch(
    balanceSnapshotsProvider.future,
  );
  final List<BudgetStatus> budgets = await ref.watch(
    budgetStatusesProvider.future,
  );
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<BillStatus> bills = await ref.watch(billStatusesProvider.future);
  final BillPayments payments = await ref.watch(billPaymentsProvider.future);
  final Map<String, String> streamNames = await ref.watch(
    streamNamesProvider.future,
  );
  return buildWidgetData(
    accounts: accounts,
    derived: derived,
    netWorth: observedNetWorth(snapshots, {
      for (final Account a in accounts) a.id: a.type,
    }),
    budgets: budgets,
    categories: {for (final Category c in categories) c.id: c},
    bills: bills,
    payments: payments,
    streamNames: streamNames,
    today: today,
    now: clock.nowUtc(),
    location: clock.location,
    deviceCurrency: defaultCurrencyCode(),
    locked: locked,
    l10n: l10n,
  );
}

/// Keeps the widgets current while listened to (see the library comment); its state is
/// when it last wrote. Not kept alive: it follows [widgetDataProvider], which follows the
/// screens' providers, so it lives while something listens (`bootstrap`, or
/// [writeWidgetsNow]).
@riverpod
class WidgetRefreshRunner extends _$WidgetRefreshRunner {
  Timer? _debounce;
  Future<void> _last = Future<void>.value();

  @override
  DateTime? build() {
    ref.listen(widgetDataProvider, (_, next) {
      if (next.hasValue) _schedule();
    }, fireImmediately: true);
    final StreamSubscription<DateTime> pulls = ref
        .watch(plaidPullProvider)
        .completed
        .listen((_) => _schedule());
    ref.listen<SyncStatus>(syncControllerProvider, (previous, next) {
      final DateTime? at = next.lastSyncAt;
      if (at != null && at != previous?.lastSyncAt) _schedule();
    });
    ref.onDispose(() {
      _debounce?.cancel();
      unawaited(pulls.cancel());
    });
    return null;
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(
      ref.read(widgetDebounceProvider),
      () => unawaited(refresh()),
    );
  }

  /// Writes the snapshot now, after any write already asked for, and completes when it
  /// is written (or has failed, which is logged).
  Future<void> refresh() {
    _debounce?.cancel();
    return _last = _last.then((_) async {
      if (!ref.mounted) return;
      try {
        final WidgetData data = await ref.read(widgetDataProvider.future);
        final Clock clock = ref.read(clockProvider);
        final DateTime now = clock.nowUtc();
        await ref
            .read(widgetWriterProvider)
            .write(
              data.stamped(
                now,
                widgetUpdatedText(
                  now,
                  clock.location,
                  ref.read(widgetLocalizationsProvider),
                ),
              ),
            );
        if (ref.mounted) state = now;
      } on Object catch (e) {
        // Only the type: a message could carry an amount.
        _log.warning('the widgets were not written: ${e.runtimeType}');
      }
    });
  }
}

/// Writes the widgets' snapshot in [container] now and completes when it is written (a
/// failure is logged, not thrown): the background cycle's hook. It waits for the stored
/// session to be read (`SessionController.restored`), then listens to the runner for the
/// write and releases it after.
///
/// A background isolate prepares what `bootstrap` prepares before calling it: the time
/// zones (`setUpTimeZones`, for "today" and the footer's time), `Intl.defaultLocale`
/// (`deviceLocale()`, which `Money.format` reads) and the date symbols
/// (`initializeDateFormatting()`, for the due dates and the time), and a container over
/// the flavor's `overridesFor`, whose local data is open.
Future<void> writeWidgetsNow(ProviderContainer container) async {
  await container.read(sessionControllerProvider.notifier).restored();
  final ProviderSubscription<DateTime?> runner = container.listen(
    widgetRefreshRunnerProvider,
    (_, _) {},
  );
  try {
    await container.read(widgetRefreshRunnerProvider.notifier).refresh();
  } finally {
    runner.close();
  }
}
