// The home screen widgets' data and the launch links on a device, in the demo flavor. Run
// on the harness's emulator with
//
//   tools/emulator_tests.sh integration
//
// The demo starts as main_demo.dart does, so the snapshot goes through home_widget into
// the plugin's preferences and is read back from there as the Kotlin side reads it: the
// accounts with the balances the app shows, and, after a transaction in a budgeted
// category, that budget's spending moved by the transaction's amount; after a whole
// Plaid pull against the in-app fake server (the demo's stand-in for a sync), the
// snapshot is written again. Then the Add transaction and Scan receipt shortcuts' links
// open the new transaction's editor, the second asking the demo's camera for the receipt
// in the editor already open.
import 'dart:convert';

import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_image_source.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/launch_links.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/widgets/application/widget_providers.dart';
import 'package:finance_tracker/features/widgets/domain/widget_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_widget/home_widget.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  // Waits in real time past the runner's debounce and the write, and returns the
  // snapshot as stored.
  Future<Map<String, Object?>> stored(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 4)),
    );
    await tester.pumpAndSettle();
    final String? raw = await tester.runAsync<String?>(
      () => HomeWidget.getWidgetData<String>(widgetSnapshotKey),
    );
    expect(raw, isNotNull);
    return jsonDecode(raw!) as Map<String, Object?>;
  }

  Future<T> read<T>(WidgetTester tester, Future<T> future) async =>
      (await tester.runAsync(() => future)) as T;

  testWidgets('demo: the widgets\' snapshot follows the app', (tester) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    final Map<String, Object?> first = await stored(tester);
    expect(first['v'], widgetSnapshotVersion);
    expect(first['signed_in'], isTrue);
    final List<Account> accounts = await read(
      tester,
      container.read(accountsProvider.future),
    );
    final Map<String, Money?> derived = await read(
      tester,
      container.read(derivedBalancesProvider.future),
    );
    final List<Object?> rows = first['accounts']! as List<Object?>;
    expect(rows, isNotEmpty);
    for (final Object? row in rows) {
      final Map<String, Object?> r = row! as Map<String, Object?>;
      final Account a = accounts.singleWhere((a) => a.id == r['id']);
      final Money shown = shownBalance(a, derived).amount;
      expect(r['minor'], shown.minorUnits, reason: a.name);
      expect(r['text'], shown.format(), reason: a.name);
    }

    final List<BudgetStatus> budgets = await read(
      tester,
      container.read(budgetStatusesProvider.future),
    );
    final Map<String, Object?> shownBudget =
        (first['budgets']! as List<Object?>).first! as Map<String, Object?>;
    final BudgetStatus status = budgets.singleWhere(
      (b) => b.budget.id == shownBudget['id'],
    );
    expect(shownBudget['spent_minor'], status.spent.minorUnits);
    final DateTime now = container.read(clockProvider).nowUtc();
    await read(
      tester,
      container
          .read(transactionRepositoryProvider)
          .upsert(
            Transaction(
              id: 'widgets-test-spend',
              accountId: accounts.first.id,
              amount: Money(-1234, status.budget.amount.currencyCode),
              date: container.read(clockProvider).today(),
              pending: false,
              name: 'Widget test',
              userCategoryId: status.budget.categoryId,
              source: DataSource.manual,
              createdAt: now,
              updatedAt: now,
              syncVersion: 0,
            ),
          ),
    );
    final Map<String, Object?> second = await stored(tester);
    final Map<String, Object?> moved = (second['budgets']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .singleWhere((b) => b['id'] == status.budget.id);
    expect(moved['spent_minor'], status.spent.minorUnits + 1234);

    final DateTime written = container.read(widgetRefreshRunnerProvider)!;
    await read(tester, container.read(plaidPullProvider).run());
    final Map<String, Object?> third = await stored(tester);
    expect(
      container.read(widgetRefreshRunnerProvider)!.isAfter(written),
      isTrue,
    );
    expect(third['updated_at'], isNot(second['updated_at']));
  });

  testWidgets('demo: the shortcuts\' links open the editor', (tester) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    void open(Uri link) => expect(
      openLaunchLink(container.read(goRouterProvider), link, sync: () {}),
      isTrue,
    );

    final FakeImageSource images =
        container.read(imageSourceProvider) as FakeImageSource;
    open(addTransactionLink);
    await tester.pumpAndSettle();
    expect(find.text('New transaction'), findsOneWidget);
    expect(images.cameraPicks, 0);

    open(scanReceiptLink);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();
    expect(find.text('New transaction'), findsOneWidget);
    expect(images.cameraPicks, 1);
  });
}
