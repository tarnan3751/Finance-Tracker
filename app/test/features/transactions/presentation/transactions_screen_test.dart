// The transaction list: date headers (Today, Yesterday, the weekday within the week, the
// full date before), rows with account, category and a pending label, search, each
// filter dimension with its removable chip, the empty states, and paging: with 2,000
// transactions only the rows on screen are built, and scrolling loads the next fifty.
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/features/transactions/presentation/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Filters'));
  await tester.pumpAndSettle();
}

Future<void> _apply(WidgetTester tester) async {
  await tester.tap(find.text('Apply'));
  await tester.pumpAndSettle();
}

/// Tall enough that the whole seed and the whole filter sheet are laid out (the test font
/// draws every character as a square, so rows are taller than on a device), so a row
/// that is not found is filtered out, not scrolled away.
const Size _tall = Size(412, 2400);

Future<void> _pumpList(WidgetTester tester, InMemoryStore store) => pumpApp(
  tester,
  initialLocation: '/transactions',
  overrides: [storeOverride(store)],
  size: _tall,
);

void main() {
  testWidgets('rows sit under Today, Yesterday, weekday and date headers', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertTransaction(testTransaction('t0', name: 'Lunch today'))
      ..upsertTransaction(testTransaction('t3', name: 'Books', daysAgo: 3));
    await _pumpList(tester, store);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    // The test clock's today is Saturday 24 October 2026.
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('October 12, 2026'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Today')).dy,
      lessThan(tester.getTopLeft(find.text('Lunch today')).dy),
    );
  });

  testWidgets('a row names the merchant, account and category', (tester) async {
    await _pumpList(tester, seededStore());

    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    expect(find.text('Rewards Card · Coffee'), findsOneWidget);
    expect(find.text(r'-$5.75'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    // No merchant: the description.
    expect(find.text('Card payment'), findsOneWidget);
  });

  testWidgets('a transaction without a live category is uncategorized', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertTransaction(
        testTransaction('gone', name: 'Mystery', categoryId: 'no-such-id'),
      );
    await _pumpList(tester, store);

    // The seed's opening balance has no category either.
    expect(find.text('Everyday Checking · Uncategorized'), findsNWidgets(2));
    expect(find.text('Mystery'), findsOneWidget);
  });

  testWidgets('a bank transaction shows the category of its Plaid code', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertTransaction(
        testTransaction('flight', name: 'Airline').copyWith(
          plaidPrimaryCategory: 'TRAVEL',
          plaidDetailedCategory: 'TRAVEL_FLIGHTS',
        ),
      )
      ..upsertTransaction(
        testTransaction(
          'clinic',
          name: 'Clinic',
        ).copyWith(plaidPrimaryCategory: 'MEDICAL'),
      );
    await _pumpList(tester, store);

    expect(find.text('Everyday Checking · Flights'), findsOneWidget);
    expect(find.text('Everyday Checking · Medical'), findsOneWidget);
    // userCategoryId is never written by the resolution.
    expect(store.transaction('flight')!.userCategoryId, isNull);
  });

  testWidgets('the category filter finds a transaction by its Plaid code', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertTransaction(
        testTransaction('flight', name: 'Airline').copyWith(
          plaidPrimaryCategory: 'TRAVEL',
          plaidDetailedCategory: 'TRAVEL_FLIGHTS',
        ),
      );
    await _pumpList(tester, store);

    await _openFilters(tester);
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'travel');
    await tester.pumpAndSettle();
    // The top-level row comes first; Flights is under it.
    await tester.tap(find.text('Travel').first);
    await tester.pumpAndSettle();
    await _apply(tester);

    expect(find.text('Airline'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets('outflows and inflows use the finance colors', (tester) async {
    await _pumpList(tester, seededStore());

    final Text outflow = tester.widget(find.text(r'-$5.75'));
    final Text inflow = tester.widget(find.text(r'$187.69'));
    expect(outflow.style!.color, const Color(0xFFB3261E));
    expect(inflow.style!.color, const Color(0xFF1B6C2A));
  });

  testWidgets('search matches the description, merchant and notes', (
    tester,
  ) async {
    await _pumpList(tester, seededStore());

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'payroll');
    await tester.pumpAndSettle();

    expect(find.text('ACME CORP PAYROLL'), findsNWidgets(2));
    expect(find.text('Rent'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pumpAndSettle();
    expect(find.text('No matching transactions'), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.text('Rent'), findsWidgets);
  });

  testWidgets('the account filter, and its chip removes it', (tester) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Rewards Card'));
    await _apply(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
    expect(find.widgetWithText(InputChip, 'Rewards Card'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove filter Rewards Card'));
    await tester.pumpAndSettle();
    expect(find.text('Rent'), findsWidgets);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('the category filter', (tester) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tv and');
    await tester.pumpAndSettle();
    await tester.tap(find.text('TV and movies'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'TV and movies'), findsOneWidget);
    await _apply(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Shell'), findsNothing);
  });

  testWidgets('the date filter: this month', (tester) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'This month'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 1, 2026 – Oct 31, 2026'), findsOneWidget);
    await _apply(tester);

    // October's rent stays; September's goes.
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
    expect(find.widgetWithText(InputChip, 'This month'), findsOneWidget);
  });

  testWidgets('the date filter: Custom opens the range picker', (tester) async {
    // Wider than a phone: the test font overflows Flutter's own range picker header at
    // phone width.
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [storeOverride(seededStore())],
      size: const Size(600, 2400),
    );

    await _openFilters(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Custom…'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('the date filter: a custom range filters and labels its chip', (
    tester,
  ) async {
    await _pumpList(tester, seededStore());

    // What the range picker hands back for 28 September to 4 October, both included.
    ProviderScope.containerOf(tester.element(find.byType(TransactionsScreen)))
        .read(transactionListControllerProvider.notifier)
        .setFilters(
          TransactionFilters(
            date: DateFilter.custom(
              LocalDateRange(LocalDate(2026, 9, 28), LocalDate(2026, 10, 5)),
            ),
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Shell'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
    expect(
      find.widgetWithText(InputChip, 'Sep 28, 2026 – Oct 4, 2026'),
      findsOneWidget,
    );
  });

  testWidgets('the amount filter compares absolute amounts', (tester) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.enterText(find.widgetWithText(TextField, 'At least'), '1000');
    await tester.enterText(find.widgetWithText(TextField, 'At most'), '2,000');
    await tester.pumpAndSettle();
    await _apply(tester);

    expect(find.text('Rent'), findsNWidgets(2));
    expect(find.text('ACME CORP PAYROLL'), findsNothing);
    expect(find.text('Netflix'), findsNothing);
    expect(
      find.widgetWithText(InputChip, r'$1,000.00 – $2,000.00'),
      findsOneWidget,
    );
  });

  testWidgets('an amount the currency cannot hold disables Apply', (
    tester,
  ) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.enterText(find.widgetWithText(TextField, 'At least'), '1.005');
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount such as 1,234.56'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a maximum below the minimum is refused in the sheet', (
    tester,
  ) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.enterText(find.widgetWithText(TextField, 'At least'), '50');
    await tester.enterText(find.widgetWithText(TextField, 'At most'), '10');
    await tester.pumpAndSettle();

    expect(find.text('At most must not be less than at least'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a top-level category takes the categories under it along', (
    tester,
  ) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'food and');
    await tester.pumpAndSettle();
    // The top-level row comes first; its children name it under their own.
    await tester.tap(find.text('Food and drink').first);
    await tester.pumpAndSettle();
    await _apply(tester);

    // Coffee and groceries are filed under categories inside Food and drink.
    expect(find.text('Blue Bottle Coffee'), findsOneWidget);
    expect(find.text('Whole Foods Market'), findsOneWidget);
    expect(find.text('Netflix'), findsNothing);
  });

  testWidgets('the tag filter', (tester) async {
    await _pumpList(tester, seededStore());

    await _openFilters(tester);
    await tester.tap(find.widgetWithText(FilterChip, '#subscription'));
    await _apply(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Whole Foods Market'), findsNothing);
  });

  testWidgets('Clear in the sheet removes every filter', (tester) async {
    await _pumpList(tester, seededStore());
    await _openFilters(tester);
    await tester.tap(find.widgetWithText(FilterChip, '#subscription'));
    await _apply(tester);

    await _openFilters(tester);
    await tester.tap(find.text('Clear'));
    await _apply(tester);

    expect(find.byType(InputChip), findsNothing);
    expect(find.text('Rent'), findsWidgets);
  });

  testWidgets('with no transactions, the empty state offers to add one', (
    tester,
  ) async {
    await _pumpList(tester, seededStore(seed: const DemoSeed.empty()));

    expect(find.text('No transactions yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Add an account first'), findsOneWidget);
  });

  testWidgets('tapping a row opens it in the editor', (tester) async {
    await _pumpList(tester, seededStore());

    await tester.tap(find.text('Shell'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Transaction'), findsOneWidget);
    expect(find.text('SHELL OIL 57442'), findsOneWidget);
  });

  testWidgets('2,000 transactions build only the visible rows, paged by 50', (
    tester,
  ) async {
    final InMemoryStore store = seededStore(seed: const DemoSeed.empty());
    final DemoSeed seed = buildDemoSeed(testClock.today());
    seed.accounts.forEach(store.upsertAccount);
    for (int i = 0; i < 2000; i++) {
      store.upsertTransaction(
        testTransaction(
          'bulk-${i.toString().padLeft(4, '0')}',
          name: 'Bulk ${i.toString().padLeft(4, '0')}',
          daysAgo: i ~/ 10,
          // Within a day, the larger offset is newer and listed first.
          createdOffsetMs: -i,
          categoryId: systemCategoryId('FOOD_AND_DRINK'),
        ),
      );
    }
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [storeOverride(store)],
    );

    final int built = find
        .byType(TransactionTile, skipOffstage: false)
        .evaluate()
        .length;
    // A 915-pixel screen holds about ten rows; the cache extent adds a few more.
    expect(built, lessThan(25));
    expect(find.text('Bulk 0000'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bulk 0070'),
      600,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 200,
    );
    expect(find.text('Bulk 0070'), findsOneWidget);
    expect(
      find.byType(TransactionTile, skipOffstage: false).evaluate().length,
      lessThan(25),
    );
  });
}
