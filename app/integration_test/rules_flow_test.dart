// Rules on a device, against the in-app fakes. Run on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The first test starts the demo flavor as main_demo.dart does: Settings → Rules lists the
// persona's two demo rules, a rule added through the editor files a demo transaction when
// it is run from the transaction editor's menu, and Save keeps it. The second starts the
// dev flavor, which FT_FAKE_SERVER puts on the fake server (skipped without the define),
// over its encrypted database (removed before and after): register, add a rule through
// the screens, link First Platypus Bank and see its transactions arrive tagged by the
// rule, then run the rule on a new manual transaction and see the change recorded in the
// change log.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/features/items/application/link_controller.dart';
import 'package:finance_tracker/features/items/domain/item_action.dart';
import 'package:finance_tracker/features/rules/presentation/rule_editor_screen.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';

import 'support/editor.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// How long a wait for the app may last, in wall-clock time: on an emulator loaded by
/// several lanes, the Link flow has taken longer than 30 s.
const Duration _patience = Duration(seconds: 120);

/// Pumps until [done]: the Link flow waits 5 s between sync requests, in real time on a
/// device.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  final Stopwatch waited = Stopwatch()..start();
  while (waited.elapsed < _patience) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (done()) return;
  fail('the app never got there in ${_patience.inSeconds} s');
}

/// Pumps until no Item action runs: the link, its sync and its pull have finished, as the
/// Linked banks flows settle.
Future<void> _settleLink(WidgetTester tester, ProviderContainer container) =>
    _pumpUntil(tester, () {
      final LinkState state = container.read(linkControllerProvider);
      return !(state.newLink?.isRunning ?? false) &&
          !state.byItem.values.any((a) => a.isRunning);
    });

Future<void> _openRules(WidgetTester tester) async {
  await _tap(tester, _tab('Settings'));
  await tester.scrollUntilVisible(
    find.text('Rules'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await _tap(tester, find.text('Rules'));
}

Future<void> _addFromMenu(WidgetTester tester, String menu, String item) async {
  await _tap(tester, find.byTooltip(menu));
  await _tap(tester, find.text(item).last);
}

Future<void> _runRulesInEditor(WidgetTester tester) async {
  await _tap(tester, find.byTooltip('More options'));
  await _tap(tester, find.text('Run rules on this transaction'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: the persona\'s rules, and a new rule run from the '
      'transaction editor files a transaction', (tester) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = _container(tester);

    await _openRules(tester);
    expect(find.text('Coffee runs'), findsOneWidget);
    expect(find.text('Gig income'), findsOneWidget);

    await _tap(tester, find.text('Add rule'));
    await tester.enterText(_field('Name'), 'Trader Joe\'s as coffee');
    await _addFromMenu(
      tester,
      'Add condition',
      'Merchant or description contains',
    );
    await tester.enterText(_field('Text'), 'Trader Joe');
    await _addFromMenu(tester, 'Add action', 'Set the category');
    await _tap(tester, find.widgetWithText(InputDecorator, 'Set the category'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Search categories'),
      'Coffee',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Coffee').last);
    await saveEditor(tester, RuleEditorScreen);
    expect(find.text('Trader Joe\'s as coffee'), findsOneWidget);

    final Transaction groceries =
        (await container
                .read(transactionRepositoryProvider)
                .watch(TransactionQuery(text: 'Trader Joe', limit: 1))
                .first)
            .single;
    expect(groceries.userCategoryId, isNull);
    unawaited(
      container
          .read(goRouterProvider)
          .push<void>(TransactionRoute(groceries.id).location),
    );
    await tester.pumpAndSettle();
    await _runRulesInEditor(tester);
    expect(
      find.text('Applied the rule “Trader Joe\'s as coffee”. Save to keep it.'),
      findsOneWidget,
    );
    await saveEditor(tester, TransactionEditorScreen);
    final Transaction filed = (await container
        .read(transactionRepositoryProvider)
        .watchById(groceries.id)
        .first)!;
    expect(filed.userCategoryId, 'plaid:FOOD_AND_DRINK_COFFEE');
    expect(filed.source, DataSource.demo);
  });

  testWidgets(
    'dev on the fake server: a rule tags the linked bank\'s transactions as '
    'they arrive, and a rule run on a manual entry is recorded',
    (tester) async {
      final File database = File(
        p.join((await getApplicationSupportDirectory()).path, databaseFileName),
      );
      if (database.existsSync()) database.deleteSync();
      addTearDown(() {
        if (database.existsSync()) database.deleteSync();
      });
      await bootstrap(AppConfig.dev());
      await tester.pumpAndSettle();

      await _tap(tester, find.text('Create an account'));
      await tester.enterText(_field('Email'), 'rules@example.com');
      await tester.enterText(_field('Password'), 'correct horse battery');
      await _tap(tester, find.widgetWithText(FilledButton, 'Create account'));

      // Every amount from 0 up: the rule matches every transaction.
      await _openRules(tester);
      expect(find.text('No rules yet'), findsOneWidget);
      await _tap(tester, find.text('Add rule'));
      await tester.enterText(_field('Name'), 'Tag everything');
      await _addFromMenu(tester, 'Add condition', 'Amount between');
      await tester.enterText(_field('At least'), '0');
      await _addFromMenu(tester, 'Add action', 'Add a tag');
      await tester.enterText(_field('Tag'), 'ruled');
      await saveEditor(tester, RuleEditorScreen);
      expect(find.text('Tag everything'), findsOneWidget);

      final ProviderContainer container = _container(tester);
      unawaited(
        container
            .read(goRouterProvider)
            .push<void>(const ItemsRoute().location),
      );
      // The list reads the database off the UI isolate: wait for the empty state.
      final Finder link = find.widgetWithText(FilledButton, 'Link a bank');
      await _pumpUntil(tester, () => link.evaluate().isNotEmpty);
      await _tap(tester, link);
      await _settleLink(tester, container);
      // The link, its sync and the pull run in real time: wait for the bank's
      // transactions to be stored.
      List<Transaction> pulled = const [];
      final StreamSubscription<List<Transaction>> stored = container
          .read(transactionRepositoryProvider)
          .watch(TransactionQuery.all)
          .listen((rows) => pulled = rows);
      addTearDown(stored.cancel);
      await _pumpUntil(tester, () => pulled.isNotEmpty);
      await tester.pumpAndSettle();
      expect(find.text('First Platypus Bank'), findsOneWidget);
      for (final Transaction t in pulled) {
        expect(t.tags, contains('ruled'), reason: t.id);
      }

      await _tap(tester, _tab('Transactions'));
      await _tap(tester, find.text('Add transaction'));
      await tester.enterText(_field('Amount'), '4.50');
      await tester.enterText(_field('Description'), 'Corner coffee');
      await _runRulesInEditor(tester);
      // The tag lands in the form, maybe below the fold; Save writes it.
      expect(
        find.text('Applied the rule “Tag everything”. Save to keep it.'),
        findsOneWidget,
      );
      await saveEditor(tester, TransactionEditorScreen);

      final Transaction manual =
          (await container
                  .read(transactionRepositoryProvider)
                  .watch(TransactionQuery(text: 'Corner coffee'))
                  .first)
              .single;
      expect(manual.source, DataSource.manual);
      expect(manual.tags, ['ruled']);
      final AppDatabase db = container.read(databaseProvider);
      final List<ChangeLogRow> entries =
          await (db.select(db.changeLog)..where(
                (c) =>
                    c.entityType.equals('transaction') &
                    c.entityId.equals(manual.id),
              ))
              .get();
      expect(entries.single.payload, contains('"ruled"'));
      final List<ChangeLogRow> rules = await (db.select(
        db.changeLog,
      )..where((c) => c.entityType.equals('rule'))).get();
      expect(rules, hasLength(1));
    },
    skip: !fakeServerInDev,
  );
}
