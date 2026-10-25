// The rules screen: the rules in the order they are tried, with their counts; reordering
// by the drag handle and by the list's semantic move actions; delete with an undo; apply
// to the existing transactions from a rule's menu, with progress shown and no second
// application while one runs; the empty state; the way in from Settings and from the
// categories screen's menu.
import 'dart:async';

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/rule_seed.dart';
import '../../../helpers/seed.dart';

Future<InMemoryRuleRepository> _pump(
  WidgetTester tester, {
  List<Rule>? rules,
  String location = '/settings/rules',
}) async {
  final InMemoryRuleRepository repository = seededRules(rules: rules);
  await pumpApp(
    tester,
    initialLocation: location,
    overrides: [storeOverride(seededStore()), rulesOverride(repository)],
  );
  return repository;
}

Future<List<String>> _names(InMemoryRuleRepository rules) async {
  final List<String> names = [];
  // The in-memory stream answers at once; read it outside the fake clock.
  final List<Rule> live = await rules.watchAll().first;
  for (final Rule r in live) {
    names.add(r.name);
  }
  return names;
}

void main() {
  testWidgets('lists the rules in order with their counts', (tester) async {
    await _pump(tester);
    expect(find.text('Rules'), findsOneWidget);
    final double first = tester.getTopLeft(find.text('Coffee on the card')).dy;
    final double second = tester.getTopLeft(find.text('Groceries')).dy;
    expect(first, lessThan(second));
    expect(find.text('4 conditions · 4 actions'), findsOneWidget);
    expect(find.text('1 condition · 1 action'), findsOneWidget);
  });

  testWidgets('with no rules, says what rules do', (tester) async {
    await _pump(tester, rules: const []);
    expect(find.text('No rules yet'), findsOneWidget);
    expect(find.text('Add rule'), findsOneWidget);
  });

  testWidgets('dragging a handle reorders the rules', (tester) async {
    final InMemoryRuleRepository rules = await _pump(tester);
    final TestGesture drag = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_handle).last),
    );
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await drag.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() => _names(rules)), [
      'Groceries',
      'Coffee on the card',
    ]);
    expect(
      tester.getTopLeft(find.text('Groceries')).dy,
      lessThan(tester.getTopLeft(find.text('Coffee on the card')).dy),
    );
  });

  testWidgets('a reorder that fails puts the stored order back and says so', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/settings/rules',
      overrides: [
        storeOverride(seededStore()),
        rulesOverride(_FailingReorder()),
      ],
    );
    final TestGesture drag = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.drag_handle).last),
    );
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await drag.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('The rules could not be reordered.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Coffee on the card')).dy,
      lessThan(tester.getTopLeft(find.text('Groceries')).dy),
    );
  });

  testWidgets('a rule offers move actions to assistive technology', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final InMemoryRuleRepository rules = await _pump(tester);
      final SemanticsNode node = tester.getSemantics(
        find.ancestor(
          of: find.text('Coffee on the card'),
          matching: find.byType(ListTile),
        ),
      );
      final SemanticsData data = node.getSemanticsData();
      final Iterable<String> labels = [
        for (final int id in data.customSemanticsActionIds ?? const <int>[])
          CustomSemanticsAction.getAction(id)!.label!,
      ];
      expect(labels, contains('Move down'));
      final int down = (data.customSemanticsActionIds ?? const <int>[])
          .firstWhere(
            (id) => CustomSemanticsAction.getAction(id)!.label == 'Move down',
          );
      node.owner!.performAction(node.id, SemanticsAction.customAction, down);
      await tester.pumpAndSettle();
      expect(await tester.runAsync(() => _names(rules)), [
        'Groceries',
        'Coffee on the card',
      ]);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('delete hides the rule; undo brings it back', (tester) async {
    final InMemoryRuleRepository rules = await _pump(tester);
    await tester.tap(find.byTooltip('Delete “Groceries”'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsNothing);
    expect(find.text('Rule deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);
    expect(await tester.runAsync(() => _names(rules)), [
      'Coffee on the card',
      'Groceries',
    ]);
  });

  testWidgets('tapping a rule opens its editor; Add rule a new one', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Edit rule'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add rule'));
    await tester.pumpAndSettle();
    expect(find.text('New rule'), findsOneWidget);
  });

  testWidgets('Settings leads to the rules', (tester) async {
    await _pump(tester, location: '/settings');
    await tester.scrollUntilVisible(find.text('Rules'), 200);
    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee on the card'), findsOneWidget);
  });

  testWidgets('the categories menu leads to the rules', (tester) async {
    await _pump(tester, location: '/settings/categories');
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    expect(find.text('Coffee on the card'), findsOneWidget);
  });

  testWidgets('a rule\'s menu applies it to the existing transactions', (
    tester,
  ) async {
    await _pump(tester, rules: [everyKindRule, groceriesRule, rentRule]);
    await tester.tap(find.byTooltip('More options for “Rent”'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply to existing transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        '2 transactions changed: 0 filed, 2 tagged, 0 renamed, 0 hidden',
      ),
      findsOneWidget,
    );
  });

  testWidgets('while an application runs, progress shows and Apply is '
      'refused', (tester) async {
    final InMemoryStore store = seededStore();
    final _SlowWrites transactions = _SlowWrites(store);
    await pumpApp(
      tester,
      initialLocation: '/settings/rules',
      overrides: [
        storeOverride(store),
        rulesOverride(
          seededRules(rules: [everyKindRule, groceriesRule, rentRule]),
        ),
        transactionRepositoryProvider.overrideWithValue(transactions),
      ],
    );
    // The progress bar animates until the application ends: pump frames, not settle.
    Future<void> openApply() async {
      await tester.tap(find.byTooltip('More options for “Rent”'));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await tester.tap(find.byTooltip('More options for “Rent”'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply to existing transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pump(const Duration(milliseconds: 500));
    final LinearProgressIndicator progress = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.semanticsLabel, 'Applying the rule to your transactions');

    // The first write waits: a second Apply is offered disabled and does nothing.
    await openApply();
    final PopupMenuItem<void> item = tester.widget(
      find.widgetWithText(
        PopupMenuItem<void>,
        'Apply to existing transactions',
      ),
    );
    expect(item.enabled, isFalse);
    await tester.tap(find.text('Apply to existing transactions'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Apply “Rent” to existing transactions?'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 500));

    transactions.release.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(
      find.text(
        '2 transactions changed: 0 filed, 2 tagged, 0 renamed, 0 hidden',
      ),
      findsOneWidget,
    );
    expect(transactions.writes, 2);
  });

  testWidgets('cancelling the confirmation applies nothing', (tester) async {
    await _pump(tester, rules: [everyKindRule, groceriesRule, rentRule]);
    await tester.tap(find.byTooltip('More options for “Rent”'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply to existing transactions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('changed'), findsNothing);
  });
}

/// The in-memory transactions, holding every batch write until [release] completes.
final class _SlowWrites extends InMemoryTransactionRepository {
  _SlowWrites(super.store) : super(recorder: const NoChangeRecorder());

  final Completer<void> release = Completer<void>();
  int writes = 0;

  @override
  Future<void> upsertAll(List<Transaction> batch) async {
    await release.future;
    writes += batch.length;
    return super.upsertAll(batch);
  }
}

/// The test rules, refusing every reorder.
final class _FailingReorder extends InMemoryRuleRepository {
  _FailingReorder()
    : super(
        testClock,
        recorder: const NoChangeRecorder(),
        initial: [everyKindRule, groceriesRule],
      );

  @override
  Future<void> reorder(List<String> ids) async =>
      throw Exception('the database refused the write');
}
