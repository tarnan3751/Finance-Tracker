// The forecast screen on the test household (forecast_seed.dart), as of 24 October 2026:
// the headline and the chart's summary for each horizon, the table and its rows'
// semantics, the headline below zero, the empty state, the account sheet's switches and
// currency chips, and a switch that cannot be kept.
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_accounts_sheet.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_chart.dart';
import 'package:finance_tracker/features/forecast/presentation/forecast_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/forecast_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';
import '../../../helpers/test_seed.dart';

Transaction _spend(String id, int cents) => Transaction(
  id: id,
  accountId: forecastCheckingId,
  amount: Money(cents, 'USD'),
  date: LocalDate(2026, 10, 22),
  pending: false,
  name: id,
  source: DataSource.manual,
  createdAt: testClock.nowUtc(),
  updatedAt: testClock.nowUtc(),
  syncVersion: 0,
);

/// An app_meta store whose writes fail.
final class _FailingMetaStore implements AppMetaStore {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async =>
      throw Exception('the write failed');
}

void main() {
  testWidgets('the chart for 30 days, then 90', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      overrides: forecastOverrides(),
      router: forecastRouter,
    );
    expect(find.widgetWithText(AppBar, 'Forecast'), findsOneWidget);
    expect(find.byType(ForecastChart), findsOneWidget);
    // Start $6,703.51 less $7.57 a day; rent on Nov 1 and Netflix on Nov 3 come before
    // the payroll on Nov 6.
    expect(find.text(r'Lowest point $4,947.18 on Nov 5'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^30-day forecast: \$6,703\.51 today, \$8,510\.92 on Nov 23\. '
          r'Lowest point \$4,947\.18 on Nov 5\.$',
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(r'^90-day forecast: .* on Jan 22\. ')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('the table reads each day as one sentence', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(
      tester,
      overrides: forecastOverrides(),
      router: forecastRouter,
    );
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();
    expect(find.byType(ForecastTable), findsOneWidget);
    expect(find.byType(ForecastChart), findsNothing);
    expect(find.text('Chart'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        r'Sat, Oct 24: balance $6,703.51, low $6,703.51, high $6,703.51.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text(r'Acme Payroll $1,850.00').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'^Fri, Nov 6: balance .*, low .*, high .*\. '
          r'Acme Payroll \$1,850\.00$',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(r'Low $6,639.61 · High $7,189.61'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the headline says when the balance goes below zero', (
    tester,
  ) async {
    final InMemoryStore store = forecastStore()
      ..upsertTransaction(_spend('big', -600000));
    await pumpApp(
      tester,
      overrides: forecastOverrides(store: store),
      router: forecastRouter,
    );
    final Finder headline = find.textContaining('Below zero on Nov 1');
    expect(headline, findsOneWidget);
    final BuildContext context = tester.element(headline);
    expect(
      tester.widget<Text>(headline).style?.color,
      Theme.of(context).colorScheme.error,
    );
  });

  testWidgets('no covered account shows the empty state', (tester) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty())
      ..upsertAccount(
        const Account(
          id: 'card',
          type: AccountType.credit,
          name: 'Card',
          currencyCode: 'USD',
          isHidden: false,
          displayOrder: 0,
        ),
      );
    await pumpApp(
      tester,
      overrides: forecastOverrides(store: store),
      router: forecastRouter,
    );
    expect(find.text('No accounts to forecast'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Choose accounts'));
    await tester.pumpAndSettle();
    expect(find.byType(ForecastAccountsSheet), findsOneWidget);
  });

  testWidgets('the sheet switches accounts and the currency', (tester) async {
    await pumpApp(
      tester,
      overrides: forecastOverrides(),
      router: forecastRouter,
    );
    await tester.tap(find.byTooltip('Choose accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Accounts in the forecast'), findsOneWidget);
    SwitchListTile tile(String name) => tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, name),
    );
    expect(tile('Everyday Checking').value, isTrue);
    expect(tile('Rainy Day').value, isFalse);
    expect(find.text('USD · hidden account'), findsOneWidget);
    expect(tile('Euro Account').value, isTrue);
    expect(find.text('Card'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'USD'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'EUR'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'EUR'))
          .selected,
      isTrue,
    );

    await tester.tap(find.text('Rainy Day'));
    await tester.tap(find.text('Euro Account'));
    await tester.pumpAndSettle();
    expect(tile('Rainy Day').value, isTrue);
    expect(find.byType(ChoiceChip), findsNothing);

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    // Checking and Rainy Day: $6,703.51 + $5,000.00.
    expect(
      find.bySemanticsLabel(RegExp(r'^30-day forecast: \$11,703\.51 today')),
      findsOneWidget,
    );
  });

  testWidgets('a switch that cannot be kept goes back, with a message', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        ...forecastOverrides(),
        appMetaStoreProvider.overrideWithValue(_FailingMetaStore()),
      ],
      router: forecastRouter,
    );
    await tester.tap(find.byTooltip('Choose accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rainy Day'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Rainy Day'),
          )
          .value,
      isFalse,
    );
    // In the sheet, where it can be seen, not under it.
    expect(
      find
          .descendant(
            of: find.byType(ForecastAccountsSheet),
            matching: find.text(
              "The forecast's accounts could not be saved. Try again.",
            ),
          )
          .hitTestable(),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });
}
