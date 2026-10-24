// The transaction editor: a new transaction is a manual expense or income on the route's
// account (else the only one, else the last used), dated today; amounts parse in the
// account's currency and are never rounded; tags and categories; an edit keeps the
// source and what the editor does not show; delete offers an undo for five seconds.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// The editor's form at a height that lays out every field in the test font.
const Size _tall = Size(412, 1600);

Future<void> _pumpEditor(
  WidgetTester tester,
  InMemoryStore store,
  String location,
) => pumpApp(
  tester,
  initialLocation: location,
  overrides: [storeOverride(store)],
  size: _tall,
);

void main() {
  testWidgets('saves a manual expense on the route account, dated today', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new?account=$checkingId');

    expect(find.text('Everyday Checking'), findsOneWidget);
    await tester.enterText(_field('Amount'), '12.50');
    await tester.enterText(_field('Description'), 'Lunch');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Lunch'))
        .single;
    expect(saved.accountId, checkingId);
    expect(saved.amount, Money(-1250, 'USD'));
    expect(saved.date, testClock.today());
    expect(saved.source, DataSource.manual);
    expect(saved.pending, isFalse);
    expect(saved.merchantName, isNull);
    expect(saved.userCategoryId, isNull);
    expect(saved.createdAt, testClock.nowUtc());
    expect(saved.updatedAt, testClock.nowUtc());
  });

  testWidgets('income is positive; the last used account is the default', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');

    // The seed's most recently created transaction is on the card.
    expect(find.text('Rewards Card'), findsOneWidget);
    await tester.tap(find.text('Income'));
    await tester.enterText(_field('Amount'), '1,000');
    await tester.enterText(_field('Description'), 'Refund');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Refund'))
        .single;
    expect(saved.accountId, cardId);
    expect(saved.amount, Money(100000, 'USD'));
  });

  testWidgets('the only account is the default', (tester) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty())
      ..upsertAccount(
        const Account(
          id: 'only',
          type: AccountType.depository,
          name: 'Only account',
          currencyCode: 'EUR',
          isHidden: false,
          displayOrder: 0,
        ),
      );
    await _pumpEditor(tester, store, '/transactions/new');

    expect(find.text('Only account'), findsOneWidget);
    // The amount field shows the account's currency.
    expect(find.text('€'), findsOneWidget);
  });

  testWidgets('bad amounts are errors and nothing is rounded or saved', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');
    await tester.enterText(_field('Description'), 'Espresso');

    for (final (String text, String error) in [
      ('', 'Enter an amount'),
      ('0', 'Enter an amount'),
      ('12.345', 'Enter an amount such as 1,234.56'),
      ('12,50', 'Enter an amount such as 1,234.56'),
      ('-5', 'Enter the amount without a sign'),
    ]) {
      await tester.enterText(_field('Amount'), text);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text(error), findsOneWidget, reason: text);
    }
    expect(store.transactions(TransactionQuery(text: 'Espresso')), isEmpty);
  });

  testWidgets('a description is required', (tester) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');

    await tester.enterText(_field('Amount'), '3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a description'), findsOneWidget);
  });

  testWidgets('picks a category, tags from input and suggestions, and notes', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');
    await tester.enterText(_field('Amount'), '4.20');
    await tester.enterText(_field('Description'), 'Bagel');

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    // Recently used first: the seed's newest transaction is filed under Coffee.
    expect(find.text('Recently used'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Tags'), 'trip,');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, '#trip'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, '#household'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Notes'), 'with Sam');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Bagel'))
        .single;
    expect(saved.userCategoryId, systemCategoryId('FOOD_AND_DRINK_COFFEE'));
    expect(saved.tags, ['trip', 'household']);
    expect(saved.notes, 'with Sam');
  });

  testWidgets('None leaves a transaction uncategorized', (tester) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/demo-txn-02');
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(find.text('Uncategorized'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.transaction('demo-txn-02')!.userCategoryId, isNull);
  });

  testWidgets("without a category of the user's own, the bank's is shown", (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertTransaction(
        testTransaction('flight', name: 'Airline').copyWith(
          plaidPrimaryCategory: 'TRAVEL',
          plaidDetailedCategory: 'TRAVEL_FLIGHTS',
        ),
      );
    await _pumpEditor(tester, store, '/transactions/flight');
    expect(find.text('Flights'), findsOneWidget);
    expect(find.text("From your bank's category"), findsOneWidget);

    // A choice of the user's own replaces it; None brings the bank's back.
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text("From your bank's category"), findsNothing);
    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(find.text('Flights'), findsOneWidget);
    expect(find.text("From your bank's category"), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.transaction('flight')!.userCategoryId, isNull);
  });

  testWidgets('Manage in the picker opens the categories and comes back', (
    tester,
  ) async {
    await _pumpEditor(tester, seededStore(), '/transactions/new');

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppBar, 'Categories').hitTestable(),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('All categories').hitTestable(), findsOneWidget);
  });

  testWidgets('an edit keeps the source, splits and merchant', (tester) async {
    final InMemoryStore store = seededStore();
    final Transaction before = store.transaction('demo-txn-04')!;
    await _pumpEditor(tester, store, '/transactions/demo-txn-04');

    expect(find.text('124.18'), findsOneWidget);
    await tester.enterText(_field('Amount'), '130');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Transaction after = store.transaction('demo-txn-04')!;
    expect(after.amount, Money(-13000, 'USD'));
    expect(after.source, DataSource.demo);
    expect(after.merchantName, before.merchantName);
    expect(after.splits, before.splits);
    expect(after.createdAt, before.createdAt);
    expect(after.updatedAt, testClock.nowUtc());
  });

  testWidgets('delete offers an undo that restores the transaction', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions');
    await tester.tap(find.text('Shell'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(store.transaction('demo-txn-07'), isNull);
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Shell'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.transaction('demo-txn-07'), isNotNull);
    expect(find.text('Shell'), findsOneWidget);
  });

  testWidgets('the undo snack bar lifts the list\'s button, above the tabs', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [storeOverride(store)],
    );
    final Finder button = find.byType(FloatingActionButton);
    final Rect before = tester.getRect(button);

    await tester.tap(find.text('Blue Bottle Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();

    final Rect snackBar = tester.getRect(find.byType(SnackBar));
    expect(tester.getRect(button).bottom, lessThan(before.bottom));
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(snackBar.top));
    expect(
      snackBar.bottom,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(NavigationBar)).dy),
    );

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.transaction('demo-txn-12'), isNotNull);
  });

  testWidgets('without undo the delete stands and the offer goes in 5 s', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/demo-txn-07');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction deleted'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Transaction deleted'), findsNothing);
    expect(store.transaction('demo-txn-07'), isNull);
  });

  testWidgets('with no account, the editor asks for one first', (tester) async {
    await _pumpEditor(
      tester,
      seededStore(seed: const DemoSeed.empty()),
      '/transactions/new',
    );

    expect(find.text('Add an account first'), findsOneWidget);
    await tester.tap(find.text('Add account'));
    await tester.pumpAndSettle();
    expect(find.text('New account'), findsOneWidget);
  });

  testWidgets('a deleted transaction says so', (tester) async {
    await _pumpEditor(tester, seededStore(), '/transactions/nope');

    expect(find.text('This transaction no longer exists.'), findsOneWidget);
  });
}
