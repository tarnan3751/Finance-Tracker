// Saved filters in the filter sheet and the list: "Save these filters" asks for a name
// and lists it under "Saved"; a tap applies one (its search text included) and the list
// leads its chips with the name, whose chip clears everything; the menu renames and
// deletes; nothing to save leaves the button disabled; one that does not decode is
// left out.
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/data/demo_saved_filters.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_saved_filter_repository.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

const Size _tall = Size(412, 2400);

Future<InMemorySavedFilterRepository> _pump(
  WidgetTester tester, {
  List<SavedFilter> initial = const [],
}) async {
  final InMemorySavedFilterRepository saved = InMemorySavedFilterRepository(
    initial: initial,
  );
  addTearDown(saved.close);
  await pumpApp(
    tester,
    initialLocation: '/transactions',
    overrides: [
      storeOverride(seededStore()),
      savedFilterRepositoryProvider.overrideWithValue(saved),
    ],
    size: _tall,
  );
  return saved;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _chip(String label) =>
    find.descendant(of: find.byType(InputChip), matching: find.text(label));

void main() {
  testWidgets('saves the sheet under a name and lists it as Saved', (
    tester,
  ) async {
    final InMemorySavedFilterRepository saved = await _pump(tester);
    await _tap(tester, find.byTooltip('Filters'));
    expect(find.text('Saved'), findsNothing);
    final Finder save = find.widgetWithText(
      OutlinedButton,
      'Save these filters',
    );
    expect(tester.widget<OutlinedButton>(save).onPressed, isNull);

    await _tap(tester, find.widgetWithText(ChoiceChip, 'This month'));
    await _tap(tester, save);
    expect(find.text('Save filters'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '  October  ');
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(TextButton, 'Save'));

    expect(find.text('Saved'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'October'), findsOneWidget);
    final List<SavedFilter> stored = (await tester.runAsync(
      () => saved.watchAll().first,
    ))!;
    expect(
      TransactionFilters.fromJson(stored.single.filters),
      const TransactionFilters(date: DateFilter(DatePreset.thisMonth)),
    );

    await _tap(tester, find.text('Apply'));
    expect(_chip('October'), findsOneWidget);
    expect(_chip('This month'), findsOneWidget);
  });

  testWidgets('a tap applies a saved filter; its chip clears everything', (
    tester,
  ) async {
    await _pump(tester, initial: demoSavedFilters);
    await _tap(tester, find.byTooltip('Filters'));
    await _tap(tester, find.text('Food and drink this month'));

    expect(find.byType(BottomSheet), findsNothing);
    expect(_chip('Food and drink this month'), findsOneWidget);
    expect(_chip('This month'), findsOneWidget);

    // Any change drops the name; going back to the saved filters shows it again.
    await _tap(tester, find.byTooltip('Remove filter This month'));
    expect(_chip('Food and drink this month'), findsNothing);
    await _tap(tester, find.byTooltip('Filters'));
    await _tap(tester, find.text('Food and drink this month'));
    await _tap(
      tester,
      find.byTooltip('Remove filter Food and drink this month'),
    );
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets("a saved filter's search text fills the search field", (
    tester,
  ) async {
    await _pump(
      tester,
      initial: [
        SavedFilter(
          id: 's1',
          name: 'Payroll',
          position: 0,
          filters: const {'text': 'payroll'},
        ),
      ],
    );
    await _tap(tester, find.byTooltip('Filters'));
    await _tap(tester, find.text('Payroll'));

    expect(find.widgetWithText(TextField, 'payroll'), findsOneWidget);
    expect(find.text('Rent'), findsNothing);
    expect(_chip('Payroll'), findsOneWidget);

    await _tap(tester, find.byTooltip('Remove filter Payroll'));
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Rent'), findsWidgets);
  });

  testWidgets('the menu renames and deletes a saved filter', (tester) async {
    final InMemorySavedFilterRepository saved = await _pump(
      tester,
      initial: demoSavedFilters,
    );
    await _tap(tester, find.byTooltip('Filters'));

    await _tap(tester, find.byTooltip('Options for Food and drink this month'));
    await _tap(tester, find.text('Rename'));
    expect(find.text('Rename saved filter'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Eating out');
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(TextButton, 'Rename'));
    expect(find.text('Eating out'), findsOneWidget);

    await _tap(tester, find.byTooltip(r'Options for Over $100, last 90 days'));
    await _tap(tester, find.text('Delete'));
    expect(find.text(r'Delete “Over $100, last 90 days”?'), findsOneWidget);
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));

    expect(
      [
        for (final f in (await tester.runAsync(() => saved.watchAll().first))!)
          f.name,
      ],
      ['Eating out'],
    );
    expect(find.text(r'Over $100, last 90 days'), findsNothing);
  });

  testWidgets('a saved filter that does not decode is left out', (
    tester,
  ) async {
    await _pump(
      tester,
      initial: [
        SavedFilter(
          id: 's0',
          name: 'Broken',
          position: 0,
          filters: const {
            'date': {'preset': 'next_week'},
          },
        ),
        ...demoSavedFilters,
      ],
    );
    await _tap(tester, find.byTooltip('Filters'));
    expect(find.text('Broken'), findsNothing);
    await _tap(tester, find.text('Food and drink this month'));
    expect(_chip('Food and drink this month'), findsOneWidget);
  });
}
