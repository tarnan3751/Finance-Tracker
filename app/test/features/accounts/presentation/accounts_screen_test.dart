// The account list: derived balances labelled as such, per-currency totals only when the
// accounts hold more than one currency, the hidden accounts in a collapsed section,
// reordering written as display order, and the empty state's action.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Account _account(
  String id,
  String name, {
  String currency = 'USD',
  bool hidden = false,
  int order = 0,
}) => Account(
  id: id,
  type: AccountType.depository,
  name: name,
  currencyCode: currency,
  isHidden: hidden,
  displayOrder: order,
);

void main() {
  testWidgets('each account shows its balance derived from its transactions', (
    tester,
  ) async {
    await pumpApp(tester, overrides: [storeOverride(seededStore())]);

    expect(find.text('Everyday Checking'), findsOneWidget);
    expect(find.text('Rewards Card'), findsOneWidget);
    expect(find.text('Checking or savings'), findsOneWidget);
    expect(find.text('Credit card'), findsOneWidget);
    // The seed's checking sums to 4,925.91 and the card to -5.75.
    expect(find.text(r'$4,925.91'), findsOneWidget);
    expect(find.text(r'-$5.75'), findsOneWidget);
    expect(find.text('from transactions'), findsNWidgets(2));
    // One currency: no totals.
    expect(find.text('Totals'), findsNothing);
  });

  testWidgets('a negative balance is read as minus', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await pumpApp(tester, overrides: [storeOverride(seededStore())]);
      expect(find.bySemanticsLabel(RegExp(r'minus \$5\.75')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('accounts in two currencies get one total per currency', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertAccount(
        _account('eur', 'Euro account', currency: 'EUR', order: 2),
      )
      ..upsertTransaction(
        testTransaction('e1', accountId: 'eur', cents: 10000, currency: 'EUR'),
      );
    await pumpApp(tester, overrides: [storeOverride(store)]);

    expect(find.text('Totals'), findsOneWidget);
    // USD: 4,925.91 - 5.75; EUR: 100.00 (the account and the total).
    expect(find.text(r'$4,920.16'), findsOneWidget);
    expect(find.text('€100.00'), findsNWidgets(2));
  });

  testWidgets('hidden accounts wait in a collapsed section', (tester) async {
    final InMemoryStore store = seededStore()
      ..upsertAccount(_account('old', 'Old savings', hidden: true));
    await pumpApp(tester, overrides: [storeOverride(store)]);

    expect(find.text('1 hidden account'), findsOneWidget);
    expect(find.text('Old savings'), findsNothing);

    await tester.tap(find.text('1 hidden account'));
    await tester.pumpAndSettle();
    expect(find.text('Old savings'), findsOneWidget);
  });

  testWidgets('reordering writes the new display order', (tester) async {
    final InMemoryStore store = seededStore();
    await pumpApp(tester, overrides: [storeOverride(store)]);

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(0, 1);
    await tester.pumpAndSettle();

    expect(store.account(cardId)!.displayOrder, 0);
    expect(store.account(checkingId)!.displayOrder, 1);
    expect(
      tester.getTopLeft(find.text('Rewards Card')).dy,
      lessThan(tester.getTopLeft(find.text('Everyday Checking')).dy),
    );
  });

  testWidgets('the empty list offers to add an account', (tester) async {
    await pumpApp(
      tester,
      overrides: [storeOverride(seededStore(seed: const DemoSeed.empty()))],
    );

    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
    await tester.pumpAndSettle();
    expect(find.text('New account'), findsOneWidget);
  });

  testWidgets('tapping an account opens its detail', (tester) async {
    await pumpApp(tester, overrides: [storeOverride(seededStore())]);

    await tester.tap(find.text('Rewards Card'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Rewards Card'), findsOneWidget);
    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
  });
}
