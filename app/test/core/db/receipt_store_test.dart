// The receipt store: a staged photo is not the receipt until committed, a commit replaces
// the old photo, a discard leaves it as it was; read gives null for a missing file or a
// path that is not a receipt's; delete of a missing file does nothing; ids that could
// leave the folder are refused; the sweep deletes the files no live transaction keeps,
// staged leftovers included, but not those written since it began. The file store runs
// in a temporary directory, the memory one beside it on the same cases.
import 'dart:io';
import 'dart:typed_data';

import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _a = Uint8List.fromList([1, 2, 3]);
final Uint8List _b = Uint8List.fromList([4, 5, 6, 7]);

void main() {
  test('the path of a receipt is receipts/<id>.jpg', () {
    expect(receiptPathFor('t-1'), 'receipts/t-1.jpg');
  });

  for (final (String name, ReceiptStore Function(Directory) make) in [
    ('file', (dir) => FileReceiptStore(() async => dir)),
    ('memory', (_) => MemoryReceiptStore()),
  ]) {
    group('$name store', () {
      late Directory dir;
      late ReceiptStore store;

      setUp(() {
        dir = Directory.systemTemp.createTempSync('receipts');
        store = make(dir);
      });
      tearDown(() => dir.deleteSync(recursive: true));

      test('a staged photo is the receipt only once committed', () async {
        final StagedReceipt staged = await store.stage('t1', _a);
        expect(await store.read('receipts/t1.jpg'), isNull);

        expect(await store.commit(staged), 'receipts/t1.jpg');
        expect(await store.read('receipts/t1.jpg'), _a);
      });

      test('a commit replaces the old photo', () async {
        await store.commit(await store.stage('t1', _a));
        await store.commit(await store.stage('t1', _b));
        expect(await store.read('receipts/t1.jpg'), _b);
      });

      test('a discard leaves the old photo as it was', () async {
        await store.commit(await store.stage('t1', _a));
        await store.discard(await store.stage('t1', _b));
        expect(await store.read('receipts/t1.jpg'), _a);
      });

      test('read is null for a missing photo or another path', () async {
        await store.commit(await store.stage('t1', _a));
        expect(await store.read('receipts/t2.jpg'), isNull);
        expect(await store.read('../receipts/t1.jpg'), isNull);
        expect(await store.read('/receipts/t1.jpg'), isNull);
        expect(await store.read('receipts/t1.jpg.staged'), isNull);
      });

      test('delete removes the photo, and again does nothing', () async {
        await store.commit(await store.stage('t1', _a));
        await store.delete('receipts/t1.jpg');
        expect(await store.read('receipts/t1.jpg'), isNull);
        await store.delete('receipts/t1.jpg');
        await store.delete('receipts/never.jpg');
      });

      test('an id that could leave the folder is refused', () {
        for (final String id in ['../x', 'a/b', '', 'a.b']) {
          expect(() => store.stage(id, _a), throwsArgumentError, reason: id);
        }
      });

      test('the sweep deletes what no live transaction keeps', () async {
        for (final String id in ['keep', 'gone1', 'gone2']) {
          await store.commit(await store.stage(id, _a));
        }
        final DateTime later = DateTime.now().add(const Duration(minutes: 1));

        final int deleted = await store.sweep({
          'receipts/keep.jpg',
          'receipts/other-device.jpg',
        }, olderThan: later);

        expect(deleted, 2);
        expect(await store.read('receipts/keep.jpg'), _a);
        expect(await store.read('receipts/gone1.jpg'), isNull);
        expect(await store.read('receipts/gone2.jpg'), isNull);
      });

      test('the sweep with no folder yet deletes nothing', () async {
        expect(await store.sweep(const {}, olderThan: DateTime.now()), 0);
      });
    });
  }

  group('file store', () {
    late Directory dir;
    late FileReceiptStore store;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('receipts');
      store = FileReceiptStore(() async => dir);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('keeps the photos in <root>/receipts and nothing else', () async {
      await store.commit(await store.stage('t1', _a));
      expect(File('${dir.path}/receipts/t1.jpg').readAsBytesSync(), _a);
      expect(Directory('${dir.path}/receipts').listSync().map((e) => e.path), [
        '${dir.path}/receipts/t1.jpg',
      ]);
    });

    test('the sweep spares a file written since it began', () async {
      await store.commit(await store.stage('old', _a));
      await store.commit(await store.stage('new', _a));
      final DateTime started = DateTime.now();
      File('${dir.path}/receipts/old.jpg')
          .setLastModifiedSync(started.subtract(const Duration(hours: 1)));
      File('${dir.path}/receipts/new.jpg')
          .setLastModifiedSync(started.add(const Duration(seconds: 1)));

      expect(await store.sweep(const {}, olderThan: started), 1);
      expect(await store.read('receipts/old.jpg'), isNull);
      expect(await store.read('receipts/new.jpg'), _a);
    });

    test('the sweep deletes a staged photo left behind', () async {
      await store.stage('crashed', _a);
      final File staged = File('${dir.path}/receipts/crashed.jpg.staged');
      expect(staged.existsSync(), isTrue);

      expect(
        await store.sweep(
          const {},
          olderThan: DateTime.now().add(const Duration(minutes: 1)),
        ),
        1,
      );
      expect(staged.existsSync(), isFalse);
    });
  });
}
