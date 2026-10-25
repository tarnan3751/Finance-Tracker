// Hiding and bulk edit on a device, in the demo flavor. Run on the harness's emulator
// with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does: a transaction hidden from its editor's menu
// leaves the list, "Show hidden" brings it back labelled, and two rows selected with a
// long press and a tap take a tag in one action.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_models/shared_models.dart';

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: hide a transaction, show it again, and tag two at once', (
    tester,
  ) async {
    await bootstrap(AppConfig.demo());
    await tester.pumpAndSettle();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    Future<Transaction> stored(String id) async => (await container
        .read(transactionRepositoryProvider)
        .watchById(id)
        .first)!;

    await _tap(tester, _tab('Transactions'));
    final List<Transaction> newest = await container
        .read(transactionRepositoryProvider)
        .watch(TransactionQuery(hidden: false, limit: 2))
        .first;
    final Finder first = find.byKey(ValueKey(newest[0].id));
    final Finder second = find.byKey(ValueKey(newest[1].id));
    expect(first, findsOneWidget);

    // Hidden from the editor's menu, saved: it leaves the list.
    await _tap(tester, first);
    await _tap(tester, find.byTooltip('More options'));
    await _tap(tester, find.byType(CheckedPopupMenuItem<void>));
    await _tap(tester, find.text('Save'));
    expect((await stored(newest[0].id)).hidden, isTrue);
    expect(first, findsNothing);

    // Show hidden brings it back, labelled.
    await _tap(tester, find.byTooltip('Filters'));
    await _tap(tester, find.text('Show hidden'));
    await _tap(tester, find.text('Apply'));
    expect(first, findsOneWidget);
    expect(
      find.descendant(of: first, matching: find.text('Hidden')),
      findsOneWidget,
    );

    // A long press and a tap select two rows; one action tags both.
    await tester.longPress(first);
    await tester.pumpAndSettle();
    await _tap(tester, second);
    await _tap(tester, find.byTooltip('Add tag'));
    await tester.enterText(find.byType(TextField).last, 'trip');
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(TextButton, 'Add'));
    expect(find.text('Tag added to 2 transactions'), findsOneWidget);
    for (final Transaction t in newest) {
      expect((await stored(t.id)).tags, contains('trip'));
    }
  });
}
