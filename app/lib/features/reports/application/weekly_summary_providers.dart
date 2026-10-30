/// The weekly summary's providers (`docs/reference/reports.md`, **The weekly summary**):
/// the last complete week and the current one, and the in-app notice raised once a
/// week through the `Notifier`.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/reports/domain/weekly_summary.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'weekly_summary_providers.g.dart';

final Logger _log = Logger('reports');

/// The weeks the summary shows: the last complete one and the current one to today.
typedef WeeklyReport = ({WeeklySummary lastWeek, WeeklySummary thisWeek});

/// The last complete week's summary and the current week's to today, hidden rows left
/// out, in the reports' currency.
@riverpod
Future<WeeklyReport> weeklyReport(Ref ref) async {
  final LocalDate today = ref.watch(todayProvider);
  final String currency = await ref.watch(reportCurrencyProvider.future);
  final Set<String> credit = await ref.watch(
    reportCreditAccountIdsProvider.future,
  );
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<Transaction> ledger = await ref.watch(
    recurringLedgerProvider.future,
  );
  final CategoryLookup lookup = categoryLookup(categories);
  final List<ReportEntry> entries = reportEntries(
    ledger,
    lookup,
    currencyCode: currency,
    creditAccountIds: credit,
    excluded: (t) => t.hidden,
  ).toList();
  final LocalDateRange thisWeek = weekContaining(today);
  return (
    lastWeek: WeeklySummary.of(
      weekContaining(thisWeek.start.addDays(-1)),
      entries,
      lookup,
      currencyCode: currency,
    ),
    thisWeek: WeeklySummary.of(
      thisWeek,
      entries,
      lookup,
      currencyCode: currency,
      through: today,
    ),
  );
}

/// Raises "Your weekly summary is ready" once a week: on the first day in a week that
/// it is listened to (`bootstrap` does, for the life of the app), it tells the
/// `Notifier` about the week before and records this week's Monday in `app_meta`
/// (`weekly_summary_raised`), so the notice is raised once per week on this device.
/// Only a week that began on or after the install day's week is summarised, so a fresh
/// install waits for the next Monday. The install day is `app_meta` `install_date`; the
/// demo, which has none, counts the day of its first evaluation (its launch).
/// A failure is logged by its type.
@riverpod
class WeeklySummaryNotice extends _$WeeklySummaryNotice {
  Future<void> _last = Future.value();
  LocalDate? _installDay;

  @override
  void build() {
    ref.listen(todayProvider, (_, today) {
      _last = _last.then((_) => _raise(today));
    }, fireImmediately: true);
  }

  Future<void> _raise(LocalDate today) async {
    try {
      final AppMetaStore meta = ref.read(appMetaStoreProvider);
      final String? installed = await meta.read(AppMetaKeys.installDate);
      final LocalDate installDay = _installDay ??= installed == null
          ? today
          : LocalDate.parse(installed);
      final LocalDate monday = weekContaining(today).start;
      // The week summarised starts a week before [monday].
      if (!monday.isAfter(weekContaining(installDay).start) ||
          await meta.read(AppMetaKeys.weeklySummaryRaised) ==
              monday.toString()) {
        return;
      }
      await ref
          .read(appNotifierProvider)
          .notify(
            WeeklySummaryNotification(
              weekStart: monday.addDays(-7),
              raisedAt: ref.read(clockProvider).nowUtc(),
            ),
          );
      await meta.write(AppMetaKeys.weeklySummaryRaised, monday.toString());
    } on Object catch (e) {
      _log.warning('the weekly summary notice failed: ${e.runtimeType}');
    }
  }
}
