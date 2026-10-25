// Receipts in the transaction editor, through a fake image source and the in-memory
// receipt store: a photo taken or chosen shows as a thumbnail and is saved with Save; a
// cancelled pick changes nothing; Replace takes another; Remove clears it; a receipt
// whose photo is not on this device says so and can still be removed; a device without
// a camera, or an image that cannot be used, is explained; the thumbnail opens the photo
// full screen; deleting the transaction keeps the photo through Undo and drops it once
// the undo has gone.
import 'dart:io';
import 'dart:typed_data';

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/fake_image_source.dart';
import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:finance_tracker/core/platform/image_source_provider.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/presentation/receipt_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

const Size _tall = Size(412, 2400);

final Uint8List _photo = File('test/fixtures/receipts/plain.jpg')
    .readAsBytesSync();
final Uint8List _otherPhoto = Uint8List.fromList([..._photo, 0]);

Finder get _thumbnail => find.bySemanticsLabel('Receipt image');

void main() {
  late InMemoryStore store;
  late MemoryReceiptStore receipts;
  late FakeImageSource images;

  setUp(() {
    store = seededStore();
    receipts = MemoryReceiptStore();
    images = FakeImageSource(() async => PickedImage(_photo));
  });

  Future<void> pumpEditor(WidgetTester tester, String location) => pumpApp(
    tester,
    initialLocation: location,
    overrides: [
      storeOverride(store),
      receiptStoreProvider.overrideWithValue(receipts),
      imageSourceProvider.overrideWithValue(images),
    ],
    size: _tall,
  );

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  // Gives transaction [id] the receipt [bytes], committed in the store.
  Future<void> withReceipt(String id, Uint8List? bytes) async {
    store.upsertTransaction(
      store.transaction(id)!.copyWith(receiptPath: receiptPathFor(id)),
    );
    if (bytes != null) await receipts.commit(await receipts.stage(id, bytes));
  }

  testWidgets('a photo taken for a new transaction is saved with it', (
    tester,
  ) async {
    await pumpEditor(tester, '/transactions/new');
    await tester.enterText(_field('Amount'), '8');
    await tester.enterText(_field('Description'), 'Hardware');
    final SemanticsHandle semantics = tester.ensureSemantics();

    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(images.cameraPicks, 1);
    expect(_thumbnail, findsOneWidget);
    expect(find.text('Take photo'), findsNothing);
    expect(find.text('Remove receipt'), findsOneWidget);
    semantics.dispose();
    // Nothing is stored before Save.
    expect(receipts.paths, isEmpty);
    await save(tester);

    final Transaction saved = store
        .transactions(TransactionQuery(text: 'Hardware'))
        .single;
    expect(saved.receiptPath, 'receipts/${saved.id}.jpg');
    expect(await receipts.read(saved.receiptPath!), _photo);
  });

  testWidgets('a photo chosen from the gallery is saved too', (tester) async {
    await pumpEditor(tester, '/transactions/demo-txn-02');
    await tester.tap(find.text('Choose photo'));
    await tester.pumpAndSettle();
    expect(images.galleryPicks, 1);
    await save(tester);

    expect(
      store.transaction('demo-txn-02')!.receiptPath,
      'receipts/demo-txn-02.jpg',
    );
    expect(await receipts.read('receipts/demo-txn-02.jpg'), _photo);
  });

  testWidgets('a cancelled pick changes nothing', (tester) async {
    images.next = () async => null;
    await pumpEditor(tester, '/transactions/demo-txn-02');
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    await save(tester);
    expect(store.transaction('demo-txn-02')!.receiptPath, isNull);
    expect(receipts.paths, isEmpty);
  });

  testWidgets('Replace takes another photo in place of the stored one', (
    tester,
  ) async {
    await withReceipt('demo-txn-02', _photo);
    images.next = () async => PickedImage(_otherPhoto);
    await pumpEditor(tester, '/transactions/demo-txn-02');
    final SemanticsHandle semantics = tester.ensureSemantics();
    expect(_thumbnail, findsOneWidget);
    expect(find.bySemanticsLabel('Replace receipt'), findsOneWidget);
    semantics.dispose();

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose photo'));
    await tester.pumpAndSettle();
    expect(images.galleryPicks, 1);
    await save(tester);

    expect(await receipts.read('receipts/demo-txn-02.jpg'), _otherPhoto);
  });

  testWidgets('Remove clears the receipt and its photo on Save', (
    tester,
  ) async {
    await withReceipt('demo-txn-02', _photo);
    await pumpEditor(tester, '/transactions/demo-txn-02');

    await tester.tap(find.text('Remove receipt'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    // Nothing goes before Save.
    expect(await receipts.read('receipts/demo-txn-02.jpg'), _photo);
    await save(tester);

    expect(store.transaction('demo-txn-02')!.receiptPath, isNull);
    expect(receipts.paths, isEmpty);
  });

  testWidgets('a receipt whose photo is on another device says so', (
    tester,
  ) async {
    await withReceipt('demo-txn-02', null);
    await pumpEditor(tester, '/transactions/demo-txn-02');

    expect(find.text('Receipt kept on another device'), findsOneWidget);
    expect(find.text('Replace'), findsOneWidget);
    await tester.tap(find.text('Remove receipt'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(store.transaction('demo-txn-02')!.receiptPath, isNull);
  });

  testWidgets('no camera, or an image that cannot be used, is explained', (
    tester,
  ) async {
    images.next = () async => throw const NoCameraException();
    await pumpEditor(tester, '/transactions/demo-txn-02');
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(find.text('No camera is available'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    images.next = () async => throw const ImagePickFailedException();
    await tester.tap(find.text('Choose photo'));
    await tester.pumpAndSettle();
    expect(find.text("That image can't be used"), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
  });

  testWidgets('the thumbnail opens the photo full screen', (tester) async {
    await withReceipt('demo-txn-02', _photo);
    await pumpEditor(tester, '/transactions/demo-txn-02');

    await tester.tap(
      find.descendant(
        of: find.byType(ReceiptSection),
        matching: find.byType(Image),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptViewScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Receipt'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptViewScreen), findsNothing);
  });

  testWidgets('Undo of a delete keeps the photo', (tester) async {
    await withReceipt('demo-txn-02', _photo);
    await pumpEditor(tester, '/transactions/demo-txn-02');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(store.transaction('demo-txn-02')!.receiptPath, isNotNull);
    expect(await receipts.read('receipts/demo-txn-02.jpg'), _photo);
  });

  testWidgets('a delete left to stand drops the photo', (tester) async {
    await withReceipt('demo-txn-02', _photo);
    await pumpEditor(tester, '/transactions/demo-txn-02');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(receipts.paths, isNotEmpty);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(receipts.paths, isEmpty);
  });
}
