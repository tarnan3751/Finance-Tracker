// Category management: the hierarchy with the system categories locked, expanding and
// search; adding a user category; a system category changes only its icon and color;
// deleting a user category counts the transactions it leaves uncategorized, and they then
// show as Uncategorized.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Tall enough to lay out the editor's whole icon and color grid in the test font.
const Size _tall = Size(412, 2400);

Future<void> _pump(
  WidgetTester tester,
  InMemoryStore store, [
  String location = '/settings/categories',
]) => pumpApp(
  tester,
  initialLocation: location,
  overrides: [storeOverride(store)],
  size: _tall,
);

void main() {
  testWidgets('Settings opens the categories', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/settings',
      overrides: [storeOverride(seededStore())],
    );

    // Below the Security section, past what the list builds at first.
    await tester.scrollUntilVisible(find.text('Categories'), 100);
    // Clear of the navigation bar too, which covers the list's last pixels.
    await tester.ensureVisible(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Categories'), findsOneWidget);
  });

  testWidgets('top-level categories expand; system ones carry a lock', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await _pump(tester, seededStore());

      expect(find.text('Food and drink'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('Food and drink\\nBuilt-in category')),
        findsOneWidget,
      );

      final int children = plaidCategories
          .where((c) => c.primary == 'FOOD_AND_DRINK')
          .length;
      await tester.tap(
        find.byTooltip('Show $children categories under Food and drink'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsOneWidget);

      await tester.tap(
        find.byTooltip('Hide the categories under Food and drink'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Groceries'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('search finds categories at every level', (tester) async {
    await _pump(tester, seededStore());

    await tester.enterText(find.byType(TextField), 'groc');
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Food and drink'), findsOneWidget);
    expect(find.text('Travel'), findsNothing);
  });

  testWidgets('adds a user category under a top-level one', (tester) async {
    final InMemoryStore store = seededStore();
    await _pump(tester, store);

    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Snacks',
    );
    await tester.tap(find.text('Nothing (top level)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food and drink').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pets'));
    await tester.tap(find.bySemanticsLabel('Teal'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Category snacks = store.categories().singleWhere(
      (c) => c.name == 'Snacks',
    );
    expect(snacks.isSystem, isFalse);
    expect(snacks.parentId, systemCategoryId('FOOD_AND_DRINK'));
    expect(snacks.icon, 'pets');
    expect(snacks.color, 0xFF00695C);
  });

  testWidgets('a system category changes only its icon and color', (
    tester,
  ) async {
    final InMemoryStore store = seededStore();
    await _pump(tester, store, '/settings/categories/plaid:FOOD_AND_DRINK');

    expect(
      find.text('A built-in category: only its icon and color can change.'),
      findsOneWidget,
    );
    final TextFormField name = tester.widget(
      find.widgetWithText(TextFormField, 'Name'),
    );
    expect(name.enabled, isFalse);
    expect(find.byTooltip('Delete'), findsNothing);

    await tester.tap(find.byTooltip('Coffee'));
    await tester.tap(find.bySemanticsLabel('Brown'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final Category food = store.category(systemCategoryId('FOOD_AND_DRINK'))!;
    expect(food.name, 'Food and drink');
    expect(food.icon, 'local_cafe');
    expect(food.color, 0xFF5D4037);
  });

  testWidgets('deleting a user category counts and uncategorizes', (
    tester,
  ) async {
    final InMemoryStore store = seededStore()
      ..upsertCategory(
        const Category(
          id: 'snacks',
          name: 'Snacks',
          isSystem: false,
          icon: 'fastfood',
          color: 0xFFEF6C00,
        ),
      )
      ..upsertTransaction(
        testTransaction('chips', name: 'Chips', categoryId: 'snacks'),
      );
    await _pump(tester, store, '/settings/categories/snacks');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete “Snacks”?'), findsOneWidget);
    expect(
      find.text('1 transaction will become uncategorized.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(store.category('snacks'), isNull);
    // The transaction keeps the id; every screen shows it uncategorized.
    expect(store.transaction('chips')!.userCategoryId, 'snacks');

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('Everyday Checking · Uncategorized'), findsNWidgets(2));
    await tester.tap(find.text('Chips'));
    await tester.pumpAndSettle();
    expect(find.text('Uncategorized'), findsOneWidget);
  });
}
