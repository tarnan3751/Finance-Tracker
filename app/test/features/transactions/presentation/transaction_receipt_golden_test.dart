// Goldens of a transaction with splits and a receipt, light and dark: the editor (which
// is the transaction's detail) of the seed's split transaction with a receipt photo, its
// two splits and the thumbnail in view; and the photo full screen, opened from the
// thumbnail. The photo is a PNG of the demo flavor's synthetic receipt
// (test/fixtures/receipts/receipt.png): a lossless image decodes to the same pixels on
// every platform, where JPEG decoders differ, so the goldens match on CI's Linux runner
// too. Tagged `golden`; see test/flutter_test_config.dart for where the files go and how
// to update them.
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/presentation/receipt_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

/// Tall enough to show the splits and the receipt below them.
const Size _size = Size(412, 1500);

Future<Widget> _app(Brightness brightness) async {
  final InMemoryStore store = seededStore();
  store.upsertTransaction(
    store
        .transaction('demo-txn-04')!
        .copyWith(receiptPath: receiptPathFor('demo-txn-04')),
  );
  final MemoryReceiptStore receipts = MemoryReceiptStore();
  await receipts.commit(
    await receipts.stage(
      'demo-txn-04',
      File('test/fixtures/receipts/receipt.png').readAsBytesSync(),
    ),
  );
  return SizedBox.fromSize(
    size: _size,
    child: buildTestApp(
      initialLocation: '/transactions/demo-txn-04',
      brightness: brightness,
      overrides: [
        storeOverride(store),
        receiptStoreProvider.overrideWithValue(receipts),
      ],
    ),
  );
}

void main() {
  // Flutter's own DEBUG banner is not part of the app.
  setUp(() => WidgetsApp.debugAllowBannerOverride = false);
  tearDown(() => WidgetsApp.debugAllowBannerOverride = true);

  for (final Brightness brightness in Brightness.values) {
    late Widget app;
    setUp(() async => app = await _app(brightness));

    goldenTest(
      'the editor of a split transaction with a receipt, ${brightness.name}',
      fileName: 'transaction_editor_splits_receipt_${brightness.name}',
      constraints: BoxConstraints.tight(_size),
      builder: () => app,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await precacheImages(tester);
      },
    );

    goldenTest(
      'a receipt full screen, ${brightness.name}',
      fileName: 'receipt_view_${brightness.name}',
      constraints: BoxConstraints.tight(_size),
      builder: () => app,
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(ReceiptSection),
            matching: find.byType(Image),
          ),
        );
        await tester.pumpAndSettle();
        await precacheImages(tester);
      },
    );
  }
}
