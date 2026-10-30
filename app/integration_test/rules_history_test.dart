// A rule applied to the existing transactions on a device, against the in-app fakes. Run
// on the harness's emulator with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// It starts the dev flavor, which FT_FAKE_SERVER puts on the fake server (skipped without
// the define), over its encrypted database (removed before and after): register, link
// First Platypus Bank and wait for its transactions, add a rule that matches every one,
// see the editor's preview count them, apply the rule from the editor's menu and see the
// snack bar's count and the rows tagged (the fake bank's rows are `demo` rows, which
// record nothing), then apply it again and see that nothing changes.
import 'dart:async';
import 'dart:io';

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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_models/shared_models.dart';

import 'support/editor.dart';
import 'support/restore_offer.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

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

/// Pumps until [done]: the Link flow, its pull and the database run in real time.
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

/// Scrolls the rule editor to its end, where the preview is (a list builds only what is
/// on screen), and pumps until the preview reads [text].
Future<void> _previewReads(WidgetTester tester, String text) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
  await tester.pumpAndSettle();
  await _pumpUntil(tester, () => find.text(text).evaluate().isNotEmpty);
}

Future<void> _addFromMenu(WidgetTester tester, String menu, String item) async {
  await _tap(tester, find.byTooltip(menu));
  await _tap(tester, find.text(item).last);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'dev on the fake server: a rule is previewed against the linked bank\'s '
    'transactions, applied once, and a second application changes nothing',
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
      await tester.enterText(_field('Email'), 'history@example.com');
      await tester.enterText(_field('Password'), 'correct horse battery');
      await _tap(tester, find.widgetWithText(FilledButton, 'Create account'));
      await startFresh(tester);

      final ProviderContainer container = _container(tester);
      final GoRouter router = container.read(goRouterProvider);
      unawaited(router.push<void>(const ItemsRoute().location));
      final Finder link = find.widgetWithText(FilledButton, 'Link a bank');
      await _pumpUntil(tester, () => link.evaluate().isNotEmpty);
      await _tap(tester, link);
      await _settleLink(tester, container);
      List<Transaction> pulled = const [];
      final StreamSubscription<List<Transaction>> stored = container
          .read(transactionRepositoryProvider)
          .watch(TransactionQuery.all)
          .listen((rows) => pulled = rows);
      addTearDown(stored.cancel);
      await _pumpUntil(tester, () => pulled.isNotEmpty);
      // The pull's pages land in their own transactions: wait for the list to settle.
      await _pumpUntil(
        tester,
        () => find.text('First Platypus Bank').evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      final List<Transaction> linked = await container
          .read(transactionRepositoryProvider)
          .watch(TransactionQuery.all)
          .first;
      // No rule yet: the bank's rows arrive untagged.
      expect(linked.where((t) => t.tags.isNotEmpty), isEmpty);
      final String count = NumberFormat.decimalPattern().format(linked.length);

      // Every amount from 0 up: the rule matches every transaction.
      unawaited(router.push<void>(const NewRuleRoute().location));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Name'), 'Tag the history');
      await _addFromMenu(tester, 'Add condition', 'Amount between');
      await tester.enterText(_field('At least'), '0');
      await _addFromMenu(tester, 'Add action', 'Add a tag');
      await tester.enterText(_field('Tag'), 'history');
      final String preview = 'Would change $count of $count transactions';
      await _previewReads(tester, preview);
      await saveEditor(tester, RuleEditorScreen);

      // The saved rule, opened again once the database has it.
      List<Rule> rules = const [];
      final StreamSubscription<List<Rule>> ruleRows = container
          .read(ruleRepositoryProvider)
          .watchAll()
          .listen((live) => rules = live);
      addTearDown(ruleRows.cancel);
      await _pumpUntil(tester, () => rules.isNotEmpty);
      final Rule saved = rules.single;
      unawaited(router.push<void>(EditRuleRoute(saved.id).location));
      await tester.pumpAndSettle();
      await _previewReads(tester, preview);

      Future<void> apply() async {
        await _tap(tester, find.byTooltip('More options'));
        await _tap(tester, find.text('Apply to existing transactions'));
        await _tap(tester, find.text('Apply'));
      }

      await apply();
      final Finder applied = find.text(
        '$count transactions changed: 0 filed, $count tagged, 0 renamed, '
        '0 hidden',
      );
      await _pumpUntil(tester, () => applied.evaluate().isNotEmpty);
      final List<Transaction> rows = await container
          .read(transactionRepositoryProvider)
          .watch(TransactionQuery.all)
          .first;
      expect(rows, hasLength(linked.length));
      // The fake server's bank rows are `demo` rows, which record nothing
      // (sync-app.md, **Recording**); the snack bar's count and the rows say what changed.
      for (final Transaction t in rows) {
        expect(t.tags, ['history'], reason: t.id);
        expect(t.source, DataSource.demo, reason: t.id);
      }
      final AppDatabase db = container.read(databaseProvider);
      Future<List<ChangeLogRow>> recorded() => (db.select(
        db.changeLog,
      )..where((c) => c.entityType.equals('transaction'))).get();
      expect(await recorded(), isEmpty);
      await _previewReads(tester, 'Would change 0 of $count transactions');

      ScaffoldMessenger.of(tester.element(find.byType(Form)))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await apply();
      await _pumpUntil(
        tester,
        () => find.text('No transactions changed.').evaluate().isNotEmpty,
      );
      expect(await recorded(), isEmpty);
      for (final Transaction t
          in await container
              .read(transactionRepositoryProvider)
              .watch(TransactionQuery.all)
              .first) {
        expect(t.tags, ['history'], reason: t.id);
      }
    },
    skip: !fakeServerInDev,
  );
}
