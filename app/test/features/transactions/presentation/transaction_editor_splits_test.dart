// Splits in the transaction editor: rows of category and unsigned amount, signed like the
// transaction, that must add up to its amount before Save takes them; "Distribute evenly"
// with the larger parts last; the category row reads "Split across N categories" and
// Save clears the single category, which removing every split brings back; untouched
// stored splits (of mixed signs, say) are saved back as they are, with no sum check,
// until a row is edited; the list and the account ledger name a split transaction's
// category "Split".
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
const Size _tall = Size(412, 2400);

/// The seed's split transaction: $124.18 at Whole Foods on the card, $100.00 groceries
/// and $24.18 superstores, filed under Groceries.
const String _split = 'demo-txn-04';

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

Future<void> _pickCategory(
  WidgetTester tester,
  Finder cell,
  String name,
) async {
  await tester.tap(cell);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), name);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a transaction with splits shows them and its category row says so',
    (tester) async {
      await _pumpEditor(tester, seededStore(), '/transactions/$_split');

      expect(find.text('Split across 2 categories'), findsOneWidget);
      expect(find.text('Splits'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Superstores'), findsOneWidget);
      expect(find.text('100.00'), findsOneWidget);
      expect(find.text('24.18'), findsOneWidget);
      expect(find.text(r'Unallocated $0.00'), findsOneWidget);
    },
  );

  testWidgets('a new transaction splits evenly, the larger part last', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');
    // Collapsed to the button alone while there are none.
    expect(find.text('Splits'), findsNothing);
    expect(find.text('Distribute evenly'), findsNothing);

    await tester.enterText(_field('Amount'), '10');
    await tester.enterText(_field('Description'), 'Bazaar');
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Add split'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Split across 3 categories'), findsOneWidget);
    expect(find.text(r'Unallocated $10.00'), findsOneWidget);
    for (final String name in ['Coffee', 'Groceries', 'Superstores']) {
      await _pickCategory(tester, find.text('Choose a category').first, name);
    }

    await tester.tap(find.text('Distribute evenly'));
    await tester.pumpAndSettle();
    final List<String> typed = [
      for (final TextFormField field in tester.widgetList<TextFormField>(
        _field('Split amount'),
      ))
        field.controller!.text,
    ];
    expect(typed, ['3.33', '3.33', '3.34']);
    expect(find.text(r'Unallocated $0.00'), findsOneWidget);
    await _save(tester);

    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Bazaar'))
        .single;
    expect(saved.amount, Money(-1000, 'USD'));
    expect(saved.splits, [
      TransactionSplit(
        categoryId: systemCategoryId('FOOD_AND_DRINK_COFFEE'),
        amount: Money(-333, 'USD'),
      ),
      TransactionSplit(
        categoryId: systemCategoryId('FOOD_AND_DRINK_GROCERIES'),
        amount: Money(-333, 'USD'),
      ),
      TransactionSplit(
        categoryId: systemCategoryId('GENERAL_MERCHANDISE_SUPERSTORES'),
        amount: Money(-334, 'USD'),
      ),
    ]);
    expect(saved.userCategoryId, isNull);
  });

  testWidgets('income splits are positive', (tester) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');
    await tester.tap(find.text('Income'));
    await tester.enterText(_field('Amount'), '50');
    await tester.enterText(_field('Description'), 'Refund');
    await tester.tap(find.text('Add split'));
    await tester.pumpAndSettle();
    await _pickCategory(tester, find.text('Choose a category'), 'Coffee');
    await tester.enterText(_field('Split amount'), '50');
    await _save(tester);

    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Refund'))
        .single;
    expect(saved.splits.single.amount, Money(5000, 'USD'));
  });

  testWidgets('splits that do not add up refuse Save, and the line follows', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    final Transaction before = store.transaction(_split)!;
    await _pumpEditor(tester, store, '/transactions/$_split');

    await tester.enterText(_field('Amount'), '130');
    await tester.pumpAndSettle();
    expect(find.text(r'Unallocated $5.82'), findsOneWidget);
    await _save(tester);
    expect(find.text(r'Splits must add up to $130.00'), findsOneWidget);
    expect(store.transaction(_split), before);

    await tester.enterText(_field('Split amount').first, '120');
    await tester.pumpAndSettle();
    // The error follows the edit: still unbalanced, now over.
    expect(find.text(r'Splits must add up to $130.00'), findsOneWidget);
    await tester.enterText(_field('Split amount').first, '105.82');
    await tester.pumpAndSettle();
    expect(find.text(r'Unallocated $0.00'), findsOneWidget);
    await _save(tester);

    final Transaction after = store.transaction(_split)!;
    expect(after.amount, Money(-13000, 'USD'));
    expect(after.splits.map((s) => s.amount), [
      Money(-10582, 'USD'),
      Money(-2418, 'USD'),
    ]);
    // The note the editor does not show is kept.
    expect(after.splits.last.note, 'Household supplies');
    // With splits, the single category is cleared.
    expect(after.userCategoryId, isNull);
  });

  group('stored splits of mixed signs', () {
    // $100.00 out, filed as $120.00 of groceries less a $20.00 refund of supplies.
    late InMemoryStore store;
    final List<TransactionSplit> mixed = [
      TransactionSplit(
        categoryId: systemCategoryId('FOOD_AND_DRINK_GROCERIES'),
        amount: Money(-12000, 'USD'),
      ),
      TransactionSplit(
        categoryId: systemCategoryId('GENERAL_MERCHANDISE_SUPERSTORES'),
        amount: Money(2000, 'USD'),
      ),
    ];

    setUp(() {
      store = seededStore()
        ..upsertTransaction(
          testTransaction(
            'mixed',
            cents: -10000,
            name: 'Mixed',
          ).copyWith(splits: mixed),
        );
    });

    testWidgets('are saved back as they are when no row is edited', (
      tester,
    ) async {
      await _pumpEditor(tester, store, '/transactions/mixed');
      expect(find.text(r'Unallocated $0.00'), findsOneWidget);

      await tester.enterText(_field('Notes'), 'receipt in the drawer');
      await _save(tester);

      final Transaction after = store.transaction('mixed')!;
      expect(after.notes, 'receipt in the drawer');
      expect(after.splits, mixed);
    });

    testWidgets('are held to the sum rule once a row is edited', (
      tester,
    ) async {
      await _pumpEditor(tester, store, '/transactions/mixed');

      await tester.enterText(_field('Split amount').first, '120');
      await tester.pumpAndSettle();
      await _save(tester);
      expect(find.text(r'Splits must add up to $100.00'), findsOneWidget);
      expect(store.transaction('mixed')!.splits, mixed);

      await tester.enterText(_field('Split amount').first, '80');
      await tester.pumpAndSettle();
      await _save(tester);
      expect(store.transaction('mixed')!.splits.map((s) => s.amount), [
        Money(-8000, 'USD'),
        Money(-2000, 'USD'),
      ]);
    });
  });

  testWidgets('over-allocated splits say by how much', (tester) async {
    await _pumpEditor(tester, seededStore(), '/transactions/$_split');

    await tester.enterText(_field('Split amount').first, '101');
    await tester.pumpAndSettle();
    expect(find.text(r'Over by $1.00'), findsOneWidget);
  });

  testWidgets('a split without a category refuses Save', (tester) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/new');
    await tester.enterText(_field('Amount'), '5');
    await tester.enterText(_field('Description'), 'Snacks');
    await tester.tap(find.text('Add split'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Split amount'), '5');
    await _save(tester);

    expect(find.text('Choose a category for every split'), findsOneWidget);
    expect(store.transactions(TransactionQuery(text: 'Snacks')), isEmpty);
  });

  testWidgets('removing every split brings back the single category', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pumpEditor(tester, store, '/transactions/$_split');

    await tester.tap(find.byTooltip('Remove split').first);
    await tester.pumpAndSettle();
    expect(find.text('Split across 1 category'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove split'));
    await tester.pumpAndSettle();
    expect(find.text('Splits'), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
    await _save(tester);

    final Transaction after = store.transaction(_split)!;
    expect(after.splits, isEmpty);
    expect(after.userCategoryId, systemCategoryId('FOOD_AND_DRINK_GROCERIES'));
  });

  testWidgets(
    'the list and the account ledger name a split transaction "Split"',
    (tester) async {
      final InMemoryStore store = seededStore();
      await pumpApp(
        tester,
        initialLocation: '/transactions',
        overrides: [storeOverride(store)],
        size: _tall,
      );
      expect(find.text('Rewards Card · Split'), findsOneWidget);

      await pumpApp(
        tester,
        initialLocation: '/accounts/$cardId',
        overrides: [storeOverride(store)],
        size: _tall,
      );
      expect(find.textContaining('· Split'), findsOneWidget);
    },
  );
}
