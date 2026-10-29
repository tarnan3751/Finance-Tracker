// Splits and a receipt on a device, in the demo flavor. Run on the harness's emulator
// with
//
//   tools/emulator_tests.sh integration -- --dart-define=FT_FAKE_SERVER=true
//
// The demo starts as main_demo.dart does: the newest transaction without splits is split
// two ways with "Distribute evenly", takes the demo's receipt photo from the fake image
// source (the demo flavor's own asset), opens it full screen, and is saved; the list
// names it "Split"; then its receipt is removed again.
import 'package:finance_tracker/bootstrap.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/presentation/receipt_view.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_models/shared_models.dart';

import 'support/editor.dart';

Finder _tab(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// Scrolls the editor until [finder] is built and on screen.
Future<void> _scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);

Future<void> _pickCategory(WidgetTester tester, String name) async {
  await _scrollTo(tester, find.text('Choose a category').first);
  await _tap(tester, find.text('Choose a category').first);
  await tester.enterText(find.byType(TextField), name);
  await tester.pumpAndSettle();
  await _tap(tester, find.text(name).last);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo: split a transaction and attach the demo receipt', (
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
    // The newest transaction without splits.
    final Transaction newest =
        (await container
                .read(transactionRepositoryProvider)
                .watch(TransactionQuery(hidden: false, limit: 20))
                .first)
            .firstWhere((t) => t.splits.isEmpty);
    await _tap(tester, find.byKey(ValueKey(newest.id)));

    // Two splits, divided evenly, the larger part last.
    await _scrollTo(tester, find.text('Add split'));
    await _tap(tester, find.text('Add split'));
    await _tap(tester, find.text('Add split'));
    await _pickCategory(tester, 'Coffee');
    await _pickCategory(tester, 'Groceries');
    await _scrollTo(tester, find.text('Distribute evenly'));
    await _tap(tester, find.text('Distribute evenly'));
    expect(find.textContaining('Unallocated'), findsOneWidget);

    // The demo's receipt, from the fake image source, opened full screen.
    await _scrollTo(tester, find.text('Take photo'));
    await _tap(tester, find.text('Take photo'));
    final Finder thumbnail = find.descendant(
      of: find.byType(ReceiptSection),
      matching: find.byType(Image),
    );
    expect(thumbnail, findsOneWidget);
    await _tap(tester, thumbnail);
    expect(find.byType(ReceiptViewScreen), findsOneWidget);
    await _tap(tester, find.byType(CloseButton));

    await saveEditor(tester, TransactionEditorScreen);
    final Transaction saved = await stored(newest.id);
    expect(saved.splits, hasLength(2));
    expect(Money.sum(saved.splits.map((s) => s.amount)), saved.amount);
    final List<int> parts = [
      for (final TransactionSplit s in saved.splits) s.amount.minorUnits.abs(),
    ];
    expect(parts.last - parts.first, inInclusiveRange(0, 1));
    expect(saved.userCategoryId, isNull);
    expect(saved.receiptPath, receiptPathFor(newest.id));
    final Uint8List? photo = await container
        .read(receiptStoreProvider)
        .read(saved.receiptPath!);
    final ByteData asset = await rootBundle.load('assets/demo/receipt.jpg');
    expect(
      photo,
      asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
    );

    // The list names it "Split".
    expect(
      find.descendant(
        of: find.byKey(ValueKey(newest.id)),
        matching: find.textContaining('Split'),
      ),
      findsOneWidget,
    );

    // Removed again.
    await _tap(tester, find.byKey(ValueKey(newest.id)));
    await _scrollTo(tester, find.text('Remove receipt'));
    await _tap(tester, find.text('Remove receipt'));
    await saveEditor(tester, TransactionEditorScreen);
    expect((await stored(newest.id)).receiptPath, isNull);
    expect(
      await container
          .read(receiptStoreProvider)
          .read(receiptPathFor(newest.id)),
      isNull,
    );
  });
}
