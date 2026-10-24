// An account's detail: the derived balance, the transactions newest first with the
// running balance after each, hiding, the delete confirmation that counts the
// transactions going with the account.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

void main() {
  testWidgets('shows the balance and a running balance after each row', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/accounts/$checkingId',
      overrides: [storeOverride(seededStore())],
    );

    expect(find.widgetWithText(AppBar, 'Everyday Checking'), findsOneWidget);
    expect(find.text(r'$4,925.91'), findsOneWidget);
    expect(find.text('from transactions'), findsOneWidget);
    // Newest first: the card payment, then rent; each with the balance after it.
    expect(find.text(r'Running balance $4,925.91'), findsOneWidget);
    expect(find.text(r'Running balance $5,113.60'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Card payment')).dy,
      lessThan(tester.getTopLeft(find.text('Rent').first).dy),
    );
    await tester.scrollUntilVisible(find.text('Opening balance'), 200);
    expect(find.text(r'Running balance $3,200.00'), findsOneWidget);
  });

  testWidgets('hide moves the account to the hidden section', (tester) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/accounts/$cardId',
      overrides: [storeOverride(store)],
    );

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide account'));
    await tester.pumpAndSettle();

    expect(store.account(cardId)!.isHidden, isTrue);
    expect(find.text('Credit card · Hidden'), findsOneWidget);
  });

  testWidgets('delete names the transaction count and takes them along', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/accounts',
      overrides: [storeOverride(store)],
    );
    await tester.tap(find.text('Rewards Card'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete “Rewards Card”?'), findsOneWidget);
    expect(
      find.text('The account and its 5 transactions will be deleted.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(store.account(cardId), isNull);
    expect(store.count(TransactionQuery(accountIds: {cardId})), 0);
    expect(find.widgetWithText(AppBar, 'Accounts'), findsOneWidget);
    expect(find.text('Rewards Card'), findsNothing);
  });

  testWidgets('cancelling the delete keeps the account', (tester) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/accounts/$cardId',
      overrides: [storeOverride(store)],
    );

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(store.account(cardId), isNotNull);
  });

  testWidgets('a deleted or unknown account says so', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/accounts/nope',
      overrides: [storeOverride(seededStore())],
    );

    expect(find.text('This account no longer exists.'), findsOneWidget);
  });
}
