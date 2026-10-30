// The monthly report's data over the in-memory repositories, as of 24 October 2026 on
// the reports' household: the report of the period chosen, the flags in it, the active
// bills' occurrences due in it with their states (paid by a payment or a mark, missed,
// due, upcoming; a paused bill left out; a bill without a name named by nothing), the
// budgets in that period, and the PDF's file name.
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/export/application/export_providers.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/report_seed.dart';

Future<MonthlyReportData> _data(InMemoryStore store, int offset) async {
  final ProviderContainer c = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.demo()),
      clockProvider.overrideWithValue(testClock),
      inMemoryStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(c.dispose);
  await c
      .read(billRepositoryProvider)
      .upsert(
        BillReminder(
          id: 'rent',
          name: 'Rent',
          amount: Money(-165000, 'USD'),
          dueDate: LocalDate(2026, 1, 2),
          cadence: RecurringCadence.monthly,
        ),
      );
  await c
      .read(billRepositoryProvider)
      .upsert(
        BillReminder(
          id: 'gym',
          name: 'Gym',
          amount: Money(-33333, 'USD'),
          dueDate: LocalDate(2026, 1, 8),
          cadence: RecurringCadence.monthly,
        ),
      );
  await c
      .read(billRepositoryProvider)
      .upsert(
        BillReminder(
          id: 'paused',
          name: 'Paused',
          dueDate: LocalDate(2026, 1, 9),
          cadence: RecurringCadence.monthly,
          active: false,
        ),
      );
  await c
      .read(billRepositoryProvider)
      .upsert(
        BillReminder(
          id: 'unnamed',
          dueDate: LocalDate(2026, 1, 23),
          cadence: RecurringCadence.monthly,
          paidOccurrences: [LocalDate(2026, 9, 23)],
        ),
      );
  await c
      .read(budgetRepositoryProvider)
      .upsert(
        Budget(
          id: 'food',
          categoryId: 'plaid:FOOD_AND_DRINK',
          period: BudgetPeriodKind.monthly,
          periodStartDay: 1,
          amount: Money(30000, 'USD'),
          rollover: false,
          startDate: LocalDate(2026, 1, 1),
        ),
      );
  final ProviderSubscription<AsyncValue<MonthlyReportData>> sub = c.listen(
    monthlyReportDataProvider(offset),
    (_, _) {},
  );
  addTearDown(sub.close);
  return c.read(monthlyReportDataProvider(offset).future);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the current period: its flags, bills and budgets', () async {
    final MonthlyReportData data = await _data(reportStore(), 0);

    expect(data.report.current.range.start, LocalDate(2026, 10, 1));
    expect(data.categoryNames['plaid:FOOD_AND_DRINK'], isNotNull);
    expect([
      for (final f in data.anomalies) f.transactionId,
    ], containsAll([reportUnusualId, reportNewMerchantId]));
    expect(
      [for (final ReportBill b in data.bills) (b.name, b.due, b.state)],
      [
        ('Rent', LocalDate(2026, 10, 2), BillState.paid),
        ('Gym', LocalDate(2026, 10, 8), BillState.missed),
        (null, LocalDate(2026, 10, 23), BillState.due),
      ],
    );
    expect(data.budgets.single.status.period.start, LocalDate(2026, 10, 1));
  });

  test('a period before: its bills as they stood, a mark paying one', () async {
    final MonthlyReportData data = await _data(reportStore(), -1);

    expect(data.report.current.range.start, LocalDate(2026, 9, 1));
    expect(
      [for (final ReportBill b in data.bills) (b.name, b.state)],
      [
        ('Rent', BillState.paid),
        ('Gym', BillState.missed),
        (null, BillState.paid),
      ],
    );
    expect(data.budgets.single.status.period.start, LocalDate(2026, 9, 1));
    expect(data.budgets.single.status.period.end, LocalDate(2026, 10, 1));
  });

  test('the file name names the period', () {
    expect(
      monthlyReportFileName(
        LocalDateRange(LocalDate(2026, 10, 1), LocalDate(2026, 11, 1)),
      ),
      'report-2026-10.pdf',
    );
    expect(
      monthlyReportFileName(
        LocalDateRange(LocalDate(2026, 10, 15), LocalDate(2026, 11, 15)),
      ),
      'report-2026-10-15.pdf',
    );
  });
}
