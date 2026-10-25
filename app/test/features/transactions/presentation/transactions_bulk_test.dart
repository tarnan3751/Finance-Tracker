// Hiding and bulk edit in the transaction list: "Show hidden" in the filter sheet brings
// hidden rows back with their label and a removable chip; a long press enters selection
// (a checkbox per row, the count in the app bar, Select all, Cancel, back), and each
// action (set the category, add a tag, hide or unhide, delete when no row is the bank's,
// after a confirmation naming the count) writes one batch and reports the count it
// changed; a row deleted after it was selected is skipped, and a refused batch says so.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Tall enough that every row of the seed is laid out.
const Size _tall = Size(412, 2400);

// The seed, two manual rows today and a bank row on the card.
InMemoryStore _store() => seededStore()
  ..upsertTransaction(testTransaction('m1', name: 'Alpha'))
  ..upsertTransaction(testTransaction('m2', name: 'Beta'))
  ..upsertTransaction(
    testTransaction(
      'p1',
      accountId: cardId,
      name: 'Gamma',
    ).copyWith(source: DataSource.plaid),
  );

Future<InMemoryStore> _pump(WidgetTester tester, [InMemoryStore? store]) async {
  final InMemoryStore s = store ?? _store();
  await pumpApp(
    tester,
    initialLocation: '/transactions',
    overrides: [storeOverride(s)],
    size: _tall,
  );
  return s;
}

Finder _row(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(TransactionTile));

// The selection's count in the app bar, read as "N selected".
Finder _count(int count) => find.descendant(
  of: find.byType(AppBar),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Text &&
        w.data == '$count' &&
        w.semanticsLabel == '$count selected',
  ),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// Lets the snack bar on screen time out, so the next one shows.
Future<void> _snackBarGone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, List<String> names) async {
  await tester.longPress(_row(names.first));
  await tester.pumpAndSettle();
  for (final String name in names.skip(1)) {
    await _tap(tester, _row(name));
  }
}

void main() {
  testWidgets('a long press selects; taps toggle; Cancel and back leave', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(Checkbox), findsNothing);

    await _select(tester, ['Alpha']);
    expect(_count(1), findsOneWidget);
    expect(
      find.byType(Checkbox),
      findsNWidgets(find.byType(TransactionTile).evaluate().length),
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    await _tap(tester, _row('Beta'));
    expect(_count(2), findsOneWidget);
    // Tapping a row in selection toggles it rather than opening it.
    await _tap(tester, _row('Beta'));
    expect(_count(1), findsOneWidget);
    await _tap(tester, _row('Alpha'));
    expect(find.byType(Checkbox), findsNothing, reason: 'none left selected');

    await _select(tester, ['Alpha']);
    await _tap(tester, find.byTooltip('Cancel selection'));
    expect(find.byType(Checkbox), findsNothing);

    await _select(tester, ['Alpha']);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Transactions'), findsWidgets);
  });

  testWidgets('Select all selects every row loaded', (tester) async {
    await _pump(tester);
    final int rows = find.byType(TransactionTile).evaluate().length;
    await _select(tester, ['Alpha']);
    await _tap(tester, find.byTooltip('More options'));
    await _tap(tester, find.text('Select all'));
    expect(_count(rows), findsOneWidget);
  });

  testWidgets(
    'hide leaves the list; Show hidden brings the rows back, labelled; '
    'unhide',
    (tester) async {
      final InMemoryStore store = await _pump(tester);
      await _select(tester, ['Alpha', 'Gamma']);
      await _tap(tester, find.byTooltip('Hide'));

      expect(find.text('2 transactions hidden'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Gamma'), findsNothing);
      expect(store.transaction('m1')!.hidden, isTrue);
      expect(store.transaction('p1')!.hidden, isTrue);

      await _tap(tester, find.byTooltip('Filters'));
      await _tap(tester, find.text('Show hidden'));
      await _tap(tester, find.text('Apply'));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Hidden'), findsNWidgets(2));
      expect(
        find.widgetWithText(InputChip, 'Including hidden'),
        findsOneWidget,
      );
      expect(tester.getSemantics(_row('Alpha')).label, contains('Hidden'));

      await _select(tester, ['Alpha', 'Gamma']);
      await _tap(tester, find.byTooltip('Unhide'));
      expect(find.text('2 transactions unhidden'), findsOneWidget);
      expect(store.transaction('m1')!.hidden, isFalse);
      expect(find.text('Hidden'), findsNothing);

      // The chip's delete leaves hidden rows out again.
      await _select(tester, ['Beta']);
      await _tap(tester, find.byTooltip('Hide'));
      expect(find.text('Beta'), findsOneWidget);
      await _tap(tester, find.byTooltip('Remove filter Including hidden'));
      expect(find.text('Beta'), findsNothing);
    },
  );

  testWidgets('add tag asks for the tag and adds it where it is missing', (
    tester,
  ) async {
    final InMemoryStore store = _store()
      ..upsertTransaction(testTransaction('m2', name: 'Beta', tags: ['trip']));
    await _pump(tester, store);
    await _select(tester, ['Alpha', 'Beta', 'Gamma']);
    await _tap(tester, find.byTooltip('Add tag'));
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Add'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).last, ' trip ');
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(TextButton, 'Add'));

    expect(find.text('Tag added to 2 transactions'), findsOneWidget);
    expect(store.transaction('m1')!.tags, ['trip']);
    expect(store.transaction('m2')!.tags, ['trip']);
    expect(store.transaction('p1')!.tags, ['trip']);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('set category through the picker, None included', (tester) async {
    final InMemoryStore store = await _pump(tester);
    await _select(tester, ['Alpha', 'Gamma']);
    await _tap(tester, find.byTooltip('Set category'));
    await tester.enterText(find.byType(TextField).first, 'Groceries');
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Groceries').last);

    expect(find.text('Category set on 2 transactions'), findsOneWidget);
    expect(
      store.transaction('m1')!.userCategoryId,
      'plaid:FOOD_AND_DRINK_GROCERIES',
    );
    expect(
      store.transaction('p1')!.userCategoryId,
      'plaid:FOOD_AND_DRINK_GROCERIES',
    );

    await _snackBarGone(tester);
    await _select(tester, ['Alpha']);
    await _tap(tester, find.byTooltip('Set category'));
    await _tap(tester, find.text('None'));
    expect(find.text('Category set on 1 transaction'), findsOneWidget);
    expect(store.transaction('m1')!.userCategoryId, isNull);
  });

  testWidgets('delete: not with a bank row; confirmed, by count', (
    tester,
  ) async {
    final InMemoryStore store = await _pump(tester);
    await _select(tester, ['Alpha', 'Beta', 'Gamma']);
    IconButton delete() => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(delete().onPressed, isNull);
    await _tap(tester, _row('Gamma'));
    expect(delete().onPressed, isNotNull);

    await _tap(tester, find.byTooltip('Delete'));
    expect(find.text('Delete 2 transactions?'), findsOneWidget);
    await _tap(tester, find.text('Cancel'));
    expect(store.transaction('m1'), isNotNull);
    expect(_count(2), findsOneWidget);

    await _tap(tester, find.byTooltip('Delete'));
    await _tap(tester, find.widgetWithText(TextButton, 'Delete'));
    expect(find.text('2 transactions deleted'), findsOneWidget);
    expect(store.transaction('m1'), isNull);
    expect(store.transaction('m2'), isNull);
    expect(store.transaction('p1'), isNotNull);
  });

  testWidgets('a row deleted after it was selected is skipped', (tester) async {
    final InMemoryStore store = await _pump(tester);
    await _select(tester, ['Alpha', 'Beta']);
    // Deleted meanwhile (on another device, say), while still on screen.
    store.deleteTransaction('m2');
    await _tap(tester, find.byTooltip('Hide'));
    expect(store.transaction('m1')!.hidden, isTrue);
    expect(find.text('1 transaction hidden'), findsOneWidget);
  });

  testWidgets('a refused batch says nothing changed', (tester) async {
    final InMemoryStore store = _store();
    await pumpApp(
      tester,
      initialLocation: '/transactions',
      overrides: [
        storeOverride(store),
        transactionRepositoryProvider.overrideWith(
          (ref) => _Refusing(ref.watch(inMemoryStoreProvider)),
        ),
      ],
      size: _tall,
    );
    await _select(tester, ['Alpha', 'Beta']);
    await _tap(tester, find.byTooltip('Hide'));
    expect(store.transaction('m1')!.hidden, isFalse);
    expect(
      find.text(
        'Nothing changed: one of the transactions was deleted meanwhile.',
      ),
      findsOneWidget,
    );
  });
}

/// The in-memory repository refusing every batch, as when a row was deleted between the
/// read and the write.
final class _Refusing extends InMemoryTransactionRepository {
  _Refusing(super.store) : super(recorder: const NoChangeRecorder());

  @override
  Future<void> upsertAll(List<Transaction> batch) async =>
      throw TransactionBatchException(
        batch.first.id,
        EntityDeletedException('transaction', batch.first.id),
      );
}
