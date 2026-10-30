// The receipt photo on first view (`receiptProvider`): the file here when it is the photo
// the hash names; else fetched once, checked against the hash and stored under the usual
// path, so the next view is local; a failed fetch is an error that a retry (an
// invalidation) recovers from; a stale file (a replaced photo) is fetched again; bytes
// that do not hash to it are refused; and with no hash, only the file here counts.
import 'dart:typed_data';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/receipt_api.dart';

final Uint8List _photo = Uint8List.fromList([0xff, 0xd8, 0xff, 1, 2, 3]);
final Uint8List _older = Uint8List.fromList([0xff, 0xd8, 0xff, 9]);

void main() {
  late ReceiptApi api;
  late MemoryReceiptStore receipts;
  late ProviderContainer container;
  final String hash = receiptHash(_photo);

  setUp(() {
    api = ReceiptApi()..photos[hash] = _photo;
    receipts = MemoryReceiptStore();
    container = ProviderContainer(
      overrides: [
        financeApiProvider.overrideWithValue(api),
        receiptStoreProvider.overrideWithValue(receipts),
      ],
      retry: (_, _) => null,
    );
  });
  tearDown(() => container.dispose());

  Future<Uint8List?> view([String? sha]) =>
      container.read(receiptProvider('t1', sha ?? hash).future);

  test('a failing fetch, then a retry that succeeds and stores it', () async {
    api.failures.add(const NetworkError(NetworkErrorKind.connection));
    await expectLater(view(), throwsA(isA<NetworkError>()));
    expect(receipts.paths, isEmpty);
    container.invalidate(receiptProvider('t1', hash));
    expect(await view(), _photo);
    expect(await receipts.read(receiptPathFor('t1')), _photo);
    expect(api.fetched, [hash, hash]);
    // The next view, after the screen let go of it, is local.
    container.invalidate(receiptProvider('t1', hash));
    expect(await view(), _photo);
    expect(api.fetched, hasLength(2));
  });

  test(
    'a photo not on the server yet is NotFound, and a retry finds it',
    () async {
      api.photos.clear();
      await expectLater(view(), throwsA(isA<NotFound>()));
      api.photos[hash] = _photo;
      container.invalidate(receiptProvider('t1', hash));
      expect(await view(), _photo);
    },
  );

  test('the file here is used when it is the photo, never fetched', () async {
    await receipts.commit(await receipts.stage('t1', _photo));
    expect(await view(), _photo);
    expect(api.fetched, isEmpty);
  });

  test(
    'a stale file (the photo was replaced elsewhere) is fetched over',
    () async {
      await receipts.commit(await receipts.stage('t1', _older));
      expect(await view(), _photo);
      expect(await receipts.read(receiptPathFor('t1')), _photo);
    },
  );

  test(
    'bytes that do not hash to the receipt are refused, and not stored',
    () async {
      api.photos[hash] = _older;
      await expectLater(view(), throwsA(isA<ReceiptHashMismatch>()));
      expect(receipts.paths, isEmpty);
    },
  );

  test('a fetch makes every reader of the file here read it again', () async {
    // The Conflicts screen holds the local photo while the editor fetches another.
    final sub = container.listen(localReceiptProvider('t1', hash), (_, _) {});
    addTearDown(sub.close);
    expect(
      await container.read(localReceiptProvider('t1', hash).future),
      isNull,
    );
    expect(await view(), _photo);
    expect(
      await container.read(localReceiptProvider('t1', hash).future),
      _photo,
    );
  });

  test('without a hash, only the file here counts', () async {
    expect(await container.read(receiptProvider('t1', null).future), isNull);
    await receipts.commit(await receipts.stage('t1', _older));
    container.invalidate(receiptProvider('t1', null));
    expect(await container.read(receiptProvider('t1', null).future), _older);
    expect(api.fetched, isEmpty);
  });
}
