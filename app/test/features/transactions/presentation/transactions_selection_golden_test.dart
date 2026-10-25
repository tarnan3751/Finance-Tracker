// Golden of the transaction list in selection mode, light and dark at phone size, on the
// demo seed dated to the test clock with one transaction hidden and "Show hidden" on, so
// the hidden row carries its label: two rows selected, the count and the bulk actions
// in the app bar. Tagged `golden`; see test/flutter_test_config.dart for where the files
// go and how to update them.
import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Widget _app(Brightness brightness) {
  final InMemoryStore store = seededStore();
  store.upsertTransaction(
    store.transaction('demo-txn-11')!.copyWith(hidden: true),
  );
  return SizedBox.fromSize(
    size: phoneSize,
    child: buildTestApp(
      initialLocation: '/transactions',
      brightness: brightness,
      overrides: [storeOverride(store)],
    ),
  );
}

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    goldenTest(
      'the transaction list selecting, ${brightness.name}',
      fileName: 'transactions_selection_${brightness.name}',
      constraints: BoxConstraints.tight(phoneSize),
      builder: () => _app(brightness),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Filters'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show hidden'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(TransactionTile).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TransactionTile).at(1));
        await tester.pumpAndSettle();
      },
    );
  }
}
