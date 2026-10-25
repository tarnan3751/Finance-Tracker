// The contract every ItemRepository implementation passes (Drift, in memory, demo), each
// from its own test file under test/features/items/data/. Items are the server's: the
// pull replaces them with the server's list, and nothing is recorded.
import 'dart:typed_data';

import 'package:finance_tracker/features/items/domain/item_repository.dart';
import 'package:finance_tracker/features/items/domain/linked_bank.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// An Item [id] at institution [name], as the server sends it.
ServerItem serverItem(
  String id, {
  String name = 'First Platypus Bank',
  ItemStatus status = ItemStatus.healthy,
  String? errorCode,
  Uri? logoUrl,
  int? color,
  DateTime? lastSync,
}) => (
  item: Item(
    id: id,
    institutionId: 'ins-$id',
    status: status,
    lastSuccessfulSyncAt: lastSync,
    errorCode: errorCode,
  ),
  institution: Institution(
    id: 'ins-$id',
    name: name,
    logoUrl: logoUrl,
    primaryColor: color,
  ),
);

/// Registers the contract tests for the fixtures [create] builds.
void runItemRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('ItemRepository contract', () {
    late RepositoryFixture f;
    late ItemRepository items;
    final DateTime pulled = DateTime.utc(2026, 10, 24, 12);

    setUp(() async {
      f = await create();
      items = f.items;
    });
    if (dispose != null) tearDown(dispose);

    Future<List<String>> ids() async => [
      for (final LinkedBank b in await items.watchAll().first) b.id,
    ];

    test('a fresh repository is empty', () async {
      expect(await items.watchAll().first, isEmpty);
      expect(await items.watchById('i1').first, isNull);
    });

    test('every field round-trips', () async {
      final ServerItem item = serverItem(
        'i1',
        status: ItemStatus.loginRequired,
        errorCode: 'ITEM_LOGIN_REQUIRED',
        logoUrl: Uri.parse('https://example.test/logo.png'),
        color: 4280391411,
        lastSync: DateTime.utc(2026, 10, 24, 9, 30, 0, 250),
      );
      await items.applyPlaid([item], pulledAt: pulled);
      expect(
        await items.watchById('i1').first,
        LinkedBank(
          item: item.item,
          institution: item.institution,
          pulledAt: pulled,
        ),
      );
    });

    test('ordered by institution name ignoring case, then id', () async {
      await items.applyPlaid([
        serverItem('i3', name: 'beta'),
        serverItem('i2', name: 'Alpha'),
        serverItem('i1', name: 'beta'),
      ], pulledAt: pulled);
      expect(await ids(), ['i2', 'i1', 'i3']);
    });

    test('applyPlaid updates listed Items and removes the others', () async {
      await items.applyPlaid([
        serverItem('i1'),
        serverItem('i2'),
      ], pulledAt: pulled);
      final Future<void> seen = expectLater(
        items.watchById('i1'),
        emitsThrough(
          isA<LinkedBank>().having(
            (b) => b.item.status,
            'status',
            ItemStatus.error,
          ),
        ),
      );
      await pumpEventQueue();
      final DateTime later = pulled.add(const Duration(minutes: 5));
      await items.applyPlaid([
        serverItem('i1', status: ItemStatus.error),
      ], pulledAt: later);
      await seen;
      expect(await ids(), ['i1']);
      expect((await items.watchById('i1').first)!.pulledAt, later);
      await items.applyPlaid(const [], pulledAt: later);
      expect(await items.watchAll().first, isEmpty);
    });

    test('applyPlaid returns the Items as stored, in list order', () async {
      final Uri url = Uri.parse('https://example.test/logo/ins-i2');
      await items.applyPlaid([
        serverItem('i2', logoUrl: url),
      ], pulledAt: pulled);
      await items.saveLogo('i2', url, Uint8List.fromList([1, 2, 3]));
      final List<LinkedBank> stored = await items.applyPlaid([
        serverItem('i2', logoUrl: url),
        serverItem('i1'),
      ], pulledAt: pulled);
      expect(stored.map((b) => b.id), ['i2', 'i1']);
      expect(stored.first.logo, [1, 2, 3]);
      expect(stored, [
        for (final String id in ['i2', 'i1'])
          (await items.watchById(id).first)!,
      ]);
    });

    test('applyPlaidItem writes one Item and leaves the rest', () async {
      await items.applyPlaid([serverItem('i1')], pulledAt: pulled);
      await items.applyPlaidItem(serverItem('i2'), pulledAt: pulled);
      expect(await ids(), ['i1', 'i2']);
    });

    test('a logo is saved against its URL and kept while the URL is', () async {
      final Uri url = Uri.parse('https://example.test/logo/ins-i1');
      final Uint8List bytes = Uint8List.fromList([137, 80, 78, 71]);
      await items.applyPlaid([
        serverItem('i1', logoUrl: url),
      ], pulledAt: pulled);
      await items.saveLogo('i1', url, bytes);
      await items.saveLogo('missing', url, bytes);
      expect((await items.watchById('i1').first)!.logo, bytes);

      await items.applyPlaid([
        serverItem('i1', logoUrl: url, status: ItemStatus.error),
      ], pulledAt: pulled);
      expect((await items.watchById('i1').first)!.logo, bytes);

      final Uri moved = Uri.parse('https://example.test/logo/v2/ins-i1');
      await items.applyPlaid([
        serverItem('i1', logoUrl: moved),
      ], pulledAt: pulled);
      expect((await items.watchById('i1').first)!.logo, isNull);
      // A fetch for the old URL that lands late is dropped.
      await items.saveLogo('i1', url, bytes);
      expect((await items.watchById('i1').first)!.logo, isNull);
    });

    test('markLoginRequired marks a stored Item only', () async {
      await items.applyPlaid([serverItem('i1')], pulledAt: pulled);
      await items.markLoginRequired('i1');
      await items.markLoginRequired('missing');
      expect(
        (await items.watchById('i1').first)!.item,
        isA<Item>()
            .having((i) => i.status, 'status', ItemStatus.loginRequired)
            .having((i) => i.errorCode, 'errorCode', 'ITEM_LOGIN_REQUIRED'),
      );
      expect(await ids(), ['i1']);
    });

    test('nothing is recorded', () async {
      await items.applyPlaid([serverItem('i1')], pulledAt: pulled);
      await items.applyPlaidItem(serverItem('i2'), pulledAt: pulled);
      await items.markLoginRequired('i1');
      expect(await f.syncStore?.unsynced() ?? const [], isEmpty);
    });
  });
}
