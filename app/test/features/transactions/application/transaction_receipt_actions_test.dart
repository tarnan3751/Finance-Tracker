// The editor's writes with receipts: a new photo is staged, the transaction written, and
// the photo committed only then, so a failed write leaves the receipt as it was (both for
// a new transaction and in place of an existing photo); a removed receipt's file goes
// after the write; a Plaid row takes a receipt and splits as overrides; a bulk delete
// removes the photos at once, a single delete's photo goes through discardReceiptOf;
// the sweep deletes the photos of deleted or unknown transactions and keeps the live
// ones'. Every write keeps the receipt's hash with its photo, and the fill gives the
// photos attached before hashes existed theirs, once.
import 'dart:typed_data';

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/accounts/domain/account_not_found_exception.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

final Uint8List _photo = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);
final Uint8List _newPhoto = Uint8List.fromList([0xFF, 0xD8, 4, 5, 6]);

TransactionDraft _draftOf(
  Transaction t, {
  ReceiptChange receipt = const KeepReceipt(),
  String? accountId,
  List<TransactionSplit>? splits,
}) => (
  accountId: accountId ?? t.accountId,
  amount: t.amount,
  date: t.date,
  name: t.name,
  categoryId: t.userCategoryId,
  notes: t.notes,
  tags: t.tags,
  splits: splits ?? t.splits,
  hidden: t.hidden,
  receipt: receipt,
);

void main() {
  late InMemoryStore store;
  late MemoryReceiptStore receipts;
  late TransactionActions actions;

  void setUpWith(InMemoryStore s) {
    store = s;
    receipts = MemoryReceiptStore();
    actions = TransactionActions(
      InMemoryTransactionRepository(store, recorder: const NoChangeRecorder()),
      receipts,
      testClock,
    );
  }

  setUp(() => setUpWith(seededStore()));

  test('a new transaction with a photo has it as its receipt', () async {
    final String id = (await actions.create((
      accountId: checkingId,
      amount: Money(-500, 'USD'),
      date: testClock.today(),
      name: 'Lunch',
      categoryId: null,
      notes: null,
      tags: const [],
      splits: const [],
      hidden: false,
      receipt: AttachReceipt(_photo),
    ))).id;

    expect(store.transaction(id)!.receiptPath, 'receipts/$id.jpg');
    expect(store.transaction(id)!.receiptSha256, receiptHash(_photo));
    expect(await receipts.read('receipts/$id.jpg'), _photo);
    expect(receipts.stagedCount, 0);
  });

  test('a new transaction whose write fails leaves no photo', () async {
    await expectLater(
      actions.create((
        accountId: 'no-such-account',
        amount: Money(-500, 'USD'),
        date: testClock.today(),
        name: 'Lunch',
        categoryId: null,
        notes: null,
        tags: const [],
        splits: const [],
        hidden: false,
        receipt: AttachReceipt(_photo),
      )),
      throwsA(isA<AccountNotFoundException>()),
    );

    expect(receipts.paths, isEmpty);
    expect(receipts.stagedCount, 0);
  });

  test('a replaced photo takes the old one\'s place', () async {
    final Transaction t = store.transaction('demo-txn-02')!;
    await actions.update(t, _draftOf(t, receipt: AttachReceipt(_photo)));
    final Transaction withReceipt = store.transaction('demo-txn-02')!;
    await actions.update(
      withReceipt,
      _draftOf(withReceipt, receipt: AttachReceipt(_newPhoto)),
    );

    expect(
      store.transaction('demo-txn-02')!.receiptPath,
      'receipts/demo-txn-02.jpg',
    );
    expect(await receipts.read('receipts/demo-txn-02.jpg'), _newPhoto);
    expect(
      store.transaction('demo-txn-02')!.receiptSha256,
      receiptHash(_newPhoto),
    );
  });

  test('a replacement whose write fails keeps the old photo', () async {
    final Transaction t = store.transaction('demo-txn-02')!;
    await actions.update(t, _draftOf(t, receipt: AttachReceipt(_photo)));
    final Transaction withReceipt = store.transaction('demo-txn-02')!;

    await expectLater(
      actions.update(
        withReceipt,
        _draftOf(
          withReceipt,
          receipt: AttachReceipt(_newPhoto),
          accountId: 'no-such-account',
        ),
      ),
      throwsA(isA<AccountNotFoundException>()),
    );

    expect(store.transaction('demo-txn-02'), withReceipt);
    expect(await receipts.read('receipts/demo-txn-02.jpg'), _photo);
    expect(receipts.stagedCount, 0);
  });

  test('a removed receipt clears the path and deletes the photo', () async {
    final Transaction t = store.transaction('demo-txn-02')!;
    await actions.update(t, _draftOf(t, receipt: AttachReceipt(_photo)));
    final Transaction withReceipt = store.transaction('demo-txn-02')!;
    await actions.update(
      withReceipt,
      _draftOf(withReceipt, receipt: const RemoveReceipt()),
    );

    expect(store.transaction('demo-txn-02')!.receiptPath, isNull);
    expect(store.transaction('demo-txn-02')!.receiptSha256, isNull);
    expect(receipts.paths, isEmpty);
  });

  test('keeping the receipt keeps a path whose photo is elsewhere', () async {
    final Transaction t = store
        .transaction('demo-txn-02')!
        .copyWith(
          receiptPath: 'receipts/demo-txn-02.jpg',
          receiptSha256: receiptHash(_photo),
        );
    store.upsertTransaction(t);
    await actions.update(t, _draftOf(t.copyWith(notes: 'n')));

    expect(
      store.transaction('demo-txn-02')!.receiptPath,
      'receipts/demo-txn-02.jpg',
    );
    expect(
      store.transaction('demo-txn-02')!.receiptSha256,
      receiptHash(_photo),
    );
  });

  test('the fill hashes the photos here that have no hash, once', () async {
    final Transaction own = store
        .transaction('demo-txn-02')!
        .copyWith(receiptPath: receiptPathFor('demo-txn-02'));
    final Transaction elsewhere = store
        .transaction('demo-txn-03')!
        .copyWith(receiptPath: receiptPathFor('demo-txn-03'));
    store
      ..upsertTransaction(own)
      ..upsertTransaction(elsewhere);
    await receipts.commit(await receipts.stage('demo-txn-02', _photo));

    expect(await actions.fillReceiptHashes(), 1);
    final Transaction filled = store.transaction('demo-txn-02')!;
    expect(filled.receiptSha256, receiptHash(_photo));
    expect(filled.updatedAt, own.updatedAt);
    // Its photo is on another device, which hashes it there.
    expect(store.transaction('demo-txn-03')!.receiptSha256, isNull);
    expect(await actions.fillReceiptHashes(), 0);
  });

  test('a Plaid transaction takes a receipt and splits as overrides', () async {
    setUpWith(linkedStore());
    final Transaction t = store.transaction('plaid-4')!;
    final List<TransactionSplit> splits = [
      TransactionSplit(
        categoryId: 'plaid:FOOD_AND_DRINK_FAST_FOOD',
        amount: Money(-1311, 'USD'),
      ),
      TransactionSplit(
        categoryId: 'plaid:FOOD_AND_DRINK_COFFEE',
        amount: Money(-1000, 'USD'),
      ),
    ];
    await actions.update(
      t,
      _draftOf(t, receipt: AttachReceipt(_photo), splits: splits),
    );

    final Transaction after = store.transaction('plaid-4')!;
    expect(after.source, DataSource.plaid);
    expect(after.splits, splits);
    expect(after.receiptPath, 'receipts/plaid-4.jpg');
    expect(await receipts.read('receipts/plaid-4.jpg'), _photo);
  });

  test('a bulk delete removes the photos at once', () async {
    for (final String id in ['demo-txn-02', 'demo-txn-03']) {
      final Transaction t = store.transaction(id)!;
      await actions.update(t, _draftOf(t, receipt: AttachReceipt(_photo)));
    }
    await actions.deleteAll(['demo-txn-02', 'demo-txn-03']);

    expect(receipts.paths, isEmpty);
  });

  test('a single delete keeps the photo until it is discarded', () async {
    final Transaction t = store.transaction('demo-txn-02')!;
    await actions.update(t, _draftOf(t, receipt: AttachReceipt(_photo)));
    await actions.delete('demo-txn-02');
    // The undo can still bring it back with its photo.
    await actions.restore('demo-txn-02');
    expect(await receipts.read('receipts/demo-txn-02.jpg'), _photo);

    await actions.delete('demo-txn-02');
    await actions.discardReceiptOf('demo-txn-02');
    expect(receipts.paths, isEmpty);
  });

  test('the sweep keeps the live receipts and deletes the rest', () async {
    for (final String id in ['demo-txn-02', 'demo-txn-03']) {
      final Transaction t = store.transaction(id)!;
      await actions.update(t, _draftOf(t, receipt: AttachReceipt(_photo)));
    }
    // A delete that became final while nothing watched, and a photo of no transaction.
    await actions.delete('demo-txn-03');
    await receipts.commit(await receipts.stage('unknown', _photo));

    expect(await actions.sweepReceipts(), 2);
    expect(receipts.paths, {'receipts/demo-txn-02.jpg'});
  });
}
