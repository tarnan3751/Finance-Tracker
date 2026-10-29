// Each editor that closes after an awaited write closes only its own page (core/router/
// own_page.dart): the write is held, the user goes to another tab and opens a page there,
// and when the write lands that page stays (before, go_router's context.pop() closed it,
// the page on top) and the editor stays on its own tab, now editing what it saved, so a
// second Save there rewrites that entity, for a new one too, and closes the editor.
import 'dart:async';

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_reminder_scheduler.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/presentation/account_editor_screen.dart';
import 'package:finance_tracker/features/bills/data/in_memory_bill_repository.dart';
import 'package:finance_tracker/features/bills/presentation/bill_editor_screen.dart';
import 'package:finance_tracker/features/budgets/data/in_memory_budget_repository.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_editor_screen.dart';
import 'package:finance_tracker/features/categories/presentation/category_editor_screen.dart';
import 'package:finance_tracker/features/items/presentation/items_screen.dart';
import 'package:finance_tracker/features/rules/data/in_memory_rule_repository.dart';
import 'package:finance_tracker/features/rules/presentation/rule_editor_screen.dart';
import 'package:finance_tracker/features/rules/presentation/rules_screen.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../helpers/budget_seed.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/rule_seed.dart';
import '../../helpers/seed.dart';

/// A recorder whose writes wait, while held, until released: the repositories' writes
/// land on demand.
final class _HeldRecorder implements ChangeRecorder {
  Completer<void>? _held;

  /// How many records have waited.
  int waited = 0;

  void hold() => _held = Completer<void>();

  void release() {
    _held?.complete();
    _held = null;
  }

  @override
  Future<void> record(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
  ) async {
    final Completer<void>? held = _held;
    if (held == null) return;
    waited++;
    await held.future;
  }
}

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Finder _field(String label) => find.widgetWithText(TextFormField, label);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<void> _add(WidgetTester tester, String menu, String item) async {
  await tester.tap(find.byTooltip(menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  const Category hobbies = Category(
    id: 'hobbies',
    name: 'Hobbies',
    isSystem: false,
    icon: 'i',
    color: 0,
  );
  final BillReminder rent = BillReminder(
    id: 'rent',
    name: 'Rent',
    amount: Money(-150000, 'USD'),
    dueDate: LocalDate(2026, 11, 1),
    cadence: RecurringCadence.monthly,
    accountId: checkingId,
  );

  /// Opens [editor] on the [editorTab] tab, makes its [edit], taps Save with the write
  /// held, goes to the [tab] tab and pushes [pushed] there, then lets the write land:
  /// the page [pushed] opened stays, and back on [editorTab] the editor is still open;
  /// saved again, it closes, and [saved] (the entities the edit is about) counts one.
  Future<void> saveWhileElsewhere(
    WidgetTester tester, {
    required String editor,
    required Type editorScreen,
    required String editorTab,
    required String tab,
    required String pushed,
    required Type pushedScreen,
    required Future<int> Function(ProviderContainer container) saved,
    List<Override> Function(ChangeRecorder recorder)? overrides,
    Future<void> Function()? edit,
  }) async {
    final _HeldRecorder recorder = _HeldRecorder();
    await pumpApp(
      tester,
      initialLocation: editor,
      overrides: [
        storeOverride(seededStore()..upsertCategory(hobbies)),
        changeRecorderProvider.overrideWithValue(recorder),
        reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
        ...?overrides?.call(recorder),
      ],
    );
    expect(find.byType(editorScreen), findsOneWidget);
    final ProviderContainer container = _container(tester);

    await edit?.call();
    recorder.hold();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(recorder.waited, greaterThan(0), reason: 'the write is held');
    await tester.tap(_tab(tab));
    await tester.pumpAndSettle();
    unawaited(container.read(goRouterProvider).push<void>(pushed));
    await tester.pumpAndSettle();
    expect(find.byType(pushedScreen), findsOneWidget);

    recorder.release();
    await tester.pumpAndSettle();
    expect(
      find.byType(pushedScreen),
      findsOneWidget,
      reason: 'the page opened meanwhile stays',
    );

    await tester.tap(_tab(editorTab));
    await tester.pumpAndSettle();
    expect(find.byType(editorScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byType(editorScreen, skipOffstage: false), findsNothing);
    expect(
      await tester.runAsync(() => saved(container)),
      1,
      reason: 'the second Save rewrote what the first saved',
    );
  }

  group('the rule editor', () {
    Future<int> named(ProviderContainer c, String name) async =>
        (await c.read(ruleRepositoryProvider).watchAll().first)
            .where((r) => r.name == name)
            .length;

    testWidgets('closes only its own page', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: EditRuleRoute(groceriesRule.id).location,
        editorScreen: RuleEditorScreen,
        editorTab: 'Settings',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, groceriesRule.name),
        overrides: (recorder) => [
          ruleRepositoryProvider.overrideWithValue(
            InMemoryRuleRepository(
              testClock,
              recorder: recorder,
              initial: [groceriesRule],
            ),
          ),
        ],
      );
    });

    testWidgets('a new rule saved twice is one rule', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const NewRuleRoute().location,
        editorScreen: RuleEditorScreen,
        editorTab: 'Settings',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, 'Tag everything'),
        edit: () async {
          await tester.enterText(_field('Name'), 'Tag everything');
          await _add(tester, 'Add condition', 'Amount between');
          await tester.enterText(_field('At least'), '0');
          await _add(tester, 'Add action', 'Add a tag');
          await tester.enterText(_field('Tag'), 'ruled');
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('the transaction editor', () {
    Future<int> named(ProviderContainer c, String text) async =>
        (await c
                .read(transactionRepositoryProvider)
                .watch(TransactionQuery(text: text))
                .first)
            .length;

    testWidgets('closes only its own page', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const TransactionRoute('demo-txn-04').location,
        editorScreen: TransactionEditorScreen,
        editorTab: 'Transactions',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) async =>
            (await c
                    .read(transactionRepositoryProvider)
                    .watchById('demo-txn-04')
                    .first) ==
                null
            ? 0
            : 1,
      );
    });

    testWidgets('a new transaction saved twice is one transaction', (
      tester,
    ) async {
      await saveWhileElsewhere(
        tester,
        editor: const NewTransactionRoute(account: checkingId).location,
        editorScreen: TransactionEditorScreen,
        editorTab: 'Transactions',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, 'Corner coffee'),
        edit: () async {
          await tester.enterText(_field('Amount'), '4.50');
          await tester.enterText(_field('Description'), 'Corner coffee');
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('the bill editor', () {
    Future<int> named(ProviderContainer c, String name) async =>
        (await c.read(billRepositoryProvider).watchAll().first)
            .where((b) => b.name == name)
            .length;

    testWidgets('closes only its own page', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: EditBillRoute(rent.id).location,
        editorScreen: BillEditorScreen,
        editorTab: 'Plan',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, 'Rent'),
        overrides: (recorder) => [
          billRepositoryProvider.overrideWithValue(
            InMemoryBillRepository(
              testClock,
              recorder: recorder,
              initial: [rent],
            ),
          ),
        ],
      );
    });

    testWidgets('a new bill saved twice is one bill', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const NewBillRoute().location,
        editorScreen: BillEditorScreen,
        editorTab: 'Plan',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, 'Electric'),
        edit: () async {
          await tester.enterText(_field('Name'), 'Electric');
          await tester.tap(find.text('Choose a due date'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('28'));
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('the budget editor', () {
    Future<int> filing(ProviderContainer c, String categoryId) async =>
        (await c.read(budgetRepositoryProvider).watchAll().first)
            .where((b) => b.categoryId == categoryId)
            .length;

    testWidgets('closes only its own page', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const EditBudgetRoute('budget-food').location,
        editorScreen: BudgetEditorScreen,
        editorTab: 'Plan',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => filing(c, 'plaid:FOOD_AND_DRINK'),
        overrides: (recorder) => [
          budgetRepositoryProvider.overrideWithValue(
            InMemoryBudgetRepository(
              testClock,
              recorder: recorder,
              initial: testBudgets(),
            ),
          ),
        ],
      );
    });

    testWidgets('a new budget saved twice is one budget', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const NewBudgetRoute().location,
        editorScreen: BudgetEditorScreen,
        editorTab: 'Plan',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => filing(c, 'plaid:FOOD_AND_DRINK_GROCERIES'),
        edit: () async {
          await tester.tap(find.text('Choose a category'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).first, 'Groceries');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Groceries').last);
          await tester.pumpAndSettle();
          await tester.enterText(_field('Amount per period'), '250.50');
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('the category editor', () {
    Future<int> named(ProviderContainer c, String name) async =>
        (await c.read(categoryRepositoryProvider).watchAll().first)
            .where((cat) => cat.name == name)
            .length;

    testWidgets('closes only its own page', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: EditCategoryRoute(hobbies.id).location,
        editorScreen: CategoryEditorScreen,
        editorTab: 'Settings',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, 'Hobbies and games'),
        // A category saved unchanged writes nothing.
        edit: () => tester.enterText(_field('Name'), 'Hobbies and games'),
      );
    });

    testWidgets('a new category saved twice is one category', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const NewCategoryRoute().location,
        editorScreen: CategoryEditorScreen,
        editorTab: 'Settings',
        tab: 'Accounts',
        pushed: const ItemsRoute().location,
        pushedScreen: ItemsScreen,
        saved: (c) => named(c, 'Board games'),
        edit: () => tester.enterText(_field('Name'), 'Board games'),
      );
    });
  });

  group('the account editor', () {
    Future<int> named(ProviderContainer c, String name) async =>
        (await c.read(accountRepositoryProvider).watchAll().first)
            .where((a) => a.name == name)
            .length;

    testWidgets('closes only its own page', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const EditAccountRoute(checkingId).location,
        editorScreen: AccountEditorScreen,
        editorTab: 'Accounts',
        tab: 'Settings',
        pushed: const RulesRoute().location,
        pushedScreen: RulesScreen,
        saved: (c) async =>
            (await c
                    .read(accountRepositoryProvider)
                    .watchById(checkingId)
                    .first) ==
                null
            ? 0
            : 1,
      );
    });

    testWidgets('a new account saved twice is one account', (tester) async {
      await saveWhileElsewhere(
        tester,
        editor: const NewAccountRoute().location,
        editorScreen: AccountEditorScreen,
        editorTab: 'Accounts',
        tab: 'Settings',
        pushed: const RulesRoute().location,
        pushedScreen: RulesScreen,
        saved: (c) => named(c, 'Savings'),
        edit: () => tester.enterText(_field('Name'), 'Savings'),
      );
    });
  });
}
